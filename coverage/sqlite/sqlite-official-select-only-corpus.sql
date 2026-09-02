-- SQLite official SELECT-only corpus for SQLancer EGRAPH
-- Source: D:\sqlancer\coverage\sqlite\sqlite-official-test-corpus.sql
-- Setup: stripped
-- Generated: 2026-08-28T21:35:42.6647533+08:00

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\affinity2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE c='0' ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\affinity2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE - x'ce' >= t0.c0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\affinity2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE +-+x'ce' >= t0.c0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\affinity2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE - 'ce' >= t0.c0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\affinity2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE +-+'ce' >= t0.c0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\affinity2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 1 FROM t0 WHERE 3175546974276630385 < c0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\aggorderby.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT group_concat(a ORDER BY a) FROM t1 WHERE b=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\aggorderby.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT group_concat(a ORDER BY c) FROM t1 WHERE b=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\alter.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t4 WHERE a = 'main';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\alter.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t4 WHERE a = 'aux';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\alter.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t5 WHERE b = 'main';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\alter.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM aux.t5 WHERE b = 'aux';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\alter2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM abc WHERE c = 10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\alter2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t2 WHERE b = X'ABCD';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\alter2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(b) FROM t2 WHERE b = X'ABCD';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\altercol.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a AS d FROM xxx WHERE d=0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\altercons.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\altercons.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a=3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE b>7223372036854775;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t4 WHERE x=1234;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE x>200 AND x<300;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE x>0 AND x<1100;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t2 WHERE x>1 AND x<2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t2 WHERE x>0 AND x<99;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t3 WHERE x>200 AND x<300;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t3 WHERE x>0 AND x<1100;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t1 WHERE b=3 AND a BETWEEN 30 AND hex(1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE b BETWEEN 30 AND 34;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE c BETWEEN 0 AND 100000;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE c BETWEEN 800000 AND 900000;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze9.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t1 WHERE b=3 AND a BETWEEN 30 AND 60;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze9.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(DISTINCT c) FROM t1 WHERE c<201;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze9.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(DISTINCT c) FROM t1 WHERE c<200;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze9.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a = 'abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze9.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a = 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze9.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a = 3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze9.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a = 5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze9.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x = 3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze9.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE x = 10000 AND y < 50;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyze9.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE z = 444;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyzeC.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *, '#' FROM t1 WHERE a BETWEEN 3 AND 8 ORDER BY c;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyzeC.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 0 FROM t44 WHERE a IN(1,2,3);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyzeE.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE t0.c1 BETWEEN '' AND (ABS(''));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyzeE.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT format('(%s)',a) FROM t1 WHERE t1.a > CAST(zeroblob(5) AS TEXT);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyzeE.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT format('(%s)',a) FROM t1 WHERE t1.a <= CAST(zeroblob(5) AS TEXT);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyzeF.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE b='xyz' AND b IS NOT NULL ORDER BY +a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyzeF.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x = substr('145', 2, 1) AND y = func(1, 2, 3);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyzeF.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x = error('error one') AND y = 4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyzeF.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x = zeroblob(2200000000) AND y = 4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyzeF.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x = dstr() AND y = 11;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\analyzeF.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x = test_zeroblob(1100000) AND y = 4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\atof1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE substr(a,',');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\attach.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE x>5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\auth.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE b=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\auth.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE b IS NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\auth.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a,c FROM t2 WHERE b IS NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\auth.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM pragma_table_list WHERE name='xyzzy';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\autoanalyze1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT idx, flgs FROM pragma_stats
   WHERE idx IS NOT NULL
   ORDER BY idx;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\autoanalyze1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT tbl, (flgs & 0x10)!=0 FROM pragma_stats WHERE tbl='t1' AND idx IS NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\autoanalyze1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT (flgs & 0x0100)!=0 FROM pragma_stats WHERE tbl='t1' AND idx IS NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\autoanalyze1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a=55;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\autoanalyze1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a IN (55,199,299);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\autoanalyze1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (b,c)=(45,45);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\autoanalyze1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE d=45;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\autoanalyze1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE d=45 AND a=45;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\autoanalyze1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE d=45 AND a IN (45,46);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\autoanalyze1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE b=45;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\autoinc.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT seq FROM sqlite_sequence WHERE name='t11';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\autoinc.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT seq FROM main.sqlite_sequence WHERE name='t6';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\autovacuum.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM av1 WHERE a = 'av1 a';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\autovacuum.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM av2 WHERE a = 'av2 a' AND b = 'av2 b' AND c = 'av2 c';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\autovacuum.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM av3 WHERE a = 'av3 a' AND b = 'av3 b';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\autovacuum.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM av4 WHERE a = 'av4 a' AND b = 'av4 b' AND c = 'av4 c';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\avtrans.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t2 WHERE y=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\avtrans.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE b<1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\avtrans.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE c<1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\backup4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x='one';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\basexx1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT num FROM bs WHERE base64(base64(b))!=b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\basexx1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT num FROM bs WHERE base85(base85(b))!=b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\basexx1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT len, base64(b) FROM rb WHERE len>200;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\basexx1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT len, base85(b) FROM rb WHERE len>200;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\basexx1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT length(base85(b))=1335 FROM rb WHERE len=1054;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE a='two';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE a IN ('one', 'four') ORDER BY +rowid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM x1 WHERE a=? AND b BETWEEN ? AND ? AND c IN (1, 2, 3, 4);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE c LIKE 'o%';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE c LIKE 'o%' OR b='y';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE c = 'three' OR c LIKE 'o%';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a, b) != ('a', 'b');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a, b) != (7, '8');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a!=7 OR b!='8';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE (a, b) != (45, 46);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE (a, b) != ('45', '46');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE (a, b) == (45, 46);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE (a, b) == ('45', '46');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, * FROM t4 WHERE x=245;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, * FROM t4 WHERE x='245';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, * FROM t4 WHERE x!=245;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, * FROM t4 WHERE x!='245';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, * FROM t4 WHERE rowid!=1 OR x!='245';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select * from vt1 WHERE a=0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select * from vt1 WHERE a=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select * from vt1 WHERE a=1 OR a=0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select * from vt1 WHERE a IN (2);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select * from vt1 WHERE a IN (0,1,2,3);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select * from vt1 WHERE a IN (0, NULL);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindex7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select * from vt1 WHERE a IN (NULL);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindexC.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM y1 WHERE a = COALESCE('8', a) LIMIT 3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindexC.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM y1 WHERE a = '2' LIMIT 3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindexC.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM x1 WHERE (a, b, c) = (?, ?, ?);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindexC.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM x1 WHERE (a, b, c) = ('X', 'Y', 'Z');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindexC.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM x1 WHERE a='x' AND b='y' AND c='z';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindexC.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM x1 
  WHERE a='x' COLLATE nocase AND b='y' COLLATE nocase AND c='z'COLLATE nocase;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindexC.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT d FROM x1 
    WHERE a='x' AND ((b='y' AND c='z') OR (b='Y' AND c='z' COLLATE nocase));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindexC.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT d FROM x1 
    WHERE a='x' COLLATE nocase 
    AND ((b='y' AND c='z') OR (b='Y' AND c='z' COLLATE nocase));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bestindexC.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM x1 WHERE b=c LIMIT 5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\bigrow.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a=='1';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\blob.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 where a = X'123456';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\blob.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 where a = X'CDEF12';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\blob.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 where a = X'CD12';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\busy.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\busy.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE y=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id, depth, root, tablename, idcolumn, parentcolumn FROM cx
   WHERE root=2048
     AND depth=1
   ORDER BY id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*), min(id), max(id) FROM c2 WHERE root=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM c2 WHERE root=10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM c2 WHERE root=12;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM c2 WHERE root IN (10,12) ORDER BY id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM c2 WHERE root IN (10,12) ORDER BY +id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM c2up WHERE root=20;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM cx
   WHERE root=20
     AND tablename='t2'
     AND idcolumn='y'
     AND parentcolumn='x';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT DISTINCT id FROM c2
   WHERE root IN (SELECT id FROM c2up
                   WHERE root=20 AND depth<=2)
   ORDER BY id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM closure
   WHERE root=1
     AND depth=3
     AND tablename='t1'
     AND idcolumn='x'
     AND parentcolumn='y'
  ORDER BY id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM c WHERE root=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id,depth FROM ct1 WHERE root=1 ORDER BY id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id,depth FROM ct1 WHERE root=1 AND depth<=4 ORDER BY id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id,depth FROM ct1 WHERE root=1 AND depth<=9223372036854775807
   ORDER BY id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id, depth FROM ct1 WHERE root=1 LIMIT 5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM cx
     WHERE root=20
       AND tablename='t3'
       AND idcolumn='y'
       AND parentcolumn='x';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM cx
     WHERE root=20
       AND tablename='t2'
       AND idcolumn='xyz'
       AND parentcolumn='x';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\closure01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM cx
     WHERE root=20
       AND tablename='t2'
       AND idcolumn='x'
       AND parentcolumn='pqr';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE c1 = 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM c5 WHERE a='abc' ORDER BY id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM c5 WHERE b='abc' ORDER BY id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM c5 WHERE c='abc' ORDER BY id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x COLLATE nocase BETWEEN 'a' AND 'c';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x BETWEEN 'a' COLLATE nocase AND 'c' COLLATE nocase;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 
  WHERE x COLLATE nocase BETWEEN 'a' COLLATE nocase AND 'c' COLLATE nocase;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE +x COLLATE nocase BETWEEN 'a' AND 'c';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE +x BETWEEN 'a' COLLATE nocase AND 'c' COLLATE nocase;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 
  WHERE +x COLLATE nocase BETWEEN 'a' COLLATE nocase AND 'c' COLLATE nocase;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE a > 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE a COLLATE binary > 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE b COLLATE binary > 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE c COLLATE binary > 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE b > 'aa' ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE a COLLATE nocase > 'aa'
     ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE b COLLATE nocase > 'aa'
     ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE c COLLATE nocase > 'aa'
     ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE b > 'aa' ORDER BY +b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE a COLLATE nocase > 'aa' ORDER BY +b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE b COLLATE nocase > 'aa' ORDER BY +b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE c COLLATE nocase > 'aa' ORDER BY +b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE c > 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE a COLLATE backwards > 'aa'
    ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE b COLLATE backwards > 'aa'
    ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE c COLLATE backwards > 'aa'
    ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE a < 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE b < 'aa' ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE b < 'aa' ORDER BY +b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE c < 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE a = 'aa';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE b = 'aa' ORDER BY oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE c = 'aa';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE a >= 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE b >= 'aa' ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE c >= 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE a <= 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE b <= 'aa' ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE c <= 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE a BETWEEN 'Aa' AND 'Bb' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE b BETWEEN 'Aa' AND 'Bb' ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE b BETWEEN 'Aa' AND 'Bb' ORDER BY +b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE c BETWEEN 'Aa' AND 'Bb' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE 
      CASE a WHEN 'aa' THEN 1 ELSE 0 END
        ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE 
      CASE b WHEN 'aa' THEN 1 ELSE 0 END
        ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE 
      CASE c WHEN 'aa' THEN 1 ELSE 0 END
        ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE a IN ('aa', 'bb') ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE b IN ('aa', 'bb') ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE c IN ('aa', 'bb') ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 
        WHERE a IN (SELECT a FROM collate2t1 WHERE a IN ('aa', 'bb'));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 
        WHERE b IN (SELECT a FROM collate2t1 WHERE a IN ('aa', 'bb'));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 
        WHERE c IN (SELECT a FROM collate2t1 WHERE a IN ('aa', 'bb'));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE NOT a > 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE NOT b > 'aa' ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE NOT c > 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE NOT a < 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE NOT b < 'aa' ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE NOT c < 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE NOT a = 'aa';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE NOT b = 'aa';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE NOT c = 'aa';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE NOT a >= 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE NOT b >= 'aa' ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE NOT c >= 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE NOT a <= 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE NOT b <= 'aa' ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE NOT c <= 'aa' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE a NOT BETWEEN 'Aa' AND 'Bb' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE b NOT BETWEEN 'Aa' AND 'Bb' ORDER BY 1, oid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE c NOT BETWEEN 'Aa' AND 'Bb' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE NOT CASE a WHEN 'aa' THEN 1 ELSE 0 END;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE NOT CASE b WHEN 'aa' THEN 1 ELSE 0 END;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE NOT CASE c WHEN 'aa' THEN 1 ELSE 0 END;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 WHERE NOT a IN ('aa', 'bb');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 WHERE NOT b IN ('aa', 'bb');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 WHERE NOT c IN ('aa', 'bb');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM collate2t1 
        WHERE NOT a IN (SELECT a FROM collate2t1 WHERE a IN ('aa', 'bb'));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM collate2t1 
        WHERE NOT b IN (SELECT a FROM collate2t1 WHERE a IN ('aa', 'bb'));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM collate2t1 
        WHERE NOT c IN (SELECT a FROM collate2t1 WHERE a IN ('aa', 'bb'));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM collate3t1 WHERE c1 = 'xxx';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM v2 WHERE c='c';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM abc16 WHERE a < 'abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE a<'ccc' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE a<'ccc' COLLATE binary ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE +a<'ccc' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a AS x FROM t1 WHERE x<'ccc' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a AS x FROM t1 WHERE +x<'ccc' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a AS x FROM t2 WHERE x='abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a AS x FROM t2 WHERE x='abc' COLLATE nocase;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a AS x FROM t2 WHERE (x COLLATE nocase)='abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a COLLATE nocase AS x FROM t2 WHERE x='abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a COLLATE nocase AS x FROM t2 WHERE (x COLLATE binary)='abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a COLLATE nocase AS x FROM t2 WHERE x='abc' COLLATE binary;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE (a COLLATE nocase)='abc' COLLATE binary;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collate8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a COLLATE nocase AS x FROM t2 WHERE 'abc'=x COLLATE binary;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collateA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b='abcde     ';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collateA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE c='abcde     ';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collateA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b='xyzzy';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collateA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE c='xyzzy';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collateA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE c='xyzzy ';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collateA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE c='xyzz';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collateA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE c='xyzzyy   ';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collateA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE c='xyzz   ';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collateA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE c='abcd   ';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collateA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE c='abcd';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collateA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE c='abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collateA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE c='abcdef    ';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collateA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE c='';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\collateA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE c=' ';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\conflict.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a=1000;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\conflict.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a=1001;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\corrupt.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE x>'abcdef';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\corrupt.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE oid = 10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\corrupt.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x = 'abcde';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\corruptC.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE x>13;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\corruptC.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t2 WHERE x<13;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\corruptG.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t1 WHERE a>'abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\corruptG.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE a='abc' and b='xyz123456789XYZ';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\corruptI.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a = 10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\corruptI.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM r WHERE x >= 10.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\corruptI.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM r WHERE x >= 10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\corruptL.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT sum(s+length(b)) FROM t1 WHERE a IN (110,10,150) AND q IS NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\corruptL.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a<='2019-05-09' ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\corruptL.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT CAST((SELECT b FROM t1 WHERE 16=c) AS int) FROM t1 WHERE 16=c;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\count.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t8 WHERE (a, b) IN (
      SELECT count(t8.b), count(*) FROM t7 AS ra0 ORDER BY count(*)
  ) AND t8.b=0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\countofview.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM v1 WHERE x<>1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\crash8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM main.ab WHERE a = 0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\crash8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM aux.ab WHERE a = 0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\cse.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 0 IN (SELECT a) FROM t1 WHERE a = 'hello' OR (SELECT a LIMIT 0);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\cse.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 0 IN(SELECT v1) FROM v0 WHERE v1 = 2 OR(SELECT v1 LIMIT 0);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\csv01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE c1=10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\csv01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE c1='10';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\csv01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE "soft opinion"=12;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\csv01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE c1='b';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\csv01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x1='6';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\csv01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE a=9;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\csv01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE b=10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\csv01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE c=11;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\csv01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE d=12;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\csv01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE d='12';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\csv01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE a='9';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\csv01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t3 WHERE b=6 OR c=7 OR d=12 ORDER BY +a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\csv01.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t3 WHERE +b=6 OR c=7 OR d=12 ORDER BY +a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\date2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t3
   WHERE typeof(b)='real'
     AND datetime(b) BETWEEN '2017-07-04' AND '2017-07-08'
  ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\dbdata.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pgno, cell, field, quote(value) FROM sqlite_dbdata WHERE pgno=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\dbdata.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT value FROM sqlite_dbdata WHERE pgno=2 AND cell=2 AND field=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\dbdata.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM sqlite_dbptr WHERE pgno=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\dbdata.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM sqlite_dbptr WHERE pgno=3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\dbdata.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(value) FROM sqlite_dbdata WHERE pgno=2 AND cell=0 AND field=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\dbpage.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pgno, quote(substr(data,1,5)) FROM sqlite_dbpage WHERE pgno=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\dbpage.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pgno, quote(substr(data,1,5)) FROM sqlite_dbpage WHERE pgno=4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\dbpage.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pgno, quote(substr(data,1,5)) FROM sqlite_dbpage WHERE pgno=5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\dbpage.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pgno, quote(substr(data,1,5)) FROM sqlite_dbpage WHERE pgno=0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\dbpage.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pgno FROM sqlite_dbpage WHERE pgno=555;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\dbpage.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pgno FROM sqlite_dbpage WHERE pgno=4294967297;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\dbstatus2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\decimal.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT decimal_add(val,'0.5') FROM t3 WHERE seq>5 ORDER BY seq;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\delete.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a='1' AND b='2';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\delete.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT f1 FROM table1 WHERE f1<10 ORDER BY f1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\delete.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT f1 FROM table2 WHERE f1<10 ORDER BY f1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\delete2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM q WHERE id='id.1';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\delete4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a>3 AND a<7;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b>3 AND b<7;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a>=3 AND a<7;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a>3 AND a<=7;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a>=3 AND a<=7;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b>=3 AND b<=7;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT d FROM t2 WHERE a>=2 ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT d FROM t2 WHERE a>2 ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT d FROM t2 WHERE a=2 AND b>'two';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT d FROM t2 WHERE a=2 AND b>='two';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT d FROM t2 WHERE a=2 AND b<'two';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT d FROM t2 WHERE a=2 AND b<='two';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT i FROM t1 WHERE a<=x'7979';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT i FROM t1 WHERE a>-99;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT i FROM t1 WHERE a=1 AND b>0 AND b<'zzz';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT i FROM t1 WHERE b>0 AND b<'zzz';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT i FROM t1 WHERE a=1 AND b>-9999 AND b<x'ffffffff';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT i FROM t1 WHERE b>-9999 AND b<x'ffffffff';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\descidx3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT i FROM t1 WHERE a IN (1,2) AND b>0 AND b<'zzz';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\distinct.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT DISTINCT pid FROM person where pid = 10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\distinct2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT DISTINCT a,b,c FROM t4 WHERE a=0 AND b=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\distinct2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT DISTINCT a,b,c,d FROM t4 WHERE a=0 AND b=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\distinct2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT DISTINCT d,a,b,c FROM t4 WHERE a=0 AND b=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\distinct2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT DISTINCT a,b,c,d,e FROM t4 WHERE a=0 AND b=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\distinct2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT DISTINCT a,b,c,d,e,f FROM t4 WHERE a=0 AND b=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\distinct2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT DISTINCT a, b, c FROM t8 WHERE b=3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\distinct2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT DISTINCT * FROM t0 WHERE NULL IS t0.c0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\distinct2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT DISTINCT * FROM t0 WHERE NULL IS c0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_blobclose.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM x1 WHERE a IN (1, -10);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_blobclose.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM x1 WHERE a = 15;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_blobclose.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM x1 WHERE a=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_blobclose.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM x1 WHERE a=-10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_blobwrite.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE i=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_blobwrite.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE i=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_fkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM track WHERE NOT (
        trackartist IS NULL OR 
        EXISTS(SELECT 1 FROM artist WHERE artistid=trackartist)
      );
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_fkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM chi WHERE c IS NOT NULL AND c NOT IN (SELECT p FROM par);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_fkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM track WHERE trackartist = 5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_fkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM track WHERE trackartist = 7;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_fkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM track WHERE trackartist = 6;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_fkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE a = 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_select.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT k FROM x1 WHERE x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_select.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT k FROM x1 WHERE y;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_select.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT k FROM x1 WHERE z;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_select.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT k FROM x1 WHERE '1'||z;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_select.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT k FROM x1 WHERE x IS NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\e_select.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT k FROM x1 WHERE z - 78.43;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\enc2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a = 'one';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\enc2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a = 'four';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\enc2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a IN ('one', 'two');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\enc3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT CAST(a AS text) FROM t2 WHERE CAST(a AS text) LIKE 'abc%';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\enc3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t2
       WHERE CAST(a AS text) LIKE CAST(x'610062002500' AS text);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\existsexpr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM x2 WHERE EXISTS (SELECT 1 FROM x1 WHERE a=x);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\existsexpr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM x2 WHERE EXISTS (SELECT 1 FROM x1 WHERE a=x);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\existsexpr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE EXISTS (SELECT 1 FROM t2 WHERE c=a);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\existsexpr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE EXISTS (SELECT 1 FROM t0 LIMIT 0);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\existsexpr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 1 FROM t2 WHERE EXISTS ( SELECT 1 FROM t3 WHERE yy==t2.ii );
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\existsexpr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT EXISTS( SELECT 1 FROM t1 ) aaa FROM x1 WHERE aaa AND aaa;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\existsexpr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2
    WHERE EXISTS (SELECT 1 FROM t3 WHERE t3.amount > t2.data);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\existsexpr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2
    WHERE EXISTS (SELECT 1 FROM t3 WHERE t3.amount > t2.data)
  LIMIT 2 OFFSET 3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\existsexpr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE EXISTS (
      SELECT 1 FROM t2
      WHERE EXISTS (
        SELECT 1 FROM t3 WHERE t3.p=t2.x AND t3.q=t1.b
      )
  );
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\existsexpr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t b
    WHERE (b.parent IS NULL OR b.parent = 99)
    AND 5 <= +b.n;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\existsexpr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE EXISTS (
    SELECT 1 FROM t2 WHERE (c=a OR d=a) AND (d+1)>0
  );
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\existsexpr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE EXISTS (SELECT 1 FROM t2 WHERE c COLLATE f = a);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\existsexpr2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM x1 WHERE EXISTS (SELECT 1 FROM x2 WHERE a!=123);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\existsexpr2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM x1 WHERE EXISTS (
    SELECT 1 FROM x3 WHERE u IN (1, 2, 3, 4) AND v=b
  );
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\existsexpr2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a,b,c FROM t1 WHERE b=2 ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\existsexpr2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x, y FROM t2 WHERE EXISTS (
    SELECT 1 FROM t1 WHERE b=x
  );
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\existsfault.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM x2 WHERE EXISTS (SELECT 1 FROM x1 WHERE a=x) AND y!=11;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\expr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1
   WHERE (x OR (8==9)) != (CASE WHEN x THEN 1 ELSE 0 END);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\expr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1
   WHERE (x OR (8==9)) != (NOT NOT x);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\expr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT sum(NOT x) FROM t1
   WHERE x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\expr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT sum(CASE WHEN x THEN 0 ELSE 1 END) FROM t1
   WHERE x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\expr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM test1 WHERE %s ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\expr2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE (
      ( (0 IS NOT FALSE) OR NOT (0 IS FALSE OR (t0.c0 = 1)) ) IS 0
  );
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aa.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT content FROM t1 WHERE rowid = 0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aa.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT content FROM t1 WHERE rowid = -1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3ab.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT english, spanish, german FROM t1 WHERE rowid=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3ai.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT content FROM t1 WHERE rowid = 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3ai.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT content FROM t1 WHERE rowid = 2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3ai.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT content FROM t1 WHERE rowid = 3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3ai.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT content FROM t1 WHERE rowid = 4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3ai.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT content FROM t1 WHERE rowid = 5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms WHERE col = '*';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms_v WHERE term='braid';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms_v WHERE +term='braid';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms_v WHERE term='breakfast';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms_v WHERE +term='breakfast';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms_v WHERE term='cba';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms_v WHERE +term='cba';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms_v WHERE term='abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms_v WHERE +term='abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms WHERE term=NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms_v WHERE term>'brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms_v WHERE +term>'brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms_v WHERE term>='brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms_v WHERE +term>='brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms_v WHERE term>='abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms_v WHERE +term>='abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms_v WHERE term>='brainstorms';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms_v WHERE term>'brainstorms';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms_v WHERE term>'cba';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms_v WHERE term<'brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms_v WHERE +term<'brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms_v WHERE term<='brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms_v WHERE +term<='brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms_v 
  WHERE rec('cnt', term) AND term BETWEEN 'brags' AND 'brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms_v 
  WHERE rec('cnt', term) AND +term BETWEEN 'brags' AND 'brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms_v 
  WHERE rec('cnt', term) AND term > 'brags' AND term < 'brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms_v 
  WHERE rec('cnt', term) AND +term > 'brags' AND +term < 'brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms3 WHERE term = 'abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms_v WHERE rec('cnt', term) AND term='braid';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms_v WHERE rec('cnt', term) AND +term='braid';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms_v WHERE rec('cnt', term) AND term='breakfast';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms_v WHERE rec('cnt', term) AND +term='breakfast';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms WHERE rec('cnt', term) AND term>'brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms WHERE rec('cnt', term) AND +term>'brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms WHERE rec('cnt', term) AND term<'brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms WHERE rec('cnt', term) AND +term<'brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms 
    WHERE rec('cnt', term) AND term BETWEEN 'brags' AND 'brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences FROM terms 
    WHERE rec('cnt', term) AND +term BETWEEN 'brags' AND 'brain';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences, languageid FROM terms WHERE col = '*';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms WHERE languageid='';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms WHERE languageid=-1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms WHERE languageid=9223372036854775807;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms WHERE languageid=-9223372036854775808;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM terms WHERE languageid=NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences, languageid 
  FROM terms WHERE col = '*' AND languageid=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, col, documents, occurrences, languageid 
  FROM terms WHERE languageid=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, col, documents, occurrences, languageid 
  FROM terms WHERE languageid=1 AND term='zero';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, col, documents, occurrences, languageid 
  FROM terms WHERE languageid='1' AND term='two';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, col, documents, occurrences, languageid 
  FROM terms WHERE languageid='+1' AND term>'four';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, documents, occurrences, languageid 
  FROM terms WHERE col = '*' AND languageid=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, col, documents, occurrences, languageid 
  FROM terms WHERE languageid=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, col, documents, occurrences, languageid 
  FROM terms WHERE languageid=2 AND term='five';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, col, documents, occurrences, languageid 
  FROM terms WHERE term='five' AND languageid=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, col, documents, occurrences, languageid 
  FROM terms WHERE term>='seven' AND languageid=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term, col, documents, occurrences, languageid 
  FROM terms WHERE term>='e' AND term<'seven' AND languageid=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term FROM t2 WHERE term=X'625f323334353637383930313233343536373839';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term FROM t2 WHERE term<X'625f003334353637383930313233343536373839';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT term FROM t2 WHERE term=X'625f003334353637383930313233343536373839';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3aux2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE term >= 5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3b.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE rowid = 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3b.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t4 WHERE rowid <> docid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3b.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t4 WHERE rowid = 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3b.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT docid, * FROM t4 WHERE rowid = 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3b.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT docid, * FROM t4 WHERE docid = 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3b.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t4 WHERE docid = 10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3b.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t4 WHERE docid = 12;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3b.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t4 WHERE rowid = 14;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3b.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t4 WHERE rowid = 12;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3b.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t4 WHERE docid = 14;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3comp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b FROM t1 WHERE docid = 2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3corrupt4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(block) FROM ft_segments WHERE blockid=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3corrupt4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, quote(matchinfo(t1,'pcxybspcxybs')) FROM t1 WHERE t1 MATCH'ATE"0"OR"2:P"""';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3defer.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1_segments WHERE length(block)>10000;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3e.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT docid FROM t1 WHERE c LIKE 'That%' ORDER BY docid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3e.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT docid FROM t1 WHERE docid in (1, 2, 10);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3e.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE rowid in (1, 2, 10);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3matchinfo.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT typeof(matchinfo(t10)), length(matchinfo(t10)) FROM t10 WHERE docid=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3misc.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(value) from t4_stat where id=0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3tok_err.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT token FROM t1 WHERE input = 'A galaxy far, far away';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3tok1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT token FROM t3 WHERE input = '1x2x3x';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3tok1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT token FROM t1 WHERE input = '1x2x3x';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3tok1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT token FROM t3 WHERE input = '1''2x3x';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3tok1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT token FROM t3 WHERE input = '';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3tok1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT token FROM t3 WHERE input = NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3tok1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE input = 123;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3tok1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE input = 'a b c' AND token = 'b';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3tok1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE token = 'b' AND input = 'a b c';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts3tok1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE input < 'b' AND input = 'a b c';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4content.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, c FROM ft1 WHERE rowid=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4content.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT path, data FROM vt WHERE rowid = 2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4docid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT docid FROM t1 WHERE docid = 5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4docid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT docid FROM t1 WHERE docid = '5';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4docid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT docid FROM t1 WHERE docid = +5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4docid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT docid FROM t1 WHERE docid = +'5';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4docid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT docid FROM t1 WHERE docid < 5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4docid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT docid FROM t1 WHERE docid < '5';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4docid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE rowid = 5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4docid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE rowid = '5';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4docid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE rowid = +5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4docid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE rowid = +'5';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4docid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE rowid < 5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4docid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE rowid < '5';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4growth.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT sum(length(block)) FROM x1_segments WHERE blockid IN (224,225,226);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4growth.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM x2_segdir WHERE level=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4growth.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM x2_segdir WHERE level=3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4growth.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT end_block FROM x2_segdir WHERE level=3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4growth.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT level, idx, second(end_block) FROM x3_segdir WHERE level=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4growth2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM x1_segdir WHERE level=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4merge.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(value) FROM t4_stat WHERE rowid=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4merge.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(value) from t1_stat WHERE rowid=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4noti.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a,b,c FROM t1 WHERE docid=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4noti.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a,b,c FROM t1 WHERE docid=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fts4unicode.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT token FROM ft1 WHERE input = 'berlin@street123sydney.road';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\func.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT match(a,b) FROM t1 WHERE 0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\func4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE x>0 ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\func5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE c=instr('abcdefg',b) OR a='abcdefg' ORDER BY +x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\func5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE a='abcdefg' OR c=instr('abcdefg',b) ORDER BY +x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\func5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x, y FROM t2 WHERE x+5=5+x ORDER BY +x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\func5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x, y FROM t2
   WHERE x+counter1('hello')=counter1('hello')+x
   ORDER BY +x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\func6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a IN (SELECT sqlite_offset(b) FROM t2);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fuzzer2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM x1_rules WHERE cTo!=cFrom;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\fuzzer2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT cTo FROM x1_rules WHERE cFrom='xx' 
  ORDER BY cost asc, rowid asc LIMIT 9;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\gencol1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE w=30;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\gencol1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE x='real';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\gencol1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE y LIKE '%tal%' OR x='real' ORDER BY b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\gencol1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE w=10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\gencol1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE x='null' AND w BETWEEN 20 AND 40;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\gencol1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE b=123;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\gencol1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t4 WHERE b=1234;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\gencol1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE (1 BETWEEN CAST(t0.c0 AS TEXT) AND t0.c0);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\gencol1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b='DEF' AND a='def';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\icu.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM t1 WHERE x LIKE 'abc%%' ESCAPE '%';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\icu.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM t1 WHERE x LIKE 'abc__' ESCAPE '_';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\icu.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x LIKE CAST(x'C0A5' AS TEXT);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\icu.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x LIKE CAST(x'C19F' AS TEXT) || 'bcdefg';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\imposter1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM xt1 WHERE a IS NOT NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM a WHERE id NOT IN (SELECT id FROM b);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM c1 WHERE a IN (SELECT a FROM c1) ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t4 WHERE a IN (3,null,8) ORDER BY +b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t4 WHERE a NOT IN (3,null,8);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM x1 
  WHERE a IN (SELECT a FROM x1 WHERE (a%2)==0) 
  ORDER BY a DESC, b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM x1 
  WHERE a IN (SELECT a FROM x1 WHERE (a%7)==0) 
  ORDER BY a DESC, b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE '1' IN (t0.c0);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 1 FROM t0 WHERE c0 IN ('2.0625');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x IN (SELECT a FROM t2);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x IN ((SELECT a FROM t2));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x IN (((SELECT a FROM t2)));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE x IN ((((((SELECT a FROM t2))))));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b BETWEEN 10 AND 50 ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b NOT BETWEEN 10 AND 50 ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b BETWEEN a AND a*5 ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b NOT BETWEEN a AND a*5 ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b BETWEEN a AND a*5 OR b=512 ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b IN (8,12,16,24,32) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b NOT IN (8,12,16,24,32) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b IN (8,12,16,24,32) OR b=512 ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b NOT IN (8,12,16,24,32) OR b=512 ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b IN (b+8,64);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b IN (max(5,10,b),20);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b IN (8*2,64/2) ORDER BY b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b IN (max(5,10),20);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE min(0,b IN (a,30));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE c IN (10,20);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1
    WHERE b IN (SELECT b FROM t1 WHERE a<5)
    ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1
    WHERE b IN (SELECT b FROM t1 WHERE a<5) OR b==512
    ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM ta WHERE a<10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM tb WHERE a<10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM ta WHERE b IN (SELECT a FROM tb);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM ta WHERE b NOT IN (SELECT a FROM tb);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM ta WHERE b IN (SELECT b FROM tb);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM ta WHERE b NOT IN (SELECT b FROM tb);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM ta WHERE a IN (SELECT a FROM tb);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM ta WHERE a NOT IN (SELECT a FROM tb);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM ta WHERE a IN (SELECT b FROM tb);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM ta WHERE a NOT IN (SELECT b FROM tb);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE a IN ();
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE a IN (5);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE a NOT IN () ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE a IN (5) AND b IN ();
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE a IN (5) AND b NOT IN ();
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM ta WHERE a IN ();
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM ta WHERE a NOT IN ();
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a IN ('hello','there');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a IN ("hello",'there');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a IN t4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a NOT IN t4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t6 WHERE b IN (2);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t6 WHERE b IN ('2');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t6 WHERE +b IN ('2');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t6 WHERE a IN ('2');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t6 WHERE a IN (2);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t6 WHERE +a IN ('2');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a NOT IN tb;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid 
    FROM t1 
    WHERE rowid IN (SELECT rowid FROM t1 WHERE rowid IN (1, 2));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select rowid from t1 where rowid IN (-1,2,4);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE rowid IN 
       (select rowid from t1 where rowid IN (-1,2,4));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE x=10 AND y IN (10);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE x IN (10) AND y=10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE x IN (10) AND y IN (10);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE x=1 AND y NOT IN (10);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE x  NOT IN (10) AND y=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE x NOT IN (10) AND y NOT IN (10);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE x IN (10,11);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE x IN (10);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE x NOT IN (10,11,99999);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE x NOT IN (10);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t4a WHERE a=b ORDER BY c;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t4a WHERE b=a ORDER BY c;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t4a WHERE (a||'')=b ORDER BY c;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t4a WHERE (a||'')=(b||'') ORDER BY c;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t4a WHERE a IN (b) ORDER BY c;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t4a WHERE (a||'') IN (b) ORDER BY c;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t4b WHERE a=b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t4b WHERE b=a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t4b WHERE +a=b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t4b WHERE a=+b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t4b WHERE +b=a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t4b WHERE b=+a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t4b WHERE a IN (b);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t4b WHERE b IN (a);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t4b WHERE +b IN (a);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 1 FROM t5 WHERE 'fuzz' IN (d);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 2 FROM t5 WHERE 'FUZZ' IN (d);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 3 FROM t5 WHERE d IN ('fuzz');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 4 FROM t5 WHERE d IN ('FUZZ');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT d FROM t1 WHERE 0=a AND b IN (-17,-4,-3,1,5,25,7798);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1
   WHERE b IN (345, (SELECT 1 FROM t1 
                      WHERE b IN (coalesce(1,random()))
                        AND c GLOB 'abc*xyz'))
     AND c BETWEEN 'abc' AND 'xyz';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1
   WHERE (b = 1137 AND c IN (97, 98))
      OR (b = 1119 AND c IN (1115, 1023));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1
   WHERE a=1
     AND b IN (2,3)
     AND c BETWEEN 4 AND 5
   ORDER BY +id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a IN ('aaa', 'bbb', 'ccc');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a IN ('aaa', 'bbb', 'ccc');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE rowid IN (1, 3);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE rowid IN ();
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE a IN ('ddd');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t2 WHERE a IN (0, 2);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t2 WHERE a IN (2, 0);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t2 WHERE a IN (2, -1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t2 WHERE a IN (NULL, 3);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t2 WHERE a IN (1.0, 2.1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t2 WHERE a IN ('1', '2');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t2 WHERE a IN ('', '0.0.0', '2');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE id IN () AND x IN (SELECT x FROM t2 WHERE id=1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE x IN ();
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE x = 10 AND y IN ();
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE x IN () AND y = 10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE x IN () OR x = 10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE y IN ();
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x IN() AS a FROM t3 WHERE a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x IN() AS a FROM t3 WHERE NOT a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE oid IN ();
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE x IN (1, 2) OR y IN ();
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE x IN (1, 2) AND y IN ();
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE a COLLATE BINARY IN (SELECT DISTINCT a FROM t1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t3 WHERE b IN (SELECT DISTINCT a FROM t3 LIMIT 5);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t3 WHERE b IN (SELECT          a FROM t3 LIMIT 5);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM x2 WHERE b IN (SELECT DISTINCT a FROM x1 LIMIT 2);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM y1 WHERE b NOT IN (SELECT a FROM y2);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM y1 WHERE b IN (SELECT a FROM y2);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM n1 WHERE a IN (1, 2, 3);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM n1 WHERE a IN (SELECT +a FROM n1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t9 WHERE a IN (44, 45, 44, 45);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT lower('1e500') FROM t0 WHERE rowid NOT IN (0, 0, lower('1e500'));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT lower('1e500') FROM t0 WHERE rowid != lower('1e500');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE (a, b) IN ( VALUES('abc', 'def'), ('ghi', 'JKL') );
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT d FROM t2 WHERE a IN t1x AND b IN t1y AND c IN t1z ORDER BY c;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT d FROM t2 WHERE a IN t1y AND b IN t1x AND c IN t1z ORDER BY d;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT d FROM t2 WHERE a IN t3x AND b IN t3y AND c IN t3z ORDER BY d;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT d FROM t2 WHERE a IN t1x AND b IN t1y AND c IN t1z ORDER BY d;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT d FROM t1
  WHERE a=100
    AND b IN (200,201,202,204)
    AND c IN (300,302,301,305)
  ORDER BY +d;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(a), quote(b), '|' FROM t1 WHERE b in (SELECT a FROM t1) AND a=0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a IN (1,2,3) ORDER BY b ASC NULLS LAST;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM v74
    WHERE (vout IN (SELECT t0.c1 FROM t0));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM v74
    WHERE NOT (vout IN (SELECT t0.c0 FROM t0));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c1 FROM t0 WHERE (((c1),(c1)) IN (
        SELECT c2, min(c2) FROM t2)
  );
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a IN (SELECT count(*) FROM t2);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a, b) IN (SELECT count(*), 'three' FROM t2);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\in7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a, b) IN (SELECT min(x), 'one' FROM t2);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\incrblob.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT v FROM blobs WHERE rowid = 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\incrblob.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM blobs WHERE rowid = 4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\incrblob.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a = 314159;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT cnt FROM test1 WHERE power=4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT cnt FROM test1 WHERE power=1024;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT power FROM test1 WHERE cnt=6;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT f1 FROM test1 WHERE f2=65536;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a=1 ORDER BY b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a=2 ORDER BY b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t3 WHERE b==10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t4 WHERE a==0 ORDER BY b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t4 WHERE a<0.5 ORDER BY b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t4 WHERE a>-0.5 ORDER BY b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t6 WHERE a='';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t6 WHERE b='';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t6 WHERE a>'';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t6 WHERE a>='';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t6 WHERE a>123;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t6 WHERE a>=123;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t6 WHERE a<'abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t6 WHERE a<='abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t6 WHERE a<='';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t6 WHERE a<'';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE typeof(a) IN ('integer','real') ORDER BY b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE b='ab005xy' COLLATE nocase;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t2 WHERE a=15;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t2 WHERE a=15 AND a<100;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t2 WHERE a=515 AND a>200;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t3 WHERE a=999;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t3 WHERE t3.b BETWEEN 5 AND 10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT e FROM t10 WHERE a=1 AND b=2 AND c=3 ORDER BY d;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT e FROM t10 WHERE c=3 AND 2=b AND a=1 ORDER BY d DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT e FROM t10 WHERE a=1 AND b=2 ORDER BY d DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 'one', * FROM t2 WHERE x NOT IN (SELECT a FROM t1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 'two', * FROM t2 WHERE x NOT IN (SELECT a FROM t1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t2 WHERE x IN (SELECT a FROM t1) ORDER BY +x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE c0 OR 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE t0.c0 IS NOT 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE CASE c0 WHEN 0 THEN 0 ELSE 1 END;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 1 FROM t0 WHERE (t0.c0 IS FALSE) IS FALSE;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 1 FROM t0 WHERE (t0.c0 IS FALSE) BETWEEN FALSE AND TRUE;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 1 FROM t0 WHERE TRUE BETWEEN (t0.c0 IS FALSE) AND TRUE;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 1 FROM t0 WHERE FALSE BETWEEN FALSE AND (t0.c0 IS FALSE);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 1 FROM t0 WHERE (c0 IS FALSE) IN (FALSE);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 2 FROM t0 WHERE c0 >= c1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 3 FROM t0 WHERE c1 <= c0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT COUNT(*) FROM t0 WHERE t0.c0 GLOB t0.c0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a IS NOT NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index6.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t2 WHERE a IS NOT NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t1 WHERE a NOT LIKE 'abc%' AND a=7 ORDER BY +b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM v4 WHERE d='xyz' AND c='def';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t6 WHERE y IS TRUE ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\index8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE c=4 ORDER BY a, b LIMIT 2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a='abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, typeof(a), b, c FROM t1 WHERE a=5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *, typeof(a) FROM x1 WHERE a=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *, typeof(a) FROM x1 WHERE a=2.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *, typeof(a) FROM x1 WHERE a='2';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *, typeof(a) FROM x1 WHERE a='2.0';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *, typeof(a) FROM x2 WHERE a=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *, typeof(a) FROM x2 WHERE a=2.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *, typeof(a) FROM x2 WHERE a='2';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *, typeof(a) FROM x2 WHERE a='2.0';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *, typeof(a) FROM x3 WHERE a=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *, typeof(a) FROM x3 WHERE a=2.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *, typeof(a) FROM x3 WHERE a='2';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *, typeof(a) FROM x3 WHERE a='2.0';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b, c, typeof(a) FROM x1 WHERE a=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b, c, typeof(a) FROM x1 WHERE a=2.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b, c, typeof(a) FROM x1 WHERE a='2';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b, c, typeof(a) FROM x1 WHERE a='2.0';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b, c, typeof(a) FROM x2 WHERE a=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b, c, typeof(a) FROM x2 WHERE a=2.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b, c, typeof(a) FROM x2 WHERE a='2';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b, c, typeof(a) FROM x2 WHERE a='2.0';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b, c, typeof(a) FROM x3 WHERE a=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b, c, typeof(a) FROM x3 WHERE a=2.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b, c, typeof(a) FROM x3 WHERE a='2';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b, c, typeof(a) FROM x3 WHERE a='2.0';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT sum(a), b FROM t2 WHERE b='two';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE b=4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b, c, '|' FROM t1 WHERE substr(a,1,12)=='and_the_Word' ORDER BY b, c;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b, c, '|' FROM t1 WHERE 'and_the_Word'==substr(a,1,12) ORDER BY b, c;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM t1 WHERE b=1 AND substr(a,2,3)='nd_' ORDER BY c;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE substr(a,b,3)<='and' ORDER BY +rowid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE +substr(a,b,3)<='and' ORDER BY +rowid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE substr(a,b,3) IN ('and','l_t','xyz')
   ORDER BY +rowid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, b, c FROM t1
      WHERE substr(a,27,3)=='ord' AND d>=29;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM t1 WHERE substr(a,b,3)<='and' ORDER BY +id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM t1 WHERE +substr(a,b,3)<='and' ORDER BY +id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM t1 WHERE substr(a,b,3) IN ('and','l_t','xyz')
   ORDER BY +id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id, b, c FROM t1
      WHERE substr(a,27,3)=='ord' AND d>=29;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t3 WHERE CAST(a AS text)<='10' ORDER BY +a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT i FROM t4 WHERE e=5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *, '|' FROM t7 WHERE +b=+c ORDER BY +a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t8 WHERE substr(b,2,4)='ARTH' COLLATE nocase;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT '1:', typeof(a), a FROM t1 WHERE a<10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT '2:', typeof(a), a FROM t1 WHERE a+0<10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT '3:', typeof(a), a FROM t1 WHERE a<10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT '4:', typeof(a), a FROM t1 WHERE a+0<10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1300 WHERE substr(b,4)='ess' COLLATE nocase ORDER BY +a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE lower(a)='1234' ORDER BY +b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE lower(a)='01234' ORDER BY +b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE ((NULL IS FALSE) IS FALSE);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT +x FROM t1 WHERE x=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT sum(b->>'one') FROM t1 WHERE a=10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT sum(b->>'two') FROM t1 WHERE a=10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 'TWOX' == (b || 'x') FROM t1 WHERE (b || 'x')>'onex';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 'TWOX' == (b || 'x') COLLATE nocase  FROM t1 WHERE (b || 'x')>'onex';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t4 
  WHERE substr(a, 2) = 'abc' COLLATE NOCASE
  ORDER BY substr(a, 2), b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t5 WHERE abs(a)=2 or abs(b)=9;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b FROM x1 WHERE CAST(b AS INTEGER) = 123;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b FROM x1 WHERE CAST(b AS TEXT) = 123;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\indexexpr2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE ~('' BETWEEN t0.c0 AND TRUE);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\insert.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM test2 WHERE f1==-111;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\insert.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM test2 WHERE f1==77;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\insert.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM test2 WHERE f1='111' AND f2=-3.33;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\insert.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM test2 WHERE f1=22 AND f2=-4.44;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\insert.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t3 WHERE a = 0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\insert.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b,c FROM t3 WHERE a IS NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\insert.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE c=99;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\insert.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE b=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\insert.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE b=3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\insert2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT cnt FROM t1 WHERE log=3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\insert2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT log FROM t1 WHERE cnt=4 ORDER BY log;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\instr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT COUNT(*) FROM t0 WHERE INSTR(x'aabb', t0.c0) ORDER BY t0.c0, t0.c1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\instr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(c0) FROM t0 WHERE INSTR(x'aabb', t0.c0) ORDER BY t0.c0, t0.c1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\instr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(x) FROM t1 WHERE instr(x'aabb',x);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\instr.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(x) FROM t1 WHERE x>'zzz' AND instr(x'aabb',x);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\instrfault.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM h1 WHERE instr(a,b);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE rowid = -9223372036854775808;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE rowid = -9223372036854775808.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE rowid = -9223372036854775809.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE rowid = -9223372036854777856.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE rowid = +9223372036854775807;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE rowid = +9223372036854775807.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE rowid = +9223372036854775808.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE rowid = +9223372036854777856.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a==4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE b=='y';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE b=='y' AND rowid<0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE b=='y' AND rowid<0 AND rowid>=-20;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE b>='y';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE b>='y' AND rowid<10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, * FROM t1 WHERE b<'second';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, * FROM t1 WHERE 'second'>b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, * FROM t1 WHERE 8>rowid AND 'second'>b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, * FROM t1 WHERE 8>rowid AND 'second'>b AND 0<rowid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, * FROM t1 WHERE b>'a';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE b>'a';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a>=20;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE b=='hello';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE b=='b-21';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE rowid>=30;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE rowid>20;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a, c FROM t1 WHERE c=='www';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * from t2 WHERE x=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a=2.0+3.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a=2.0+3.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE a>2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE a>'2';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE a<'2';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE a<c;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE a=c;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a>2147483648;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a>=2147483648;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a>2147483648;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a>=2147483647;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a<2147483648;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a<12345678901;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intpkey.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t1 WHERE a>12345678901;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intreal.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT substr(a,1,4) FROM t2 WHERE a = CAST(836627109860825358 AS REAL);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\intreal.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (t1.c1 = CAST(8366271098608253588 AS REAL));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\istrue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y IS TRUE;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\istrue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y IS FALSE;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\istrue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y IS NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\istrue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y IS NOT TRUE;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\istrue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y IS NOT FALSE;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\istrue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y IS NOT NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\istrue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE true;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\istrue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE false;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\join.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM v0 WHERE NOT(v0.a IS FALSE);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\join.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM v0 WHERE v0.c NOTNULL NOTNULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\join2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT typeof(c0), c0 FROM v0 WHERE c0>='0';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\join8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t9 WHERE id=128*h+64*g+32*f+16*e+8*d+4*c+2*b+a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\join8.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t9 WHERE id<>128*h+64*g+32*f+16*e+8*d+4*c+2*b+a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\joinD.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM v1 WHERE y BETWEEN 30 AND 40 ORDER BY y;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json101.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM j1 WHERE NOT json_valid(x);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json101.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM j1 WHERE NOT json_valid(char(0x20,0x09,0x0a,0x0d)||x);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json101.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM j1 WHERE NOT json_valid(x||char(0x20,0x09,0x0a,0x0d));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json101.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM j1 WHERE json_remove(x)<>x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json101.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM j1 WHERE json_replace(x)<>x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json101.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM j1 WHERE json_set(x)<>x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json101.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM j1 WHERE json_insert(x)<>x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json101.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM j1 WHERE json_type(x) IN ('object','array');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json101.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM j1b WHERE json_type(x) IN ('object','array');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json103.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT json_group_array(a) FROM t1 WHERE a<0 AND typeof(a)!='blob';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json103.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(jsonb_group_array(a)) FROM t1 WHERE a<0 AND typeof(a)!='blob';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json103.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT json_group_array(a) FROM t1
   WHERE rowid BETWEEN 31 AND 39;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json103.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT json_array_length(json_group_array(a)) FROM t1
   WHERE rowid BETWEEN 31 AND 39;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json103.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT json_group_object(c,a) FROM t1 WHERE a<0 AND typeof(a)!='blob';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json103.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(jsonb_group_object(c,a)) FROM t1 WHERE a<0 AND typeof(a)!='blob';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json103.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT json_group_object(c,a) FROM t1
   WHERE rowid BETWEEN 31 AND 39 AND rowid%2==1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json106.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT j0 FROM t1 WHERE json(j0)!=json(json_pretty(j0));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json106.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT j5 FROM t1 WHERE json(j5)!=json(json_pretty(j5));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json108.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE json(j0)==json(json_pretty(j0,NULL));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json108.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE json(j0)==json(json_pretty(j0,''));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json108.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE json(j0)==json(json_pretty(j0,char(9)));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\json108.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE json(j0)==json(json_pretty(j0,'/*hello*/'));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\lastinsert.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select rin from rid where k=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\lastinsert.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select rout from rid where k=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\lastinsert.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select rin from rid where k=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\lastinsert.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select rout from rid where k=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\laststmtchanges.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select count() from t0 where x=8;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM t12nc WHERE x LIKE 'abc%' ORDER BY +id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM t12b WHERE x LIKE 'abc%' ORDER BY +id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM t12nc WHERE x LIKE 'abc%' COLLATE binary ORDER BY +id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM t12b WHERE x LIKE 'abc%' COLLATE binary ORDER BY +id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM t12nc WHERE x LIKE 'abc%' COLLATE nocase ORDER BY +id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM t12b WHERE x LIKE 'abc%' COLLATE nocase ORDER BY +id;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT y FROM t15 WHERE x LIKE 'ab/%d%' ESCAPE '/';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT y FROM t15 WHERE x LIKE 'abcdx%%' ESCAPE 'x';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT y FROM t15 WHERE x LIKE 'abx%%' ESCAPE 'x' ORDER BY +y;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT y FROM t15 WHERE x LIKE '/%bc%' ESCAPE '/';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a LIKE ' 1%';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a LIKE ' 1-';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE x LIKE 'abc' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE x GLOB 'abc' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE x LIKE 'ABC' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE x LIKE 'aBc' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE x REGEXP 'abc' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE x REGEXP '^abc' ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE x LIKE '''a%';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, * FROM t1 WHERE rowid GLOB '1*' ORDER BY rowid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b FROM t1 WHERE b LIKE 'aB%' ORDER BY +a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b FROM t1 WHERE +b LIKE 'aB%' ORDER BY +a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b FROM t2 WHERE b GLOB 'ab*' ORDER BY +a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b FROM t2 WHERE +b GLOB 'ab*' ORDER BY +a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b FROM t2 WHERE b>=x'6162' AND b GLOB 'ab*';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b FROM t2 WHERE +b>=x'6162' AND +b GLOB 'ab*';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b FROM t2 WHERE b GLOB 'ab*' AND b>=x'6162';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b FROM t2 WHERE +b GLOB 'ab*' AND +b>=x'6162';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(x) FROM t3 WHERE x LIKE 'ab%' ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(x) FROM t3 WHERE x LIKE 'ab%' ORDER BY x DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(x) FROM t3 WHERE x LIKE 'ab%' ORDER BY +x DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(x) FROM t3 WHERE x LIKE 'ab%' ORDER BY x ASC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(x) FROM t3 WHERE x LIKE 'ab%' ORDER BY +x ASC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(x) FROM t4 WHERE x LIKE 'ab%' ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(x) FROM t4 WHERE x LIKE 'ab%' ORDER BY x DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(x) FROM t4 WHERE x LIKE 'ab%' ORDER BY +x DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(x) FROM t4 WHERE x LIKE 'ab%' ORDER BY x ASC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT quote(x) FROM t4 WHERE x LIKE 'ab%' ORDER BY +x ASC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t5a WHERE x LIKE '/%';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t5a WHERE x LIKE '/a%';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t5a WHERE x LIKE '^12%' ESCAPE '^';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t5a WHERE x LIKE '^-2%' ESCAPE '^';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t5b WHERE x GLOB '/*';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t5b WHERE x GLOB '/a*';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t5c WHERE (c0 LIKE '+/');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE t0.c0 LIKE './';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE t0.c0 LIKE '.1%';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE t0.c0 GLOB '-*';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM Example WHERE word GLOB 'み*';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\like3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM Example WHERE word >= char(0x307F) AND word < char(0x3080);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\limit.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t1 WHERE rowid IN (SELECT rowid FROM t1 LIMIT 2);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\limit2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b, '|' FROM t1 WHERE a IN (2,4,5,3,1) ORDER BY b LIMIT 5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\limit2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b, '|' FROM t1 WHERE a IN (2,4,5,3,1) ORDER BY +b LIMIT 5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\limit2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b, '|' FROM t1 WHERE a IN (2,4,5,3,1) ORDER BY b DESC LIMIT 5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\limit2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a, b, '|' FROM t1 WHERE a IN (2,4,5,3,1) ORDER BY +b DESC LIMIT 5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\limit2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *,'.' FROM t300 WHERE a=0 AND (c=0 OR c=99) ORDER BY c DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\limit2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *,'.' FROM t300 WHERE a=0 AND (c=0 OR c=99) ORDER BY c DESC LIMIT 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\limit2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *,'x' FROM t400 WHERE a IN (1,2,3) ORDER BY b DESC LIMIT 3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\limit2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT *,'y' FROM t400 WHERE a IN (1,2,3) ORDER BY +b DESC LIMIT 3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\limit2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT j FROM t500 WHERE i IN (1,2,3,4,5) ORDER BY j DESC LIMIT 3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\limit2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT j FROM t501 WHERE i IN (1,2,3,4,5) ORDER BY j LIMIT 3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\limit2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT j FROM t502 WHERE i IN (1,2,3,4,5) ORDER BY j LIMIT 3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\main.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * from T1 where x!!5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\main.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * from T1 where ^x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\malloc3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM v1 WHERE d = g;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\mallocA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE a='abc' AND b='x';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\mallocA.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t1 WHERE a='abc' AND b<'y';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\mallocK.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM x1 WHERE a = (SELECT 1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\mallocK.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM x2 WHERE x = str('19') AND y = str('4');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(a) FROM t14 WHERE b='2' AND a>'50';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(x) FROM t1 WHERE x=5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(x) FROM t1 WHERE x>=5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(x) FROM t1 WHERE x>=4.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(x) FROM t1 WHERE x<4.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t2 WHERE a=(SELECT max(a) FROM t2);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t2 WHERE a=max_a_t2();
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT coalesce(max(rowid),999) FROM t3 WHERE rowid<25;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(x) FROM t1 WHERE y=5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT max(x) FROM t1 WHERE y=5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(x) FROM t1 WHERE y=6;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT max(x) FROM t1 WHERE y=6;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(x) FROM t1 WHERE y=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT max(x) FROM t1 WHERE y=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(x) FROM t1 WHERE y=0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT max(x) FROM t1 WHERE y=0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(x) FROM t1 WHERE y=5 AND x>=17.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT max(x) FROM t1 WHERE y=5 AND x>=17.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT max(a) FROM t7 WHERE a=5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(b) FROM t7 WHERE a=5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT max(b) FROM t7 WHERE a=5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(b) FROM t7 WHERE a=4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT max(b) FROM t7 WHERE a=4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(c) FROM t7 WHERE a=4 AND b=10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT max(c) FROM t7 WHERE a=4 AND b=10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(rowid) FROM t7 WHERE a=3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT max(rowid) FROM t7 WHERE a=3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(rowid) FROM t7 WHERE a=3 AND b=5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT max(rowid) FROM t7 WHERE a=3 AND b=5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(rowid) FROM t7 WHERE a=3 AND b=5 AND c=1015;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT max(rowid) FROM t7 WHERE a=3 AND b=5 AND c=15;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(b) FROM t2 WHERE a = 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(b) FROM t2 WHERE a = 1 AND b>1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(b) FROM t2 WHERE a = 1 AND b>-1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(b) FROM t2 WHERE a = 1 AND b<2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(b) FROM t2 WHERE a = 1 AND b<1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(b) FROM t2 WHERE a = 3 AND b<1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(a), b FROM t1 WHERE a<50;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT MIN(t0.c1), t0.c0 FROM t0 WHERE t0.c1 ISNULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT MIN(a) FROM t1 WHERE a=123;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\minmax4.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT min(a), b, c FROM t1 WHERE c='x';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x75 FROM manycol WHERE x50=350;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x50 FROM manycol WHERE x99=599;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x50 FROM manycol WHERE x99=899;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x1 FROM manycol WHERE x0=100;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT y FROM t9
       WHERE x=(SELECT x FROM t9 WHERE y=1)
          OR x=(SELECT x FROM t9 WHERE y=2)
          OR x=(SELECT x FROM t9 WHERE y=3)
          OR x=(SELECT x FROM t9 WHERE y=4)
          OR x=(SELECT x FROM t9 WHERE y=5)
          OR x=(SELECT x FROM t9 WHERE y=6)
          OR x=(SELECT x FROM t9 WHERE y=7)
          OR x=(SELECT x FROM t9 WHERE y=8)
          OR x=(SELECT x FROM t9 WHERE y=9)
          OR x=(SELECT x FROM t9 WHERE y=10)
          OR x=(SELECT x FROM t9 WHERE y=11)
          OR x=(SELECT x FROM t9 WHERE y=12)
          OR x=(SELECT x FROM t9 WHERE y=13)
          OR x=(SELECT x FROM t9 WHERE y=14);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE a>1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE a>2147483647;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE a<2147483648;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE a<=2147483648;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE a<10000000000;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE a<1000000000000 ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE a>=-2147483648 ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE a>-2147483648 ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE a>-2147483649 ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE a>=0 AND a<2147483649 ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE a>=0 AND a<=2147483648 ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE a>=0 AND a<2147483648 ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE a>=0 AND a<=2147483647 ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE a>=0 AND a<2147483647 ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(a) FROM t3 WHERE b IN (SELECT b FROM t3);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(a) FROM t3 WHERE b IN (SELECT b FROM t3 ORDER BY a+1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc3.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t3 WHERE 1+(b IN ('abc','xyz'))==2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\misc7.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t1 WHERE a = 1 ORDER BY b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\notnull2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE ((c0 NOT NULL) AND 1) OR (c0 == NULL);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\notnullfault.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE d NOT NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\null.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t5 WHERE a = 1 AND b IS NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\null.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t5 WHERE a IS NULL AND b = 'x';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\null.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t0 WHERE t0.c0 > NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\null.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT sum(b), total(b) FROM t1 WHERE b<0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\null.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select a from t1 where b<10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\null.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select a from t1 where not b>10;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\null.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select a from t1 where b<10 or c=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\null.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select a from t1 where b<10 and c=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\null.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
select a from t1 where not (b<10 and c=1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\null.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t4 WHERE y=NULL;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\null.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t4 WHERE y IN (33,NULL);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\null.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t4 WHERE y<33 ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\null.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t4 WHERE y>6 ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\null.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t4 WHERE y!=33 ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\nulls1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE a=1 ORDER BY b NULLS LAST;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\nulls1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t2 WHERE a=1 ORDER BY b DESC NULLS FIRST;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\nulls1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t4 WHERE a IN (1, 2, 3) ORDER BY a, b NULLS LAST;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\nulls1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t4 WHERE a IN (1, 2, 3) ORDER BY a DESC, b DESC NULLS FIRST;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\nulls1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a,b FROM t5 WHERE a=1 ORDER BY b NULLS LAST, c;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\nulls1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a,b FROM t5 WHERE a=1 ORDER BY b DESC NULLS FIRST, c DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\nulls1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t71 WHERE a=1 AND b=2 ORDER BY c NULLS LAST;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\nulls1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t71 WHERE a=1 AND b=2 ORDER BY c DESC NULLS FIRST;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\nulls1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c1, c2, ifnull(c3, 'NULL') FROM v0 
  WHERE c2=10 ORDER BY c1, c3 NULLS LAST;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\nulls2.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t2 WHERE (d, e, f) IN (
        SELECT a, b, c FROM t1
    );
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\orderby5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t4 WHERE b='abc' ORDER BY b COLLATE binary;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\orderby5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t5 WHERE b='def' ORDER BY b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\pager1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM z WHERE x < 100;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\pragma5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT DISTINCT name, builtin
    FROM pragma_function_list WHERE name='upper' AND builtin;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\pragma5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT DISTINCT name, builtin
    FROM pragma_function_list WHERE name LIKE 'exter%';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\pragma5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM pragma_module_list WHERE name='fts5';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\pragma5.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM pragma_pragma_list WHERE name='pragma_list';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'text', 'noop', 'blob') FROM t1 WHERE x=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'blob', 'noop', 'text') FROM t1 WHERE x=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'text', 'noop', 'text16') FROM t1 WHERE x=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'blob', 'noop', 'text16') FROM t1 WHERE x=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'text16', 'noop', 'blob') FROM t1 WHERE x=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'text16', 'noop', 'text') FROM t1 WHERE x=1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'text', 'noop', 'blob') FROM t1 WHERE x=3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'blob', 'noop', 'text') FROM t1 WHERE x=3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'text', 'noop', 'text16') FROM t1 WHERE x=3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'blob', 'noop', 'text16') FROM t1 WHERE x=3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'text16', 'noop', 'blob') FROM t1 WHERE x=3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'text16', 'noop', 'text') FROM t1 WHERE x=3;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'text', 'noop', 'blob') FROM t1 WHERE x=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'blob', 'noop', 'text') FROM t1 WHERE x=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'text', 'noop', 'text16') FROM t1 WHERE x=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'blob', 'noop', 'text16') FROM t1 WHERE x=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'text16', 'noop', 'blob') FROM t1 WHERE x=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'text16', 'noop', 'text') FROM t1 WHERE x=2;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'text', 'noop', 'blob') FROM t1 WHERE x=4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'blob', 'noop', 'text') FROM t1 WHERE x=4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'text', 'noop', 'text16') FROM t1 WHERE x=4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'blob', 'noop', 'text16') FROM t1 WHERE x=4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'text16', 'noop', 'blob') FROM t1 WHERE x=4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\ptrchng.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT pointer_change(y, 'text16', 'noop', 'text') FROM t1 WHERE x=4;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\pushdown.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM v3 WHERE a=2 AND b=200;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\pushdown.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a=2 AND f(b) AND f(c);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\pushdown.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a=3 AND f(c) AND f(b);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\pushdown.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM u1 WHERE f('one')=123 AND 123=(
      SELECT x FROM u2 WHERE x=a AND f('two')
    );
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\pushdown.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM u1 WHERE 123=(
      SELECT x FROM u2 WHERE x=a AND f('two')
    ) AND f('three')=123;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\quote.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE z='w';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y REGEXP 'by|in' ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y REGEXP 'by|Christ' ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE regexp('by|christ',y) ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE regexpi('by|christ',y) ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE regexpi('BY|CHRIST',y) ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y REGEXP 'shal+ al+' ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y REGEXP 'shall x*y*z*all' ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE regexp('shall x*y*z*all',y) ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE regexp('SHALL x*y*z*all',y) ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE regexpi('SHALL x*y*z*all',y) ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y REGEXP 'shallx?y? ?z?all' ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y REGEXP 'r{2}' ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y REGEXP 'r{3}' ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y REGEXP 'r{1}' ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y REGEXP 'ur{2,10}e' ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y REGEXP 'alive' ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y REGEXP '^alive' ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y REGEXP 'ma\w' ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y REGEXP 'ma\W' ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y REGEXP '\sma\w' ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y REGEXP '\Sma\w' ORDER BY x;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT x FROM t1 WHERE y REGEXP
          '\b(unto|us|son|given|his|name|called|' ||
          'wonderful|councelor|mighty|god|everlasting|father|' ||
          'prince|peace|alive)\b';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a='日本語';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE a LIKE '日本語';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 wHERE a REGEXP '日本語';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t2 WHERE a REGEXP '-';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\regexp1.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid FROM t2 WHERE a REGEXP '\-';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\reindex.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c0 FROM t0 WHERE c1 IS NULL ORDER BY 1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\reindex.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c0 FROM t0 WHERE c1 IS NULL AND c0 IN (1,2,3,4,5);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowhash.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT id FROM t1 WHERE a = 'a' OR b = 'b' OR c = 'c';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t14 WHERE x < 'a' ORDER BY rowid ASC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t14 WHERE x < 'a' ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT oid FROM t1 WHERE x>8;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t2 WHERE a NOT IN(1,2,1000000,1000001,2147483647);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT b FROM t2 WHERE a NOT IN(1,2,1000000,1000001,2147483647) 
          ORDER BY b;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE a<123.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE a<124.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE a>123.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE a>122.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE a==123.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE a==123.000;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE a>100.5 AND a<200.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE a>'xyz';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE a<'xyz';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t3 WHERE a>=122.9 AND a<=123.1;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid>=5.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid>=5.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid>5.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid>5.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE 5.5<=rowid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE 5.5<rowid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid<=5.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid<5.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE 5.5>=rowid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE 5.5>rowid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid>=5.5 ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid>=5.0 ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid>5.5 ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid>5.0 ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE 5.5<=rowid ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE 5.5<rowid ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid<=5.5 ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid<5.5 ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE 5.5>=rowid ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE 5.5>rowid ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE rowid>=-5.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE rowid>=-5.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE rowid>=-5.5 ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE rowid>=-5.0 ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE -5.5<=rowid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE -5.5<=rowid ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE rowid>-5.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE rowid>-5.0;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE rowid>-5.5 ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE rowid>-5.0 ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE -5.5<rowid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE -5.5<rowid ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE rowid<=-5.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE rowid<=-5.5 ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE -5.5>=rowid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE -5.5>=rowid ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE rowid<-5.5;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE rowid<-5.5 ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE -5.5>rowid;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t6 WHERE -5.5>rowid ORDER BY rowid DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid>'abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid>='abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid<'abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid<='abc';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid>'abc' ORDER BY 1 ASC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid>='abc' ORDER BY 1 ASC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid<'abc' ORDER BY 1 ASC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid<='abc' ORDER BY 1 ASC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid>'abc' ORDER BY 1 DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid>='abc' ORDER BY 1 DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid<'abc' ORDER BY 1 DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, a FROM t5 WHERE rowid<='abc' ORDER BY 1 DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT count(*) FROM t7 WHERE y=='x';
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowid.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT rowid, * FROM t1 WHERE rowid>1000;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM hh WHERE (a, b) = (SELECT 'abc', 1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM hh WHERE (a, b) = (SELECT 'abc' COLLATE nocase, 1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM hh WHERE a = (SELECT 'abc' COLLATE nocase) AND b = (SELECT 1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM hh WHERE +a = (SELECT 'abc' COLLATE nocase) AND b = (SELECT 1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM hh WHERE a = (SELECT 'abc') COLLATE nocase AND b = (SELECT 1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM hh WHERE (a COLLATE nocase, b) = (SELECT 'def', 2);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM hh WHERE (a COLLATE nocase, b) IS NOT (SELECT 'def', 2);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT c FROM hh WHERE (b, a) = (SELECT 2, 'def');
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM j1 WHERE (select min(a) FROM j1) IN (?, ?, ?);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT a FROM t3
    WHERE (c,d) IN (SELECT 'c','d' FROM dual)
    AND (a,b,e) IN (SELECT 'a','b','d' FROM dual);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 1 FROM t12 WHERE (1,x) BETWEEN (1,1) AND (3,3);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM b3 WHERE (SELECT b3.a, b3.b) IN ( SELECT a, b FROM b5 );
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM b3 WHERE (VALUES(b3.a, b3.b)) IN ( SELECT a, b FROM b5 );
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM b3 WHERE (b3.a, b3.b) IN ( SELECT a, b FROM b5 );
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a,b)>(0,0) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a,b)>=(0,0) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a,b)<(5,0) ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a,b)<=(5,0) ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a,b)>(3,0) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a,b)>=(3,0) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a,b)<(3,0) ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a,b)<=(3,0) ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a,b)>(3,32) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a,b)>(3,33) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a,b)>=(3,33) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a,b)>=(3,34) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a,b)<(3,34) ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a,b)<(3,33) ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a,b)<=(3,33) ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a,b)<=(3,32) ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (0,0)<(a,b) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (0,0)<=(a,b) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (5,0)>(a,b) ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (5,0)>=(a,b) ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (3,0)<(a,b) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (3,0)<=(a,b) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (3,0)>(a,b) ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (3,0)>=(a,b) ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (3,32)<(a,b) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (3,33)<(a,b) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (3,33)<=(a,b) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (3,34)<=(a,b) ORDER BY a;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (3,34)>(a,b) ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (3,33)>(a,b) ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (3,33)>=(a,b) ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (3,32)>=(a,b) ORDER BY a DESC;
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT * FROM t1 WHERE (a,b) IN (VALUES(1,2));
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 2 FROM t0 WHERE (+bb,1) >= (aa,1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 3 FROM t0 WHERE (aa,1) <= (+bb,1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 2 FROM t0 WHERE (SELECT +bb,1) >= (aa,1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 3 FROM t0 WHERE (aa,1) <= (SELECT +bb,1);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 2 FROM t0 WHERE (SELECT +bb) >= (aa);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 3 FROM t0 WHERE (aa) <= (SELECT +bb);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 2 FROM t0 WHERE (t0.c0, TRUE) > (CAST('' AS REAL), FALSE);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 2 FROM t0 WHERE (t0.c0, 0) < ('B' COLLATE NOCASE, 0);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 2 FROM t0 WHERE ('B' COLLATE NOCASE, 0)> (t0.c0, 0);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 2 FROM t0 WHERE ('B', 0)> (t0.c0 COLLATE nocase, 0);
-- EGRAPH_CORPUS_CASE_END

-- EGRAPH_CORPUS_CASE_BEGIN source=D:\sqlite-src\test\rowvalue.test mode=select-only
-- EGRAPH_CORPUS_SETUP_BEGIN
-- EGRAPH_BASE_QUERY
SELECT 2 FROM t0 WHERE (t0.c0 COLLATE nocase, 0) < ('B', 0);
-- EGRAPH_CORPUS_CASE_END

