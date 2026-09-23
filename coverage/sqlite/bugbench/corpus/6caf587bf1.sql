CREATE TABLE t1(a INT, j TEXT);
INSERT INTO t1 VALUES(1,'{"x":[1,2]}');
CREATE INDEX ix ON t1(a, json_extract(j,'$.x'));
SELECT json_array(+json_extract(j,'$.x')) FROM t1 WHERE a=1;
