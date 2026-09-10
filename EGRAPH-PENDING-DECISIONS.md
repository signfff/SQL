# EGRAPH 决策与改动记录

> 2026-09-08。第一节是已按建议实施的（含实测依据），第二节是仍然开放、需要单独规划的。

# 一、2026-09-08 已实施

| # | 改动 | 依据 |
|---|---|---|
| 1 | sqlite-jdbc `3.49.1.0` -> `3.53.4.0` | 被测代码 2025-02-18 -> 2026-07-24；已确认 3.53.4 就是 SQLite 官方当前发布版 |
| 2 | oracle 区分变体/原查询报错，变体独有错误记入统计（不报告） | 上线即暴露两个真实缺陷；升级成报告需要先攒样本定性 |
| 3 | 空 base query 按 `egraph.emptyBaseCheckPercent`（默认 10）采样继续跑 | 让 `hasSingleSideEmptyMismatch` 从结构上不可能触发变成可触发 |
| 4 | 提取器环处理：不再伪造 `Symbol(0)`，改为放弃该次随机游走 | `Symbol(0)` 会被解析成符号表第一个符号即真实列引用；修复后延迟 8603ms -> 40ms |
| 5 | 删除 `isnull-to-isunknown` / `isnotnull-to-isnotunknown` | SQLite 不支持 `IS UNKNOWN`，把 `UNKNOWN` 当列名；曾导致约 16% 的 check 被静默丢弃 |
| 6 | 修 `CO_ROUTINE` wrapper 的双 LIMIT 语法错误 | base query 自带 `LIMIT 10`，wrapper 又拼 `LIMIT -1` |
| 7 | 新增 12 条比较规则（`EGRAPH_EXTRA_RULES=0` 可关） | 全部先在对抗性取值网格验过等价性 |
| 8 | `FORCED_VALUES` 加入 int64 / 2^53 / 亲和性边界 + 跨列边界组合行 | 唯一那个假报（`sub-to-add`+`add-assoc` 溢出）就是漏在取样上；回归测试 32 个变体全等价 |
| 9 | 重新启用 `between-decomp`（+ 反向 `between-compose`） | 13182 个亲和性组合零反例；是少数能改变字节码的规则 |
| 10 | 重新启用 `and-dist-or` / `or-dist-and` | 实测 SOUND，禁用原因是爆炸不是不等价；实测把 `MULTI_INDEX_OR` 从 ~100% lost 降到 57.1% lost |
| 11 | 饱和预算参数化并定默认 `EGRAPH_NODE_LIMIT=200` / `EGRAPH_TIME_LIMIT_MS=40` | 扫参数得出；预算越大环越多反而更差 |
| 12 | 捕获脚本 `--egraph-max-variants` 3 -> 16 | 变体/查询 2.50 -> 14.25；32 的变体/秒更高但 check 数掉 8 倍，取中间值 |
| 13 | `run-5h-codecov.ps1` 接入 auto-research 作为 Phase 3（非致命） | 原来只有 capture + coverage，第四步要手工跑 |
| 14 | 捕获脚本输出 `variant-only-errors.log` / `single-side-empty-reproducers.sql` 到 run dir | 新判据的产物要能追溯 |

最终配置的 300 秒冒烟（含语料，语料占 73%）：6939 checks / 93065 次执行 /
Explain 失败 5（基线 89）/ 变体独有错误 0 / 假报 0。

## 2026-09-09 四小时长跑之后的两处修复

| # | 改动 | 结果 |
|---|---|---|
| 15 | `auto-research-codecov.ps1:884` `temp_store` MEMORY -> FILE | 直接修复。finish-long 早已改成 FILE，这个脚本被漏掉，导致候选负载在"vdbesort PMA/外部归并子系统不可达"的条件下测量，而基线是 FILE 下产出的 —— 每个 delta 都有偏 |
| 16 | `finish-long-codecov.ps1` 新增 `-ContextPrelude`（**默认关**） | 见下，实测净负 |

### 为什么 `-ContextPrelude` 默认关

问题是真的：`Write-EGraphReplayChunks` 只写 PRAGMA preamble + case 行，从不注入 EGRAPH
context 建表，所以每个 chunk 的库里没有 wrapper shape 要查的探针表。20260909 长跑里
`no such table: egraph_fts4c` 7664 次、`egraph_fts_content_src` 1046 次，977/1097 chunk 标记失败。

实现方式：不解析 SQL，而是**让 SQLite 判定** —— 在空库上重放一遍 context，只保留成功的语句
（实测 626 条里 494 条自包含，滤掉的 132 条正是引用 `t0`/`x1`/`ttt` 等 SQLancer 自有表的）。

A/B（20260909 长跑的同一批 2000 个 case，4 worker，输入完全相同）：

```
              行覆盖    分支      函数      缺 context 错误
prelude 开    71.90%    76.62%    81.95%    201
prelude 开    71.86%    76.58%    81.92%    201     <- 同臂噪声 0.04pp
prelude 关    72.70%    77.41%    82.43%    250
```

**达到了设计目标**（`egraph_fts4c` 缺失 287 -> 233，缺 context 错误 250 -> 201），
**但代价是 0.80pp 行覆盖，是同臂噪声的 20 倍。**

排除过的机制：chunk 超时（两臂都是 0）、`CREATE ... already exists` 冲突（两臂都是 0）。
**机制仍未查明。** 在查明之前默认关，让流水线保留更好的那个数字，开关保留以便复现实验。

（注：200 case 样本上同臂噪声是 0.48pp，看不出差异；2000 case 才降到 0.04pp。
小样本上做这个 A/B 会得出"无差异"的错误结论。）

### 下一轮该查的
- prelude 为什么会**降低**覆盖率 —— 加了执行却少了覆盖，这本身反直觉，可能指向重放机制里
  另一个未知问题（比如 keyframe 快照与预建表的交互）
- 未覆盖报告里 `Oracle-target lines with no wrapper shape driving them: 1627`
  （other 1355 行 / 147 个函数、Memory/mutex 272 行）—— 这是唯一还有实质空间的方向
- `--egraph-max-variants` 从 16 降回 8 或 3：实测 case 数涨 10 倍覆盖率不动，
  变体数量不买覆盖率

## 2026-09-10 R-Tree 目标表：只加表没用，要喂可下推谓词

### 背景：为什么之前没成效

`egraph.rtreeTargets`（默认开）把 R-Tree 虚表加进 base query 的候选目标表。判据是对的 ——
R-Tree 的约束下推发生在 SQLite 前端归一化（`sqlite3WhereSplit` 展平 AND、`sqlite3ExprCommute`
归一化 `const OP col`）**之后**，所以等价改写不会塌缩成同一份字节码；普通表上会塌缩，改写白做。

**但随机表达式生成器产不出可下推的谓词。** 下推要求 `坐标列 <op> 常量` 且直接位于顶层
AND/OR 结构上；生成器产的是任意算术树、列 vs 列比较、`IS NULL` 乘法。

手工验证（sqlite3 3.51，rt 表 64 行种子数据）：

| 谓词 | 等价写法数 | 不同 plan |
|---|---|---|
| `c1 <= 6.0 AND c2 >= 6.0`（可下推） | 8 | **6** |
| `(c2-c3) * (c1 IS NULL)`（生成器实际产出） | 10 | 1 |
| `(c3 <= c0) * c3`（生成器实际产出） | 32 | 1 |

长跑报告印证（`egraph-hints-plan.txt`，8375 checks）：RTREE_VIRTUAL 多 plan 率 5.8%，
REGULAR 17.4% —— R-Tree 拿走 61% 的 check 名额却只有 1/3 的区分率，净负。

> 注：`manual-long-codecov-20260909-002155` 那次覆盖率长跑**没开** rtreeTargets
> （`java-args.txt` 里没有该参数，也无 RTREE_VIRTUAL 记录）。上面的数据来自
> 2026-09-09 15:51–16:32 的 `egraph-hints-rtree/rt2/rt3/rt4/plan/ex.txt` 一批短跑。

### 已实施（工作区，**未提交**）

`SQLite3OracleFactory.java`：

1. `rtreeCoordinateColumns()` —— 原 `isRtreeTable` 的布尔缓存改成存坐标列数，从
   `sqlite_master` 建表语句里数：id 列之后、第一个 `+辅助列` 之前的才算。数错不危险
   （辅助列上的约束只是不被消费，退化成后置过滤）。
2. `generateRtreePushdownWhere()` —— 目标表是 R-Tree 时按约束项拼 WHERE，6 种形状：
   点包含 / 区间重叠 / 严格界（`RTREE_LT`、`RTREE_GT` 是与 `LE`/`GE` 不同的 opcode）/
   单边约束 / 全开区间（保证非空）/ 两对坐标同时约束（4 个约束项）。
   再各 1/10 概率或上第二个约束列表（打 `MULTI-INDEX OR`）、与一个随机残余项。
   常量整数/浮点混用，取值贴 `seedRtreeTable` 的 [-20, 24]。
3. 报告分桶拆成 `RTREE_VIRTUAL_PUSHDOWN` / `RTREE_VIRTUAL_RANDOM`，plan 直方图正好按这个
   字符串分组，同一次跑里就有对照。**注意旧报告用的是 `RTREE_VIRTUAL`，跨报告对比时名字变了。**
4. 新开关 `-Degraph.rtreePushdownPercent`（默认 80，0 = 全走旧路径），已写进 `EGRAPH.md`
   属性表，顺带补上一直没记的 `-Degraph.rtreeTargets`。

### A/B 结果（150s × 2 线程，同机同参，只差这一个开关）

| 桶 | 多 plan 率 |
|---|---|
| `RTREE_VIRTUAL_PUSHDOWN` | **1180 / 1262 = 93.5%**（9+ plan 有 139 个） |
| `RTREE_VIRTUAL_RANDOM`（同跑内对照） | 18 / 281 = 6.4% |
| `RTREE_VIRTUAL_RANDOM`（control 臂） | 41 / 693 = 5.9%（与旧长跑 5.8% 一致） |
| `REGULAR` | 13.9% / 17.6% |

全跑口径 **9.9% → 57.6%**，能区分字节码的 check 绝对数 104 → 1297，**12.5 倍**。
**吞吐反而更高**（150s 内 2268 vs 1056 checks）：可下推谓词好满足，非空探针丢弃率
43% → 6.8%。假报 0、异常 0、单边空 0。

生成出来的样子：

```sql
SELECT ALL * FROM rt1 WHERE rt1.c1 <= 24.5 AND rt1.c2 >= 24.5 LIMIT 10
SELECT ALL * FROM rt1 WHERE (rt1.c1 < 7.5 AND rt1.c2 > 7.5) AND NOT (...随机残余项...) ORDER BY rt1.c2 ASC LIMIT 10
```

### 顺带查清的：虚表的数据从哪来

三条独立来源：

1. **`seedRtreeTable`（`SQLite3Provider.java:316`）** —— 建 `rt1` 后立刻灌 64 行确定性数据，
   互相重叠、嵌套的包围盒，让树真的分叉。实测对 3列/5列/7列/带辅助列四种形状都能插满 64 行。
2. **SQLancer 通用 INSERT/UPDATE** —— 只排除视图和只读表，虚表会被选中，但基本插不进去。
   实测两个真实库：`rt1` 65/66 行，其中 64 行来自种子，150 秒里通用 INSERT 只挤进 1–2 行。
3. **wrapper shape 的探针表** —— `egraph_rtree`（3 个盒子）、`egraph_rtree_deep`（递归 CTE
   生成 32×32 网格 384 个盒子），常量 INSERT，不参与变体比对，纯覆盖率用。

R-Tree 插入语义实测（sqlite3 3.51）：

| 写法 | 结果 |
|---|---|
| 完整一行，min ≤ max | OK |
| 只给坐标对的一半 | **失败** `rtree constraint failed: rt.(c1<=c2)`（没给的坐标默认 0） |
| min > max | 失败，同上 |
| 坐标给 `NULL` / `'abc'` | 静默变成 `0.0` |
| `INSERT OR IGNORE` 违反约束 | **静默丢弃，不报错** |
| 其余 `OR ABORT/REPLACE/FAIL/ROLLBACK` | 抛 `SQLITE_CONSTRAINT`，被 `getInsertUpdateErrors()` 的 `[SQLITE_CONSTRAINT]` 吞掉 |

### 还没做的

- **改动未提交**，在工作区。
- `seedRtreeTable` 用 `nrPairs = (columns.size()-1)/2` 算坐标对，**把辅助列 `+c3` 也算成坐标**，
  往 BLOB 类型的辅助列里写坐标数字。不报错（辅助列什么都收），但和新加的
  `countRtreeCoordinateColumns`（遇到 `+` 就停）不是同一套算法。两行的事，值得对齐。
- 长跑还没在打开 pushdown 的情况下跑过；`rtree.c` 的行覆盖当前 88.31%
  （整个 amalgamation 均值 86.90%），主要由两个 RTREE context shape 撑着，
  **target-table 这一路对 `rtree.c` 覆盖的贡献没单独 A/B 过**。
- 路径转义 bug：`manual-long-codecov-20260909-002155/java-args.txt` 里
  `-Degraph.variantOnlyError.log=...002155ariant-only-errors.log` —— `\v` 被当转义吃掉，
  `variant-only-errors.log` 写去了错的地方。出在拼路径的 PowerShell 脚本里。

---

# 二、仍然开放

> 2026-09-08。以下每条都会改变 bug 判定语义、吞吐特征或测试目标，属于需要拍板的决定，
> 所以只记录不实施。已实施的三处基础改动见文末。

## 1. `add-assoc` / `mul-assoc` 在整数溢出边界不成立 —— 删掉还是加守卫

实测（SQLite 3.53.4）：

```sql
(9223372036854775807 + 1) + -1  -->  9.22337203685478e+18   (REAL)
9223372036854775807 + (1 + -1)  -->  9223372036854775807    (INTEGER)

(4611686018427387904 * 4) * 0   -->  0.0    (REAL)
4611686018427387904 * (4 * 0)   -->  0      (INTEGER)
```

SQLite 整数溢出转 REAL 是文档行为，所以这是**假报来源，不是 bug**。这两条规则同时又是
少数能改变编译后字节码的规则，所以删掉会损失一点检测面。

**2026-09-08 更新：不再是理论，有了真实反例。** 开启空 base 采样后的第一轮 300 秒长跑
（218986 对变体比较）里，`hasSingleSideEmptyMismatch` 第一次触发，抓到的就是这个：

```
-- egraph-single-side-empty-reproducers.sql
原查询 WHERE: (t0.c0 - t0.c0) + (t0.c0 >= t0.c0)        -> 9 行
变体   WHERE: ((-t0.c0) + (t0.c0 >= t0.c0)) + t0.c0      -> 0 行
触发行的 c0 = -9223372036854775808
```

手工验证：

```
原式   (c0-c0) + (c0>=c0)      = 0 + 1                = 1    (真)
变体   ((-c0) + (c0>=c0)) + c0 = (9.22e18 + 1) + c0    = 0.0  (假)
肇因   -(-9223372036854775808) 溢出 int64 -> REAL 9.22337203685478e+18，丢精度
```

用到的规则是 `sub-to-add` + `add-assoc`。假报率不高（218986 对里 1 个），
但确认了这条规则链在 int64 边界上不成立。注意 Rust 侧的 `validate_with_sqlite`
没能拦住它 —— 它的随机取样没覆盖到 int64 边界值，这也是选项 (b) 之外的第四个选项：
**(d) 给 `validate_with_sqlite` 的取样强制加入 int64 边界值和 REAL/INTEGER 分界值。**

选项：
- (a) 直接删除这两条（连同 `sub-antisym`，同样的溢出问题）
- (b) 加守卫：只在能静态判定不溢出时应用（需要在 egraph 里带区间分析，工作量大）
- (c) 保留，但在 Java 侧限制算术字面量幅度，让溢出概率趋零（最省事，但削弱了边界测试）
- (d) 保留规则，改为在 `validate_with_sqlite` 的取样里强制加入 int64 边界值 —— 让校验层拦住它，而不是删规则（我倾向这个：不损失检测面，且对未来所有算术规则都生效）

## 2. `egraph.emptyBaseCheckPercent` 的默认值定多少

已实现为可调，默认 **10**。这是我拍的数，需要你确认或 A/B。

- 0 = 恢复原来的"原查询空就丢弃"
- 10 = 约 78% 的 base query 探针为空，其中 10% 会继续跑变体
- 100 = 全部跑，single-side-empty 判据满负荷，但大部分 check 是两边都空（无信息）

建议用你之前测"按谓词补数"那套 A/B 方法量一遍：看区分率和吞吐的交换比。

## 3. 变体独有错误：只记录，还是升级成 bug 报告

已实现为**只记录**（报告新增一节 + `-Degraph.variantOnlyError.log` 落盘）。
没有升级成 `AssertionError`，因为有合法情况：改写后的表达式树更深，可能撞
"expression tree is too large"；改写后的形状可能让索引不再适用，撞 "no query solution"。

要不要升级成报告，得先看第一轮日志里这些错误的实际构成。

## 3b. `between-decomp` 要不要重新启用（有实测证据，但历史上因 3 个假报被禁）

`sql_rewrite.rs` 里这条被注释掉，注释写的是"混合类型下 BETWEEN 和两个比较不等价，
改变了类型强制顺序，产生假报（BUG #1, #2, #4）"。

我在 SQLite 3.53.4 上重测了：**6 种声明亲和性（INTEGER/TEXT/REAL/BLOB/NUMERIC/无）
× 13 个列值（NULL/''/文本/数字文本/带空格数字/0/整数/浮点/BLOB）× 169 组 (lo,hi) 边界
= 13182 个组合，零反例。** SQLite 官方文档也写明二者等价，唯一差别是 BETWEEN
只求值 x 一次。

所以历史上那 3 个假报，可能是：
- (a) 同一个变体里另一条规则造成的，归因归错了
- (b) 3.49.1 之后被 SQLite 修掉了
- (c) 真正的差异在"x 只求值一次" —— 若 `?x` 非确定（如 `random()`），两侧必然不同

(c) 是唯一残留的真风险，但 `egraphMode` 已经移除了 `ExpressionType.FUNCTION`，
生成侧产生不了 `random()`，语料侧则会被 `unsupportedTokens` 拦掉。

**这条规则的价值**：它是少数能改变编译后字节码的规则之一（实测：索引区间扫 →
两段 OR range scan）。要不要开，你拍板；如果开，第一轮长跑要盯 BUG #1/#2/#4 那类假报有没有回来。

## 3c. 分配律 `and-dist-or` / `or-dist-and` 要不要启用

注释写的禁用原因是"指数级 e-graph 爆炸"，**不是不等价**——我实测这两条在
Kleene 三值逻辑下 SOUND。它们能大幅增加变体数（用户的明确目标），
而且 `(x AND y) OR (x AND z)` 这个形态正是 SQLite OR-optimization / MULTI_INDEX_OR 的入口。

代价是吃 `node_limit` 预算。egg 有 node_limit / time_limit 兜底，不会真的挂，
但会挤掉其它规则的触发机会并拉高延迟。要开的话建议配合下面这条一起调。

## 3d. 饱和预算的默认值（已改，需确认）

我加了两个环境变量并**改了默认值**，因为新增的扩张型规则和已有的压缩型规则
形成增长循环（`(= x y)` → `(and (>= ..) (<= ..))` → `(>= ..)` → `(or (> ..) (= ..))` → 回到起点，
每轮更深一层），导致 runner 永远跑到限额而不是真正饱和：

| 变量 | 原值（硬编码） | 新默认 |
|---|---|---|
| `EGRAPH_NODE_LIMIT` | 5000 | 1200 |
| `EGRAPH_TIME_LIMIT_MS` | 3000 | 150 |

原值下加完新规则，单次请求从约 30ms 涨到 >10s（基准脚本 120s 超时都没跑完 12 条查询），
吞吐会崩。新默认来自参数扫描（见 EGRAPH.md），目标是最大化**变体/秒**而不是变体/查询。
这个数需要你确认，或者用长跑 A/B 定。

## 3e. `--egraph-max-variants` 该设多少（现在长跑命令里是 3）

实测（8 条代表性查询，新规则集，node=400/t=60ms）：

| max_variants | 变体/查询 | 延迟 | 变体/秒 |
|---|---|---|---|
| 3 | 3.00 | 18ms | 166.7 |
| 8 | 8.00 | 26ms | 307.7 |
| 16 | 13.62 | 34ms | 400.6 |
| 32 | **25.88** | 52ms | **497.7** |

变体/秒在 32 时最高，但一次 check 的执行次数从 1+3=4 涨到 1+32=33，
所以 **check 数会掉约 8 倍**。32 个变体是同一个 base 谓词、同一份数据上的不同写法，
彼此高度相关；而 8 倍的 check 数意味着 8 倍的 base 谓词和数据状态。
哪个出 bug 更多是经验问题，需要长跑 A/B，我不替你定。我测试时用的是 16。

## 3f. 观察（不需要改，但你应该知道）

变体经过 Rust 服务往返后会**丢掉 `INDEXED BY` 子句**：

```
original: SELECT ALL * FROM t0 INDEXED BY i86 WHERE ...
variant : SELECT ALL * FROM t0            WHERE ...
```

这不是不安全（`INDEXED BY` 按 SQLite 语义只影响计划、不影响结果，
若无法满足则报 "no query solution"），而且它顺带让两侧的执行计划不同，
对变形测试反而有利。但如果哪天要精确归因"是谁改变了计划"，要记得这一层。

## 4. 测试目标：要不要上 debug 构建 / trunk

当前已换到 sqlite-jdbc 3.53.4.0（SQLite 3.53.4, source_id 2026-07-24, 约 6 周新）。
仍然是 release build，`assert()` 全被编译掉，只能观测"结果集不同"这一种失效模式。

下一步选项（成本递增）：
- 自己编 `sqlitejdbc.dll`（SQLite amalgamation + sqlite-jdbc 的 JNI 胶水），
  加 `-DSQLITE_DEBUG -DSQLITE_ENABLE_API_ARMOR`，用
  `-Dorg.sqlite.lib.path=<dir> -Dorg.sqlite.lib.name=<dll>` 挂载（已确认
  `SQLiteJDBCLoader.java:307-309` 支持，不需要改 SQLancer 代码）
- 代价：`assert()` 失败会 `abort()` 整个 JVM，长跑要能从崩溃恢复；`SQLITE_DEBUG` 慢 3-5 倍
- 副作用：会让 memory 里"插桩构建必须与 sqlite-jdbc 编译选项对齐"那条失效，覆盖率基线要重取

## 5. 单表限制 —— 是否放开 JOIN

`SQLite3OracleFactory` 里 `targetTables = new AbstractTables<>(singletonList(chosen))`，
结构上不可能生成 JOIN。而 SQLancer 历史上在 SQLite 找到的 bug 大量集中在
多表 LEFT JOIN + WHERE 下推。放开需要同时改 egraph 侧（当前规则集没有关系代数规则）。

## 6. ORDER BY 永久在射程外

`requiresOrderSensitiveComparison` 见到 `ORDER BY` 就切顺序敏感比对，而内层 base query
无序 + 两侧计划不同 ⇒ 必然假报。所以 ORDER BY 只能进 context setup，不进判定。
代价是"ORDER BY + 索引"这一类 bug（DESC 索引排序错、ORDER BY + LIMIT 走错索引）
完全无法观测。若要覆盖，需要在改写时保证两侧都有全序（比如强制 ORDER BY 全部投影列）。

## 7. ~~长跑是否加载了语料~~ —— 已排除，不是问题

2026-09-08 实测：`start-long-codecov-capture.ps1:181` 确实传了 `--egraph-input-file`，
三个语料一起（official variant-ready + high-coverage 2.8GB + auto-research 23MB）。
手工跑一轮验证，四个来源都出现在报告里：

```
# CORPUS_AUTO_RESEARCH             806
# CORPUS_HIGH_COVERAGE            107
# CORPUS_OFFICIAL_SELECT_TEMPLATE  58
# RANDOM_GENERATED_1_3            352     <- 语料占 71%
```

旧报告里只有 `RANDOM_GENERATED_1_3` 的那两次，是手工启动没带该参数的跑，不是缺陷。

**唯一的观察**：加载 2.8GB 语料期间前约 30 秒执行 0 条查询。`readStatements` 把整个文件
读进 `List<String>`，而 `MAX_QUERY_INPUTS`（默认 20000）是**读完整个文件之后**才判断的，
所以 2.8GB 全进了堆。长跑里 30 秒可忽略；但如果哪天要跑短实验，
用 `-Dsqlite3.egraph.input.maxQueries=<N>` 也救不了启动时间 —— 那需要把上限判断挪进读取循环。

---

# 已实施的基础改动（2026-09-08）

1. `pom.xml:302` sqlite-jdbc `3.49.1.0` -> `3.53.4.0`（SQLite 3.49.1 / 2025-02-18 -> 3.53.4 / 2026-07-24）
2. `EGraphMetamorphicOracle.getResultRows` 增加 variant/original 角色区分，
   变体独有错误记入 `EGraphSqlCoverage.recordVariantOnlyError`（只统计，不报告）
3. `SQLite3OracleFactory` 空 base query 不再无条件丢弃，按 `egraph.emptyBaseCheckPercent`
   （默认 10）采样后继续跑变体，让 `hasSingleSideEmptyMismatch` 可触发
4. `sql_rewrite.rs` 提取器环处理修复：`extract_randomized_impl` 撞到无叶子的 e-class 环时
   不再伪造 `Symbol(0)`（它会被解析成符号表第一个符号，即一个真实列引用），改为放弃该次
   随机游走返回 `None`。修复前后同一基准：延迟 8603ms -> 40ms，变体/查询 0.75 -> 0.88
5. `sql_rewrite.rs` 删除 `isnull-to-isunknown` / `isnotnull-to-isnotunknown` 两条规则 ——
   **SQLite 不支持 `IS UNKNOWN` / `IS NOT UNKNOWN`**，把 `UNKNOWN` 当列名解析。
   实测代价：300 秒长跑里 3133 个变体独有错误中 3101 个是这个，且变体报错会中止整个 check，
   相当于约 16%（3133/19615）的 check 被静默丢弃
6. `sql_rewrite.rs` 新增 12 条比较规则（`make_extra_comparison_rules`，可用
   `EGRAPH_EXTRA_RULES=0` 关掉做 A/B），全部先在对抗性取值网格上验过等价性
7. `sql_rewrite.rs` 饱和预算参数化并改默认：`EGRAPH_NODE_LIMIT` 5000 -> 400，
   `EGRAPH_TIME_LIMIT_MS` 3000 -> 60（见 3d）
