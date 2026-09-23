CREATE TABLE t1(c1 TEXT);
INSERT INTO t1 VALUES(0);
SELECT count(*) FROM t1
WHERE (c1=json_quote(0)) AND (json_object('c',c1) IS '{"c":0}');
SELECT count(*) FROM t1 WHERE (c1=json_quote(0)) AND (json_object('c',c1) IS '{"c":0}');
