CREATE TABLE t0(c0 TEXT, c1 INT);
INSERT INTO t0 VALUES ('1', 10);
CREATE INDEX i0 ON t0(c1) WHERE c0=json_quote(1);
SELECT c0, (c0=json_quote(1) AND json_array(c0)='[1]') AS p FROM t0;
SELECT count(*) FROM t0 NOT INDEXED WHERE (c0=json_quote(1) AND json_array(c0)='[1]');
SELECT count(*) FROM t0 WHERE (c0=json_quote(1) AND json_array(c0)='[1]');
