"""Decide whether a reproducer still fails on the engine under test, by asking a fixed upstream build.

A query that answers differently on the released SQLite and on trunk is a defect the release still
carries and upstream has since fixed. That replaces reading each bug thread and judging by hand.

Usage: python referee.py <dir-of-sql-files>   (defaults to the corpus directory)
Writes referee.json next to this script and prints the tally.
"""
import glob
import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
RELEASE = r"D:\sqlancer\coverage\sqlite\build\sqlite3_cov.exe"
# Built from the GitHub mirror of the canonical tree, which carries the same manifest as the Fossil
# check-in. Pinned here because trunk moves: a verdict is only reproducible against a fixed build.
TRUNK_CHECKIN = "75c1ee9de670c6366200df65b3a2c7c8888f709e985b5eaf81d57e562ab65b93"
TRUNK_WSL = "cd ~/sqlite-trunk/src && ./sqlite3 :memory:"


def normalise(output):
    # The release binary is a Windows build and ends its lines with CRLF; the trunk build runs
    # under WSL and ends them with LF. Comparing raw output made every case look different.
    return "\n".join(line.rstrip() for line in output.replace("\r\n", "\n").strip().splitlines())


def run_release(path):
    env = dict(os.environ, GCOV_PREFIX=os.path.join(HERE, "gcov-sink"))
    with open(path, "rb") as handle:
        proc = subprocess.run([RELEASE, ":memory:"], stdin=handle, capture_output=True, timeout=30,
                              env=env)
    return normalise(proc.stdout.decode("utf-8", "replace"))


def run_trunk(path):
    with open(path, "rb") as handle:
        proc = subprocess.run(["wsl.exe", "-e", "bash", "-lc", TRUNK_WSL], stdin=handle,
                              capture_output=True, timeout=60)
    return normalise(proc.stdout.decode("utf-8", "replace").replace("\x00", ""))


def main():
    directory = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "corpus")
    results = []
    for path in sorted(glob.glob(os.path.join(directory, "*.sql"))):
        case = os.path.basename(path)[:-4]
        try:
            release, trunk = run_release(path), run_trunk(path)
            differs = release != trunk
        except subprocess.TimeoutExpired:
            release, trunk, differs = "TIMEOUT", "TIMEOUT", False
        results.append({"id": case, "live_in_release": differs, "release": release[:400],
                        "trunk": trunk[:400]})
        print("%-12s %s" % (case, "LIVE" if differs else "same"))
    json.dump({"trunkCheckin": TRUNK_CHECKIN, "cases": results},
              open(os.path.join(HERE, "referee.json"), "w", encoding="utf-8"),
              ensure_ascii=False, indent=1)
    live = sum(1 for r in results if r["live_in_release"])
    print("\n%d of %d reproducers still fail on the release under test" % (live, len(results)))


main()
