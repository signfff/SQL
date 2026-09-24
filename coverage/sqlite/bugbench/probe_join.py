import json, os, re, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = r"D:\sqlancer\coverage\sqlite\manual-long-codecov-20260921-010516\java-args.txt"
OLD = r"D:\sqlancer\coverage\sqlite\manual-long-codecov-20260921-010516"
CORPUS = ";".join([os.path.join(r"D:\sqlancer\coverage\sqlite", f) for f in
                   ["sqlite-official-select-only-variant-ready-corpus.sql", "auto-research-filtered-corpus.sql"]])
tag, seconds = sys.argv[1], int(sys.argv[2])
extra = sys.argv[3:]
workdir = os.path.join(HERE, "join", tag)
os.makedirs(workdir, exist_ok=True)
lines = []
for line in open(TEMPLATE, encoding="utf-8-sig").read().splitlines():
    line = line.replace(OLD, workdir)
    if line.startswith("--timeout-seconds="):
        line = "--timeout-seconds=%d" % seconds
    elif line.startswith("--egraph-input-file="):
        line = "--egraph-input-file=" + CORPUS
    lines.append(line)
for e in extra:
    lines.insert(1, e)
lines.insert(1, "-Degraph.knownBugs.log=" + os.path.join(workdir, "known-bugs.sql"))
args = os.path.join(workdir, "args.txt")
open(args, "w", encoding="utf-8").write("\n".join(lines))
p = subprocess.run(["java", "@" + args], capture_output=True, cwd=workdir, timeout=seconds + 240)
out = p.stdout.decode("utf-8", "replace") + p.stderr.decode("utf-8", "replace")
open(os.path.join(workdir, "out.log"), "w", encoding="utf-8").write(out)
hints = open(os.path.join(workdir, "workload-hints.txt"), encoding="utf-8", errors="replace").read()
known = os.path.join(workdir, "known-bugs.sql")
ktext = open(known, encoding="utf-8", errors="replace").read() if os.path.exists(known) else ""
trace = open(os.path.join(workdir, "egraph-trace.log"), encoding="utf-8", errors="replace").read()
base = re.findall(r"egraph-request start[^\n]*rewrite=(.*)", trace)
print(json.dumps({
    "tag": tag, "checks": len(base),
    "joins": sum(1 for q in base if re.search(r"\bJOIN\b", q, re.I)),
    "knownSuppressed": ktext.count("EGRAPH_KNOWN_BUG"),
    "asserts": len(re.findall(r"AssertionError", out)),
    "reportLines": [l.strip() for l in hints.splitlines() if "reported bug" in l or "# nested" in l or "# row-value" in l],
}, ensure_ascii=False))
