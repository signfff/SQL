"""Rebuild the high-coverage corpus as the cases its reader can load.

The corpus was appended to for a month while the writer emitted a whole-database snapshot per case,
and the reader takes at most 80 setup statements and 12000 characters. Of 9273 cases in 8.5 GB, 874
could be loaded; the rest was read and discarded on every run. The writer has since been fixed, so
this is only needed once, for what the old one left behind.

Usage: python compact-high-coverage-corpus.py <input.sql> <output.sql>
"""
import re
import sys

MAX_SETUP_STATEMENTS = 80
MAX_SETUP_CHARS = 12000
MAX_SETUP_STATEMENT_CHARS = 2000

# The reader's own rules, kept in the same order so a case this keeps is a case it accepts.
UNSAFE_PRAGMA = re.compile(
    r'^PRAGMA\s+(WRITABLE_SCHEMA|PAGE_SIZE|MAX_PAGE_COUNT|JOURNAL_MODE|LOCKING_MODE'
    r'|INCREMENTAL_VACUUM|AUTO_VACUUM|SYNCHRONOUS|INTEGRITY_CHECK|QUICK_CHECK)\b')
TRANSACTION_OR_VACUUM = re.compile(r'^(VACUUM|ATTACH|DETACH|BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)\b')
INSERT_SELECT = re.compile(r'^INSERT\b.*\bSELECT\b')
SCHEMA_TABLES = ('SQLITE_MASTER', 'SQLITE_SCHEMA', 'SQLITE_TEMP_MASTER', 'SQLITE_TEMP_SCHEMA')


def normalise(statement):
    return re.sub(r'\s+', ' ', statement.strip()).upper()


def reject_reason(statements):
    if len(statements) > MAX_SETUP_STATEMENTS:
        return 'too-many-statements'
    total = 0
    for statement in statements:
        total += len(statement)
        if total > MAX_SETUP_CHARS:
            return 'too-many-chars'
        if len(statement) > MAX_SETUP_STATEMENT_CHARS:
            return 'statement-too-long'
        upper = normalise(statement)
        if any(name in upper for name in SCHEMA_TABLES):
            return 'sqlite-schema'
        if 'SQLITE_STAT1' in upper or 'SQLITE_STAT4' in upper:
            return 'sqlite-stat'
        if UNSAFE_PRAGMA.match(upper):
            return 'unsafe-pragma'
        if TRANSACTION_OR_VACUUM.match(upper):
            return 'transaction-or-vacuum'
        if 'WITH RECURSIVE' in upper or 'RANDOMBLOB(' in upper:
            return 'expensive-expression'
        if INSERT_SELECT.match(upper):
            return 'insert-select'
    return None


def main():
    source, destination = sys.argv[1], sys.argv[2]
    kept = dropped = 0
    reasons = {}
    seen_queries = set()
    duplicates = 0
    # A case is emitted as a keyframe: the delta encoding the writer uses refers to the case before
    # it, and dropping a case would leave the next one rebuilding tables that were never created.
    with open(source, encoding='utf-8', errors='replace') as src, \
            open(destination, 'w', encoding='utf-8', newline='\n') as out:
        case, setup, statements, current, in_case, in_setup = [], [], [], '', False, False
        queries = []
        for line in src:
            if line.startswith('-- EGRAPH_CORPUS_CASE_BEGIN'):
                case, setup, statements, current = [line], [], [], ''
                queries = []
                in_case, in_setup = True, False
                continue
            if not in_case:
                continue
            case.append(line)
            if line.startswith('-- EGRAPH_CORPUS_SETUP_BEGIN'):
                in_setup = True
                continue
            if line.startswith(('-- EGRAPH_CORPUS_SETUP_DELTA',)):
                # A delta case cannot stand on its own once its keyframe is dropped.
                in_setup = False
                in_case = False
                dropped += 1
                reasons['delta-without-keyframe'] = reasons.get('delta-without-keyframe', 0) + 1
                continue
            if line.startswith(('-- EGRAPH_BASE_QUERY', '-- EGRAPH_REPLAY_QUERY')):
                if current.strip():
                    statements.append(current.strip().rstrip(';'))
                    current = ''
                in_setup = False
                continue
            if line.startswith('-- EGRAPH_CORPUS_CASE_END'):
                in_case = False
                reason = reject_reason(statements)
                key = '\n'.join(sorted(queries))
                if reason is None and key and key in seen_queries:
                    reason = 'duplicate-queries'
                    duplicates += 1
                if reason is None:
                    # Rewritten as a keyframe, since the cases between were dropped.
                    case[0] = re.sub(r'setup=delta', 'setup=full', case[0])
                    out.writelines(case)
                    seen_queries.add(key)
                    kept += 1
                else:
                    dropped += 1
                    reasons[reason] = reasons.get(reason, 0) + 1
                continue
            if in_setup:
                current += line
                if line.rstrip().endswith(';'):
                    statements.append(current.strip().rstrip(';'))
                    current = ''
            elif line.strip() and not line.startswith('--'):
                queries.append(line.strip())

    print('kept %d cases, dropped %d' % (kept, dropped))
    for reason, count in sorted(reasons.items(), key=lambda item: -item[1]):
        print('  %-28s %d' % (reason, count))
    print('  (of the kept, %d duplicates were folded away)' % duplicates)


main()
