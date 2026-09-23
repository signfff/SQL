CREATE TABLE t1(a INT, j TEXT);
INSERT INTO t1 VALUES(1, '{"x":[1,2]}');
CREATE INDEX t1_x_idx ON t1(a, json_extract(j,'$.x'));
SELECT subtype((SELECT json_extract(j,'$.x') FROM t1 WHERE a=1));
SELECT json_array((SELECT json_extract(j,'$.x') FROM t1 WHERE a=1));
