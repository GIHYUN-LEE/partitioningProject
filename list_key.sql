use partitioningProject;

select * from real_dataset;
drop table list_key;

UPDATE real_dataset
SET 발급회원번호 = REPLACE(발급회원번호, 'SYN_', '');

ALTER TABLE real_dataset
MODIFY COLUMN 발급회원번호 int primary key;

UPDATE real_dataset SET 연체일자_B0M=YEAR(연체일자_B0M);  -- raw 데이터의 연체일자봄을 숫자형으로 변경
select * from real_dataset;

desc real_dataset;
drop table list_key;


CREATE TABLE list_key (
    발급회원번호 INT,
    남녀구분코드 INT,
    연령 VARCHAR(20),
    거주시도명 VARCHAR(20),
    월중평잔_일시불_B0M INT,
    연체일자_B0M INT,
    연체잔액_B0M INT,
    연체잔액_일시불_B0M INT,
    연체잔액_할부_B0M INT,
    primary key(발급회원번호)
) PARTITION BY LIST (연체일자_B0M)
   SUBPARTITION BY KEY(발급회원번호)
   SUBPARTITIONS 5(
      PARTITION P2005 VALUES IN (2000,2001, 2002, 2003, 2004),
      PARTITION P2010 VALUES IN (2005, 2006, 2007, 2008, 2009),
      PARTITION P2015 VALUES IN (2010, 2011, 2012, 2013, 2014),
      PARTITION P2020 VALUES IN (2015, 2016, 2017, 2018, 2019),
      PARTITION P2025 VALUES IN (2020, 2021, 2022, 2023, 2024, 2025)
   );

INSERT INTO list_key
(연령,발급회원번호,남녀구분코드 ,거주시도명,월중평잔_일시불_B0M,연체일자_B0M, 연체연도,연체잔액_B0M,연체잔액_일시불_B0M,연체잔액_할부_B0M)
SELECT 연령,발급회원번호,남녀구분코드 ,거주시도명,월중평잔_일시불_B0M,연체일자_B0M,year(연체일자_B0M),연체잔액_B0M,연체잔액_일시불_B0M,연체잔액_할부_B0M
FROM real_dataset;

-- 파티션 조회
SELECT 
  TABLE_NAME, PARTITION_NAME, SUBPARTITION_NAME, PARTITION_METHOD, SUBPARTITION_METHOD, TABLE_ROWS
FROM 
  information_schema.PARTITIONS
 where TABLE_NAME = 'list_key';  

SELECT 
  TABLE_NAME, PARTITION_NAME, SUBPARTITION_NAME, PARTITION_METHOD, SUBPARTITION_METHOD, TABLE_ROWS
FROM 
  information_schema.PARTITIONS
 where TABLE_NAME = 'real_dataset';  

-- ------------------------------------------------------------------------
SELECT 
  TABLE_NAME, PARTITION_NAME, TABLE_ROWS
FROM 
  information_schema.PARTITIONS
 where TABLE_NAME = 'list_key'; -- 비파티션

desc list_key;
show tables;
 
explain select * from real_dataset where year(연체일자_B0M)=2015; 
explain select * from list_key where 연체연도=2015;
-- --------------------------------------------------------------------------
-- 벤치마크용 프로시저 생성(성능비교) 100번 반복

DROP PROCEDURE IF EXISTS bench_partitioned;
DROP PROCEDURE IF EXISTS bench_non_partitioned;

-- 파티셔닝된 테이블에서 연체연도를 백번 조회하는 프로시져
CREATE PROCEDURE bench_partitioned()
BEGIN
  DECLARE i INT DEFAULT 0;
  WHILE i < 100 DO
    SELECT * FROM list_key WHERE 연체연도 = 2015;
    SET i = i + 1;
  END WHILE;
END;

-- 파티셔닝 되지 않은 테이블에서 연체연도를 백번 조회하는 프로시져
CREATE PROCEDURE bench_non_partitioned()
BEGIN
  DECLARE i INT DEFAULT 0;
  WHILE i < 100 DO
    SELECT * FROM real_dataset WHERE year(연체일자_B0M) = 2007;
    SET i = i + 1;
  END WHILE;
END;
-- -----------------------------------------------------------------
SET PROFILING = 1;

CALL bench_partitioned();  -- 파티션된 테이블에서 호출 100번
CALL bench_non_partitioned(); -- 비파션 테이블에서 호출 100번

SHOW PROFILES;