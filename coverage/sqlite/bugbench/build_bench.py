"""Merge the extracted bug records, apply the corpus-channel filter, write one corpus per case.

Usage: python build_bench.py
Reads extract/out-*.jsonl, writes core.json and corpus/<id>.sql, prints the tallies.
"""
import glob
import json
import os
import re
import subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
SQLITE = r"D:\sqlancer\coverage\sqlite\build\sqlite3_cov.exe"

# The tokens SQLite3EGraphInputCorpus.getEGraphQueryRejectReason refuses, with
# sqlite3.egraph.corpus.allowJoin set (so JOIN itself is allowed).
UNSUPPORTED = [" WITH ", " MATCH ", " GROUP BY ", " HAVING ", " WINDOW ", " OVER ", " UNION ",
               " INTERSECT ", " EXCEPT ", " VALUES ", " INDEXED BY ", " RETURNING ", " PRAGMA ",
               " CREATE ", " INSERT ", " UPDATE ", " DELETE ", " DROP ", " ALTER ", " REINDEX ",
               " ANALYZE ", " VACUUM ", " TRIGGER "]


def norm(sql):
    return re.sub(r"\s+", " ", sql.strip().rstrip(";")).upper()


def reject_reason(query):
    if not query.strip():
        return "no-query"
    n = norm(query)
    if not n.startswith("SELECT "):
        return "not-select"
    if " WHERE " not in " " + n + " ":
        return "no-where"
    for token in UNSUPPORTED:
        if token in " " + n + " ":
            return "unsupported-" + token.strip().lower().replace(" ", "-")
    if " FROM (" in n:
        return "derived-from"
    return None


def split_statements(sql):
    out, cur = [], ""
    for line in sql.splitlines():
        cur += line + "\n"
        if line.rstrip().endswith(";"):
            out.append(cur.strip())
            cur = ""
    if cur.strip():
        out.append(cur.strip())
    return out


def main():
    rows = []
    for path in sorted(glob.glob(os.path.join(HERE, "extract", "out-*.jsonl"))):
        for line in open(path, encoding="utf-8"):
            if line.strip():
                rows.append(json.loads(line))
    by_id = {r["id"]: r for r in rows}
    rows = list(by_id.values())

    env = dict(os.environ, GCOV_PREFIX=os.path.join(HERE, "gcov-sink"))
    os.makedirs(os.path.join(HERE, "corpus"), exist_ok=True)
    os.makedirs(os.path.join(HERE, "sql"), exist_ok=True)
    core = [r for r in rows if r["klass"] == "core-sql-correctness" and r["repro_sql"].strip()]
    for r in core:
        statements = split_statements(r["repro_sql"])
        query = r.get("bug_query", "").strip()
        if not query:
            selects = [s for s in statements if norm(s).startswith("SELECT")]
            query = selects[-1] if selects else ""
        r["bug_query"] = query
        r["setup"] = [s for s in statements if s.strip() != query.strip()]
        r["reject"] = reject_reason(query)

        path = os.path.join(HERE, "sql", r["id"] + ".sql")
        open(path, "w", encoding="utf-8").write(r["repro_sql"])
        with open(path, "rb") as handle:
            try:
                proc = subprocess.run([SQLITE, ":memory:"], stdin=handle, capture_output=True,
                                      timeout=20, env=env)
                r["run_err"] = proc.stderr.decode("utf-8", "replace")[:300]
                r["run_out"] = proc.stdout.decode("utf-8", "replace")[:600]
            except subprocess.TimeoutExpired:
                r["run_err"], r["run_out"] = "TIMEOUT", ""
        if r["reject"] is None:
            body = "\n".join(s if s.rstrip().endswith(";") else s + ";" for s in r["setup"])
            tail = query if query.rstrip().endswith(";") else query + ";"
            open(os.path.join(HERE, "corpus", r["id"] + ".sql"), "w", encoding="utf-8").write(
                body + "\n" + tail + "\n")

    json.dump(rows, open(os.path.join(HERE, "all.json"), "w", encoding="utf-8"), ensure_ascii=False)
    json.dump(core, open(os.path.join(HERE, "core.json"), "w", encoding="utf-8"), ensure_ascii=False)

    from collections import Counter
    print("records:", len(rows), Counter(r["klass"] for r in rows))
    print("core with repro:", len(core))
    print("corpus filter:", Counter(r["reject"] for r in core).most_common())
    print("repro runs with a SQL error:", sum(1 for r in core if "rror" in r.get("run_err", "")))


main()
