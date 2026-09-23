"""A/B the allowEmptyBase switch on the normal long-run configuration.

Usage: python ab_empty_base.py <seconds> <repeats>
Runs the standard long-run arguments (all three corpora, random path enabled) with the
switch off and on, and reports checks, throughput and any assertion raised.
"""
import json
import os
import re
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
TEMPLATE = r"D:\sqlancer\coverage\sqlite\manual-long-codecov-20260921-010516\java-args.txt"
OLD = r"D:\sqlancer\coverage\sqlite\manual-long-codecov-20260921-010516"
CORPUS_DIR = r"D:\sqlancer\coverage\sqlite"
CORPUS_SMALL = ";".join([
    os.path.join(CORPUS_DIR, "sqlite-official-select-only-variant-ready-corpus.sql"),
    os.path.join(CORPUS_DIR, "auto-research-filtered-corpus.sql"),
])


def run(tag, seconds, allow_empty):
    workdir = os.path.join(HERE, "ab", tag)
    os.makedirs(workdir, exist_ok=True)
    lines = []
    for line in open(TEMPLATE, encoding="utf-8-sig").read().splitlines():
        line = line.replace(OLD, workdir)
        if line.startswith("--timeout-seconds="):
            line = "--timeout-seconds=%d" % seconds
        elif line.startswith("--egraph-input-file="):
            # The high-coverage corpus is 6.7 GB; a short run spends all its time reading it
            # and never reaches a check. The two smaller corpora exercise the same paths.
            line = ("--egraph-input-file=" + CORPUS_SMALL)
        lines.append(line)
    if allow_empty:
        lines.insert(1, "-Dsqlite3.egraph.corpus.allowEmptyBase=true")
    args = os.path.join(workdir, "args.txt")
    open(args, "w", encoding="utf-8").write("\n".join(lines))
    proc = subprocess.run(["java", "@" + args], capture_output=True, cwd=workdir,
                          timeout=seconds + 240)
    out = proc.stdout.decode("utf-8", "replace") + proc.stderr.decode("utf-8", "replace")
    open(os.path.join(workdir, "out.log"), "w", encoding="utf-8").write(out)
    trace = os.path.join(workdir, "egraph-trace.log")
    ttext = open(trace, encoding="utf-8", errors="replace").read() if os.path.exists(trace) else ""
    sse = os.path.join(workdir, "single-side-empty-reproducers.sql")
    stext = open(sse, encoding="utf-8", errors="replace").read() if os.path.exists(sse) else ""
    queries = re.findall(r"Executed (\d+) queries", out)
    return {
        "tag": tag,
        "allowEmptyBase": allow_empty,
        "queries": int(queries[-1]) if queries else 0,
        "checks": ttext.count("original-exec done"),
        "emptyBaseKept": ttext.count("kept=true"),
        "sse": stext.count("EGRAPH_SINGLE_SIDE_EMPTY_BEGIN"),
        "asserts": len(re.findall(r"AssertionError", out)),
    }


def main():
    seconds, repeats = int(sys.argv[1]), int(sys.argv[2])
    results = []
    for i in range(repeats):
        for allow in (False, True):
            tag = "%s-%d" % ("on" if allow else "off", i)
            r = run(tag, seconds, allow)
            results.append(r)
            print(json.dumps(r, ensure_ascii=False), flush=True)
    open(os.path.join(HERE, "ab-results.json"), "w", encoding="utf-8").write(
        json.dumps(results, ensure_ascii=False, indent=1))


main()
