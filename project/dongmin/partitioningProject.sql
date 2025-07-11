use partitioningProject;

select * from real_dataset;

UPDATE dataset SET VIP등급코드 = 0 where VIP등급코드 = '_';
UPDATE dataset SET 최상위카드등급코드 = 0 where 최상위카드등급코드 = '_';
UPDATE dataset SET 연체일수_최근 = 0 where 연체일수_최근 < 0;
UPDATE dataset SET 연체일수_B1M = 0 where 연체일수_B1M < 0;
UPDATE dataset SET 연체일수_B2M = 0 where 연체일수_B2M < 0;
UPDATE dataset SET 최종연체회차 = 0 where 최종연체회차 < 0;

UPDATE real_dataset
SET 발급회원번호 = REPLACE(발급회원번호, 'SYN_', '');

ALTER TABLE real_dataset
MODIFY COLUMN 발급회원번호 int primary key;

desc real_dataset;

UPDATE dataset;
select 연체일자_B0M from real_dataset;
select 연체일수_최근 from dataset where 연체원금_B1M > 0 or 연체원금_B2M > 0 or 연체일수_최근 > 0;

CREATE TABLE list_hash (
    발급회원번호 INT,
    남녀구분코드 INT,
    연령 VARCHAR(20),
    거주시도명 VARCHAR(20),
    월중평잔_일시불_B0M INT,
    연체일자_B0M DATE,
    연체연도 INT,
    연체잔액_B0M INT,
    연체잔액_일시불_B0M INT,
    연체잔액_할부_B0M INT,
    primary key(발급회원번호, 연체연도)
) PARTITION BY LIST (연체연도)
	SUBPARTITION BY HASH(발급회원번호)
	SUBPARTITIONS 5(
		PARTITION P2005 VALUES IN (2000,2001, 2002, 2003, 2004),
		PARTITION P2010 VALUES IN (2005, 2006, 2007, 2008, 2009),
		PARTITION P2015 VALUES IN (2010, 2011, 2012, 2013, 2014),
		PARTITION P2020 VALUES IN (2015, 2016, 2017, 2018, 2019),
		PARTITION P2025 VALUES IN (2020, 2021, 2022, 2023, 2024, 2025)
	);

INSERT INTO list_hash
(연령,발급회원번호,남녀구분코드 ,거주시도명,월중평잔_일시불_B0M,연체일자_B0M, 연체연도,연체잔액_B0M,연체잔액_일시불_B0M,연체잔액_할부_B0M)
SELECT 연령,발급회원번호,남녀구분코드 ,거주시도명,월중평잔_일시불_B0M,연체일자_B0M,year(연체일자_B0M),연체잔액_B0M,연체잔액_일시불_B0M,연체잔액_할부_B0M
FROM real_dataset;

insert into list_hash values(1, 1, '20대', '서울', 123123, '2015-03-21', year('2015-03-21'), 123, 123 ,123);
insert into list_hash values(1, 1, '20대', '서울', 123123, '2015-03-21', 2000, 123, 123 ,123);
insert into list_hash values(1213, 1, '20대', '서울', 123123, '2015-03-21', 2001, 123, 123 ,123);
insert into list_hash values(11, 1, '20대', '서울', 123123, '2015-03-21', 2002, 123, 123 ,123);
insert into list_hash values(421, 1, '20대', '서울', 123123, '2015-03-21', 2003, 123, 123 ,123);
insert into list_hash values(11111, 1, '20대', '서울', 123123, '2015-03-21', 2003, 123, 123 ,123);
insert into list_hash values(11111, 1, '20대', '서울', 123123, '2015-03-21', 2000, 123, 123 ,123);

-- 파티션 조회
SELECT 
  TABLE_NAME, PARTITION_NAME, TABLE_ROWS
FROM 
  information_schema.PARTITIONS
 where TABLE_NAME = 'list_hash';


-- 1) 파티셔닝 안 한 테이블
SELECT SQL_NO_CACHE COUNT(*)
FROM real_dataset;
-- 2) 파티셔닝 한 테이블
SELECT SQL_NO_CACHE COUNT(*)
FROM list_hash;

SELECT 
    event_name,
    timer_start,
    timer_end,
    ROUND((timer_end - timer_start)/1000000) AS duration_ms
FROM performance_schema.events_statements_history
ORDER BY event_id DESC limit 4;

LIMIT 1;

select * from real_dataset where 발급회원번호 = 1125;
select * from list_hash where 발급회원번호 = 1125;
select * from list_hash where 발급회원번호 = 25;



-- LIST -> RANGE : 불가능
CREATE TABLE delinquency_data (
    발급회원번호 VARCHAR(20),
    성별 CHAR(1),
    연체원금_최근 INT
)
PARTITION BY LIST (성별)
SUBPARTITION BY RANGE (연체원금_최근)
(
    PARTITION p_male VALUES IN ('M')
        SUBPARTITIONS 3
        (
            SUBPARTITION sp_male_low VALUES LESS THAN (100000),
            SUBPARTITION sp_male_mid VALUES LESS THAN (500000),
            SUBPARTITION sp_male_high VALUES LESS THAN MAXVALUE
        ),
        
    PARTITION p_female VALUES IN ('F')
        SUBPARTITIONS 3
        (
            SUBPARTITION sp_female_low VALUES LESS THAN (100000),
            SUBPARTITION sp_female_mid VALUES LESS THAN (500000),
            SUBPARTITION sp_female_high VALUES LESS THAN MAXVALUE
        )
);
