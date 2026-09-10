# EGRAPH：基于等价重写的 SQLite 变形测试

这是在 [SQLancer](https://github.com/sqlancer/sqlancer) 上新增的一个 oracle。它的判据只有一条：

> **同一份数据上，一个查询和它的等价改写必须返回相同的结果集。不同就是 bug。**

等价改写由一个 Rust 服务用 e-graph（[egg](https://github.com/egraphs-good/egg)）饱和 SQL 代数规则产生，
所以不需要预先知道"正确答案"是什么 —— 这是变形测试（metamorphic testing）而不是差分测试。

---

## 1. 一次 check 的完整流程

```
① 生成被测查询          SQLite3OracleFactory
   只建一张普通表 t0（EGRAPH 全程只查单表），随机造 WHERE
   两道预过滤（EGraphPredicateFilter）：丢弃恒不为真的谓词、
   丢弃 e-graph 表示不了的谓词；再用探针查询丢弃命中 0 行的 base query
   数据完全来自 SQLancer 自己的 INSERT/UPDATE，不额外补数
        │
② 求等价变体            egraph-server（Rust，HTTP）
   base query ──POST /generate-variants──► 3 个等价改写
        │
③ 套 wrapper 执行并比对  EGraphMetamorphicOracle
   原查询和每个变体都套上同一个 coverage shape 后执行
   结果集不一致 ⇒ 报 bug
        │
④ 落盘可重放语料        EGraphCorpusCaseWriter / EGraphContextReplayWriter
   供后续测覆盖率、也可反过来当输入语料
```

### 为什么要 wrapper shape

只比较改写后的 WHERE，SQLite 里被执行的其实只有表达式求值那一小块。
所以每个 base query 会被套进约 60 个 **coverage shape** 之一，把执行推进不同子系统：
FTS3/4/5、R-Tree、JSON/JSONB、窗口函数、sorter、WAL/vacuum/integrity-check、ALTER、UPSERT……

shape 的写法有个硬性要求：**它算出的值必须进结果集**。

```sql
-- 好：count 进投影，探针表算错了就会变成 mismatch
SELECT q.*, (SELECT count(*) FROM egraph_probe WHERE ...) AS n FROM (<base>) AS q

-- 差：恒真的 EXISTS 过滤，探针表返回错的行 oracle 也看不见，只涨覆盖率不涨检测力
SELECT * FROM (<base>) AS q WHERE EXISTS (SELECT 1 FROM egraph_probe LIMIT 1)
```

---

## 2. 跑起来

### 依赖

- JDK 17+、Maven
- Rust toolchain（编译 e-graph 服务）
- 测覆盖率还需要：gcc/gcov、SQLite amalgamation 源码

### 编译并启动

```bash
# 1. SQLancer 本体 —— 一定要 clean，见下方"踩过的坑"
mvn -o clean package -DskipTests

# 2. e-graph 服务（oracle 依赖它出变体，必须先起来）
cd egraph-server
cargo build --release
./target/release/egraph-server        # 监听 127.0.0.1:3000
```

### 最小跑法（不需要任何语料）

纯随机路径不读语料文件，开箱即用：

```bash
java -cp target/sqlancer-2.0.0.jar sqlancer.Main \
    --num-threads=1 --timeout-seconds=300 \
    --log-each-select=true \
    --egraph-url=http://127.0.0.1:3000 \
    --egraph-max-variants=3 --egraph-timeout-millis=3000 \
    sqlite3 --oracle=EGRAPH
```

> 注意 SQLancer 的参数顺序：全局选项在 DBMS 名字**之前**，DBMS 专属选项在**之后**。

### 带语料跑

```bash
java ... sqlite3 --oracle=EGRAPH \
    --egraph-input-file="coverage/sqlite/sqlite-official-select-only-variant-ready-corpus.sql;coverage/sqlite/auto-research-filtered-corpus.sql"
```

### 有用的系统属性

| 属性 | 作用 |
|---|---|
| `-Dsqlancer.statementTimeoutSeconds=15` | 单条语句超时，防止病态查询卡住长跑（超时不当 bug 报） |
| `-Degraph.examples.file=<path>` | 输出人可读的端到端样例（结构/数据/原查询/变体/结果） |
| `-Degraph.coverage.file=<path>` | 输出 workload 统计：哪些 shape 跑了、丢了多少、为什么丢 |
| `-Degraph.replay.file=<path>` | 输出可重放语料，测覆盖率用 |
| `-Dsqlite3.egraph.corpus.keyframeInterval=50` | 快照关键帧间隔，**必须与重放分块大小一致** |
| `EGRAPH_LOG_VALIDATE=1`（环境变量） | 打开 e-graph 服务的变体校验日志，默认静默 |
| `-Degraph.variantOnlyError.log=<path>` | 落盘"原查询成功但变体报错"的成对样本，供人工定性 |
| `-Degraph.emptyBaseCheckPercent=<0-100>` | 原查询探针为空时仍然继续跑变体的比例，默认 10；0 = 恢复旧的一律丢弃 |
| `EGRAPH_NODE_LIMIT`（环境变量） | e-graph 节点上限，默认 400 |
| `EGRAPH_TIME_LIMIT_MS`（环境变量） | 单次饱和时间上限，默认 60 |
| `EGRAPH_EXTRA_RULES=0`（环境变量） | 关掉 2026-09-08 新增的 12 条比较规则，用于 A/B |
| `-Degraph.rtreeTargets=false` | 不再把 R-Tree 虚表当作 base query 的目标表，默认开 |
| `-Degraph.rtreePushdownPercent=<0-100>` | R-Tree 目标表上构造**可下推谓词**的比例，默认 80；0 = 全走随机生成器 |
| `-Degraph.indexedPredicatePercent=<0-100>` | 普通表上把 WHERE 构造成 `索引列 <op> 常量` 的比例，默认 **0**（关闭）；0 = 全走随机生成器 |

---

## 3. 覆盖率测量：四步研究循环

```
① start-long-codecov-capture.ps1   长跑，捕获可重放语料
② finish-long-codecov.ps1          并行分块重放到插桩 SQLite，合并 gcda，出 gcov 报告
③ analyze-uncovered-codecov.ps1    给未覆盖代码分类
④ auto-research-codecov.ps1        量化各候选 workload 的增量并排名，排名回灌下一轮 shape 选择
```

第③步的分类是关键 —— 它把未覆盖代码分成三类，只有第三类值得追：

1. **SQL 打不到**（纯 C API、需要编译选项）
2. **打得到但改变不了查询结果**（EXPLAIN 渲染、错误格式化、析构）—— 覆盖它只动百分比，永远不会变成 bug 报告
3. **能改变查询结果**（oracle target）—— 这才是目标

> 一个陷阱：那份报告只统计"从未进入的函数"。实测未覆盖 19024 行里，**7206 行是从未进入的函数，
> 另外 11818 行藏在已进入函数内部没走的分支**（`sqlite3VdbeExec` 的 opcode switch、`sqlite3Pragma`、
> `yy_reduce` 的语法规则等），而成块的机会恰恰在后者。

### 语料

| 文件 | 在仓库里 | 来源 |
|---|---|---|
| `sqlite-official-test-corpus.sql` | ✅ 6.5 MB | SQLite 官方测试套件导出 |
| `sqlite-official-select-only-corpus.sql` | ✅ 264 KB | 上一个 → `build-official-select-only-corpus.ps1` |
| `sqlite-official-select-only-variant-ready-corpus.sql` | ✅ 192 KB | 上一个 → `build-variant-ready-official-corpus.ps1` |
| `auto-research-filtered-corpus.sql` | ✅ 23 MB | `filter-auto-research-corpus-fast.ps1` |
| `high-coverage-egraph-corpus.sql` | ❌ | 长跑的 replay 累积而成，单文件 1.8 GB 超 GitHub 100 MB 限制，用 `update-high-coverage-corpus.ps1` 重建 |

插桩 SQLite 也不在仓库里：下载 SQLite amalgamation 源码后跑 `build-instrumented-sqlite.ps1`。
**它的编译选项必须和实际用的 sqlite-jdbc 对齐**，否则覆盖率百分比跨构建不可比。

---

## 4. 踩过的坑（改代码前先读）

**`mvn compile` 的 BUILD SUCCESS 可能是假的。** IDE（VS Code Java LSP）会往 `target/classes` 写 class，
Maven 增量编译会跳过那些文件。曾经有 3 处真实编译错误一路 BUILD SUCCESS，打出的 jar 里装着带
`Unresolved compilation problems` 的坏类，一运行就抛 `java.lang.Error`。**验证构建一律用 `clean`。**

**ORDER BY 不能进 wrapper。** `requiresOrderSensitiveComparison` 只要在查询文本里看到 `ORDER BY`
就切成顺序敏感比对。内层 base query 本身无序、原查询和变体的执行计划又不同 ⇒ 顺序天然可能不同
⇒ **必然假报告**。需要 ORDER BY 的（比如 `sqlite3Fts3DoclistPrev` 只能靠 `ORDER BY docid DESC` 触发）
放到 context setup 里，它不进 oracle 判定，但会进 context replay，覆盖率照样采得到。

**context setup 里不能有非确定值。** 语料快照是逐条比较语句文本做 delta 编码的。
`randomblob` / `random()` / `datetime('now')` / `CURRENT_TIMESTAMP` 会让每次 context 刷新
都被判定成变更、把整表重新序列化进每个快照。曾经因此让 `replay-all.sql` 的 94.5% 字节
都是两张探针表的导出数据。新增 setup 后务必扫一遍这几个模式。

**FTS 辅助函数只能作为裸投影项。** `offsets` / `snippet` / `matchinfo`（FTS3/4）必须直接出现在
FROM 里写了 fts 表名的那个 SELECT 的投影里 —— 不能放进聚合、不能用别名、**不能嵌在子查询里**。
唯一可行的形态是：

```sql
SELECT q.*, matchinfo(egraph_fts4m, 's') FROM (<base>) AS q, egraph_fts4m
WHERE egraph_fts4m MATCH '"lcsanchor alpha beta"'
```

`length(matchinfo(...))` 包一层是允许的。FTS5 的 `highlight`/`snippet`/`bm25` 同样要直接上下文，
但可以先在子查询里算好再外层聚合。

**随机提取在环状 e-graph 上会伪造节点。** `extract_randomized_impl` 检测到 e-class 环时，
若该 e-class 里没有叶子节点，旧代码 `return rec.add(SqlLang::Symbol(0))` 凭空造一个占位符 ——
但 `Symbol(0)` 不是中性的，`recexpr_to_sql_expr` 里 `symbols.get(&0)` 取的是**符号表第一个符号**，
所以一个环会静默变成一个真实列引用。原查询 `c0 = 5` 提取出的变体里会出现裸 `c0` 当布尔用：

```
(c0 OR (((c0 OR ((c0 OR c0) AND ((NOT (c0 OR ...
```

这些变体全部被 `validate_with_sqlite` 拒掉，代价是白跑一遍 SQLite 校验 —— 单次请求从 26ms
涨到 8603ms。base 53 条规则下 e-graph 基本无环，很少触发；一旦加入扩张型规则就每次都触发。
**现在的做法是放弃这次随机游走（返回 `None`），`extract_variants` 本来就会重试
`max_variants * 200` 次，放弃是免费的。**

**饱和预算越大不一定越好。** e-graph 越大环越多、被放弃的游走越多。实测（8 条代表性查询）：

| 规则集 | node_limit / time_limit | max_variants | 变体/查询 | 延迟 |
|---|---|---|---|---|
| base 53 | 5000 / 3000ms | 3 | 2.50 | 24ms |
| base 53 | 400 / 60ms | 32 | 15.25 | 69ms |
| base+extra 65 | 5000 / 3000ms | 3 | 0.88 | 40ms |
| **base+extra 65** | **400 / 60ms** | **32** | **25.88** | **52ms** |

默认值因此定为 `EGRAPH_NODE_LIMIT=400`、`EGRAPH_TIME_LIMIT_MS=60`，都可用环境变量覆盖。

**`Randomly.smallNumber()` 恒为偶数。** 它是 `(int)(|nextGaussian()|) * 2`，所以
`nrColumns = 1 + smallNumber()` 只能得到 1、3、5、7 —— **永远不会有 2 列或 4 列的表**。
这是 SQLancer 上游多年的既有行为，改它会同时改变所有 provider 的生成分布。

**被测表永远只有一张。** `targetTables` 是 `singletonList(chosen)`，所以 base query 结构上不可能有
JOIN；而候选池筛掉视图和虚表后，约 95% 的情况下只剩 `t0` 一张。这也是"跨列约束"在单列表上
退化成重复值的原因。

---

## 5. 代码地图

| 路径 | 职责 |
|---|---|
| `src/sqlancer/common/oracle/EGraphMetamorphicOracle.java` | oracle 主体：执行、比对、报 bug |
| `src/sqlancer/common/oracle/RustEGraphVariantGenerator.java` | e-graph 服务的 HTTP 客户端 |
| `src/sqlancer/sqlite3/SQLite3OracleFactory.java` | 约 60 个 coverage shape 的定义与 context setup |
| `src/sqlancer/sqlite3/oracle/EGraphPredicateFilter.java` | 谓词预过滤：四值可满足性 + e-graph 兼容性 |
| `src/sqlancer/sqlite3/oracle/EGraphCorpusCaseWriter.java` | 快照捕获与 delta 编码 |
| `src/sqlancer/sqlite3/oracle/EGraphContextReplayWriter.java` | context setup 的重放记录 |
| `src/sqlancer/sqlite3/oracle/SQLite3EGraphInputCorpus.java` | 语料输入解析 |
| `src/sqlancer/sqlite3/oracle/EGraphSqlCoverage.java` | workload 统计与丢弃原因归类 |
| `src/sqlancer/sqlite3/oracle/EGraphExampleLogger.java` | 人可读的端到端样例输出 |
| `egraph-server/src/sql_rewrite.rs` | e-graph 规则集（base 53 + extra 12）、随机提取、变体校验 |
| `EGRAPH-PENDING-DECISIONS.md` | 待拍板的改动清单（含各自的实测依据） |
| `coverage/sqlite/*.ps1` | 覆盖率测量与研究循环的工具链 |
