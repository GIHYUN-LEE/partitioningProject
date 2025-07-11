create database partitioningProject;
use partitioningProject;

show tables;
desc real_dataset;

select * from real_dataset;


UPDATE real_dataset
SET 발급회원번호 = REPLACE(발급회원번호, 'SYN_', '');

ALTER TABLE real_dataset
MODIFY COLUMN 발급회원번호 int primary key;


CREATE TABLE range_hash (
  	연령 INT,
  	발급회원번호 INT,
    남녀구분코드 INT,
    거주시도명 VARCHAR(20),
    월중평잔_일시불_B0M INT,
    연체일자_B0M DATE,
    연체잔액_B0M INT,
    연체잔액_일시불_B0M INT,
    연체잔액_할부_B0M INT,
    primary key(발급회원번호, 연체일자_B0M)
) 
PARTITION BY RANGE (YEAR(연체일자_B0M))
SUBPARTITION BY HASH (발급회원번호)
SUBPARTITIONS 5 (
  PARTITION p_before_2005 VALUES LESS THAN (2005),
  PARTITION p_before_2010 VALUES LESS THAN (2010),
  PARTITION p_before_2015 VALUES LESS THAN (2015),
  PARTITION p_before_2020 VALUES LESS THAN (2020),
  PARTITION p_before_2025 VALUES LESS THAN MAXVALUE
);

drop table range_hash;
select * from real_dataset;

INSERT INTO range_hash 
(연령,발급회원번호,남녀구분코드 ,거주시도명,월중평잔_일시불_B0M,연체일자_B0M,연체잔액_B0M,연체잔액_일시불_B0M,연체잔액_할부_B0M)
SELECT 연령,발급회원번호,남녀구분코드 ,거주시도명,월중평잔_일시불_B0M,연체일자_B0M,연체잔액_B0M,연체잔액_일시불_B0M,연체잔액_할부_B0M
FROM real_dataset;


SELECT 
  TABLE_NAME, PARTITION_NAME, TABLE_ROWS
FROM 
  information_schema.PARTITIONS
WHERE 
  TABLE_NAME = 'range_hash';
 