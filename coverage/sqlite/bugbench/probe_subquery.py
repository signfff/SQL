import json, os, re, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = r"D:\sqlancer\coverage\sqlite\manual-long-codecov-20260921-010516\java-args.txt"
OLD = r"D:\sqlancer\coverage\sqlite\manual-long-codecov-20260921-010516"
CORPUS = ";".join([os.path.join(r"D:\sqlancer\coverage\sqlite", f) for f in
                   ["sqlite-official-select-only-variant-ready-corpus.sql", "auto-research-filtered-corpus.sql"]])
tag, seconds, percent = sys.argv[1], int(sys.argv[2]), sys.argv[3]
workdir = os.path.join(HERE, "subq", tag)
os.makedirs(workdir, exist_ok=True)
lines = []
for line in open(TEMPLATE, encoding="utf-8-sig").read().splitlines():
    line = line.replace(OLD, workdir)
    if line.startswith("--timeout-seconds="):
        line = "--timeout-seconds=%d" % seconds
    elif line.startswith("--egraph-input-file="):
        line = "--egraph-input-file=" + CORPUS
    lines.append(line)
lines.insert(1, "-Degraph.subqueryPredicatePercent=" + percent)
args = os.path.join(workdir, "args.txt")
open(args, "w", encoding="utf-8").write("\n".join(lines))
p = subprocess.run(["java", "@" + args], capture_output=True, cwd=workdir, timeout=seconds + 240)
out = p.stdout.decode("utf-8", "replace") + p.stderr.decode("utf-8", "replace")
open(os.path.join(workdir, "out.log"), "w", encoding="utf-8").write(out)
trace = open(os.path.join(workdir, "egraph-trace.log"), encoding="utf-8", errors="replace").read()
base = re.findall(r"egraph-request start[^\n]*rewrite=(.*)", trace)
sse = os.path.join(workdir, "single-side-empty-reproducers.sql")
stext = open(sse, encoding="utf-8", errors="replace").read() if os.path.exists(sse) else ""
print(json.dumps({
    "tag": tag, "percent": percent, "baseQueries": len(base),
    "inSubquery": sum(1 for q in base if " IN (SELECT" in q.upper()),
    "rowValue": sum(1 for q in base if re.search(r"\([^()]+,[^()]+\) IN \(SELECT", q, re.I)),
    "variantsZero": trace.count("variants=0"),
    "sse": stext.count("EGRAPH_SINGLE_SIDE_EMPTY_BEGIN"),
    "asserts": len(re.findall(r"AssertionError", out)),
}, ensure_ascii=False))
