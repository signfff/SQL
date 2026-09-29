# BugBench：用 SQLite 官方 bug 报告测 EGRAPH oracle 的检出率

把 sqlite.org/bugs 论坛最近的 300 个帖子变成一条可重复的基准：
对每个 bug 的官方 reproducer，跑一次 EGRAPH oracle，看等价改写能不能把它报出来。

判据分两层，全部是我们自己的流程，不依赖官方帖子的 expected/actual 字段：

- **检测层（蜕变测试）**：`run_case.py` 把语料喂给 EGRAPH oracle。
  同一份数据上，原查询与等价改写的结果集必须一致，不一致即检出。
  信号只有两种：非空侧对比抛 `AssertionError`，或一侧空一侧非空
  （落在 `single-side-empty-reproducers.sql` 的 `EGRAPH_SINGLE_SIDE_EMPTY_BEGIN` 块里）。
- **定性层（差分测试）**：`referee.py` 把同一 reproducer 分别喂给 release 版
  和 trunk 版 SQLite，输出不同 ⇒ release 还带着这个 bug 且上游已修。

## 目录与数据

| 路径 | 内容 |
|---|---|
| `threads/` `threadtxt/` | 300 帖原始 HTML 与纯文本（不入库，用 `curlcfg.txt` 可重新抓） |
| `threads.json` `curlcfg.txt` | 300 帖索引与抓取配置（入库，重新抓 `threads/` 的入口） |
| `extract/out-*.jsonl` | 结构化提取记录（入库；158 条，含 crash / core-sql-correctness 分类） |
| `all.json` `core.json` | 分类汇总（入库）；`core.json` = 35 个核心结果错误 bug |
| `corpus/<id>.sql` | 每个 bug 一个语料（官方 setup + bug query 原样） |
| `verdicts.json` | 18 个进入实测的用例逐条判定（检出机制、repro_on_3534、run_out） |
| `referee.json` | trunk 裁判结果（release/trunk 输出与 live_in_release） |
| `runs4/<id>/` | 每例 60s 实测产物（不入库，`run_case.py` 重跑生成）：out.log、workload-hints.txt、single-side-empty 块 |
| `run_case.py` | 跑一个语料，输出一条 JSON 判定 |
| `referee.py` | release vs trunk 差分裁判，写 referee.json |
| `build_bench.py` | 从 extract 记录合并分类、写语料 |
| `ab_empty_base.py` | 放开空基查询（allowEmptyBase）的 A/B 工具 |

`join/`、`gcov-sink/` 是后续 JOIN 实验与裁判运行的临时产物，不入库。

## 测试台怎么跑

```bash
# 前置：egraph-server 已在 127.0.0.1:3000 监听；SQLancer 已 mvn -o clean package
# 路径可用环境变量覆盖，默认值指向本机原有位置（见各脚本头部）
python run_case.py corpus/4f3e1f1cd7.sql 60 runs4/4f3e1f1cd7
python referee.py corpus            # 写 referee.json
```

`run_case.py` 的检出信号只认两个来源：stdout 里的 `AssertionError`
和 single-side-empty 文件里的块计数——**stdout 里的 "mismatch" 字面不是信号**，
第一版测试台因此漏判过（阳性对照 `nested-right-join-regression-corpus.sql` 必做）。

## 300 帖的漏斗

```
300 帖（约 128 天）
 ├─ crash 45
 ├─ core-sql-correctness 35   ← 基准
 ├─ ext-or-tool 32 / other 28 / perf 8
 └─ …
35 个核心 bug
 ├─ 17 个被语料入口拒收（no-where 10、not-select 2、derived-from 2、GROUP BY/OVER/UNION 各 1）
 └─ 18 个进入实测（verdicts.json）
     ├─ ✅ 检出 3
     ├─ 目标不存在 6（repro_on_3534=false，bug 在 3.53.4 上不复现）
     └─ 真损失 9（见下）
```

## 三个检出：逐个详解

三个都靠 single-side-empty 信号（一侧有行一侧空），且都被 referee 确认
`live_in_release: true`、trunk 已修。共同机制：**SQLite 的 bug 活在特定执行计划
路径上；e-graph 的等价改写改变了计划形状，一侧撞 bug 路径、一侧不撞**。

### `4f3e1f1cd7` — 嵌套 RIGHT JOIN + WHERE 多出一行

官方现象：`SELECT * FROM t1 JOIN t0 ON (...) RIGHT JOIN t2 ON 1 WHERE t1.b IS NULL`
应返回空，3.53.4 返回 `NULL|NULL|7`。

| 查询 | 结果集 |
|---|---|
| base `WHERE t1.b IS NULL` | **1 行** `NULL\|NULL\|7`（撞 bug） |
| 变体 `(t1.b IS NOT TRUE) AND (t1.b IS NOT FALSE)` | **0 行**（正确） |

e-graph 把 `IS NULL` 三值逻辑展开（规则 `603cae55`），改写了计划绕开 bug。
每 check 恒 2 个变体（同一种语义的两种 AND 交换序），60s 内 1462 次 var-only-empty。
检测侧规则**早于**生成侧就绪——之前抓不到只是因为生成器根本不产 JOIN。

### `765ea1c83b` — OR 转 IN 丢列排序规则

官方现象：`WHERE t1.a = t2.val OR t1.b = t2.val`（t1 两列 NOCASE、t2.val 有索引）
应返回 hello、world 两行，OR-to-IN 优化丢 collation 后返回 0 行。

| 查询 | 结果集 |
|---|---|
| base | **0 行**（丢 2 行） |
| 变体·德摩根 `NOT ((t2.val<>t1.a) AND (t1.b<>t2.val))` | **1 行** world |
| 变体·BETWEEN `(t1.b=t2.val) OR (t2.val BETWEEN t1.a AND t1.a)` | **1 行** world |
| 正确结果 | 2 行 hello、world |

两侧都错、错得不同：变体保留 world（NOCASE 下 'World'='world'）但丢 hello
（BETWEEN 走 BINARY 排序规则）。检出靠放开空基查询（`allowEmptyBase`，默认开）——
base 0 行不再被当噪声丢掉，1442 次 orig-only-empty。
注意这里混入一层不健全性：德摩根把 `t1.a = t2.val` 变成 `NOT (t2.val <> t1.a)`，
SQLite 的 `=`/`<>` 排序规则取左操作数，交换后 NOCASE 变 BINARY——
但检出本身成立，trunk 裁判确认 release 错。

### `6c97dbe469` — row-value IN + min()

官方现象：`(((c1),(c1)) IN (SELECT c.c1, min(c.c1) FROM t0 AS c))` 应返回 -1，实际 0 行。

| 查询 | 结果集 |
|---|---|
| base | **0 行**（撞 bug） |
| 变体 `NOT (NOT (...))` | **-1**（正确） |
| 变体 `p AND p` / `p OR p` | **0 行**（子查询求值两遍仍在 bug 路径） |

row-value IN 是 e-graph 语言外的原子（根节点 Symbol），正常规则集产 0 变体。
`identity_variants` 兜底（commit `4cad5702`）产三件套，确定性恒 3 个变体/check；
只有双重否定改变了子查询物化路径，复制类变体零信号。
生成侧空白同样关键：`egraph.subqueryPredicatePercent`（默认 30）让随机路径
能产出这种形状，100% 档 5 分钟内随机路径自己复现了这份报告。

## 15 个没检出的卡点

**第一层：6 个 bug 在 3.53.4 上不存在**（`repro_on_3534: false`，流程无责）：
f5d54eb0c5、d4dcff8410、6c13952293、1693eb8cfd、2c00db58f8、6caf587bf1。
重跑时流程健康（93–100% 有变体、大量 2 plans），一致是因为目标不在。

**第二层：9 个真损失，按卡点分五类**：

| 卡点 | 用例 | 机制 |
|---|---|---|
| 聚合值内 bug，改写碰不到 | 209d3c6472、51b256b79a | `count(*)` 恒返回一行，single-side-empty 信号不存在；IN 原子双重否定改了计划但 IN 求值路径没变，两侧 count 值同错 |
| 0 变体 | 8ebae091a9、6870c930b7、f9d7a71210 | WHERE 在相关子查询内部 / WHERE 是标量子查询原子 / WHERE 根是 AND 且两边是 json 原子（identity 兜底只在 Symbol 根触发） |
| 变体被优化器折叠 | 0ee3d0537b | `NOT(NOT(LIKE))` 被折叠，1639/1639 全 1 plan（rewrite changed nothing） |
| 两侧都空 | 135787579e | bug 是"少返回行"，改写绕不开 IN(SELECT) 路径，722/731 两侧都 0 行 |
| bug 在索引匹配路径 | 6246e57faf、f65fd0e5fd | 计划变了但改写没动到索引匹配子表达式，两侧走同一个 bug 索引 |

## 改进方向（评估过，未实施）

- **P1**：NOT INDEXED 变体在语料场景重开——精确瞄准聚合值类 2 个 + 索引路径类 2 个。
  20260919 回滚的败因（随机负载触发率 0.3%、吞吐腰斩）在精选用例上不成立；
  memory 记录当时已实测 NOT INDEXED 对 51b256b79a 返回正确 4 行。
- **P2**：identity 兜底扩展到 AND/OR/IS 根——几行代码，预期低（折叠风险）。
- **P3**：不可折叠恒等变体库（`p OR (p AND 0)` 类）——针对 1-plan 类。
- **不做**：e-graph 进入子查询内部改写（语言级工程）、LIKE→= 条件规则
  （LIKE 语义坑多，收益 1 个用例）。

任何改动的验证框架：18 个语料重跑 `run_case.py`，检出数应升；
6 个 `repro_on_3534: false` 的用例必须仍为 0 检出（假阳性防线）。

## 为什么"之前"抓不到这三个

不是检测力的问题，是**负载形状与官方 bug 脱节**。0921 长跑 52258 条基查询：
JOIN 0 条、行值 0 条、IN(SELECT) 0 条——生成器只会单表 + 比较/布尔/算术。
三个检出对应的形状（RIGHT JOIN、跨表 OR + NOCASE 索引、行值 IN + 聚合）
全部在空白里。检测侧（IS NULL 展开规则、oracle 判据）早就在位，
缺的只是"生成得出这种查询"——这正是 `subqueryPredicatePercent`
（commit `acfe09f1`）和 corpus 通道 `allowJoin` 的动机。
