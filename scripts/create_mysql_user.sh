#!/bin/bash

mysql --user=root --host=mysql <<EOF
CREATE DATABASE IF NOT EXISTS gitlabhq_test;
CREATE USER 'gitlab'@'%';
GRANT ALL PRIVILEGES ON gitlabhq_test.* TO 'gitlab'@'%';
FLUSH PRIVILEGES;
EOF
