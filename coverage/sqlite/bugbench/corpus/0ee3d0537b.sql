CREATE TABLE t(id INTEGER PRIMARY KEY, v TEXT);
INSERT INTO t VALUES (1,char(65533)),(2,char(65534)),
                     (3,char(65535)),(4,char(65532));
SELECT id, hex(v) FROM t WHERE v LIKE char(65533);
