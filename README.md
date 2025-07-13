# 🧪 연체 위험도 분석
대규모 연체 이력 데이터를 기반으로 MySQL의 파티셔닝 전략(RANGE, LIST, HASH 등)을 적용하고, 전략별 쿼리 성능을 분석한 프로젝트입니다.

---
# 👥팀소개
<div align="center">
  
|이제현|김동민|이기현|장송하|
|:---:|:---:|:---:|:---:|
|[]()|[kddmmm](https://github.com/kddmmm)|[GIHYUN-LEE](https://github.com/GIHYUN-LEE)|[jangongha](https://github.com/songhajang)|
|<img width="200" height="250" alt="Image" src="" />|<img width="200" height="250" alt="Image" src="https://github.com/user-attachments/assets/0a3636dc-b947-4d83-ae30-6dbb5708b189" />|<img width="200" height="250" alt="Image" src="https://github.com/user-attachments/assets/417f7091-5fee-4d60-b975-0d67b5a37486" />|<img width="200" height="250" alt="Image" src="https://github.com/user-attachments/assets/158494bb-76c3-41b3-b457-213f6add7b3b" />|
  
</div>

<br>


### 📌 파티셔닝이란
- **논리적으로는 하나의 테이블**, 물리적으로 여러 테이블로 나누어 관리하는 기법
- **대용량 테이블을 분할하여 성능 향상 및 관리 용이성 확보** 등의 효능이 있다.


# 🎯 목적

- MySQL 파티셔닝 기능(`RANGE`, `LIST`, `HASH`, `KEY`) 이해
- 파티셔닝 기능별 `PROCEDURE`을 통해 성능 차이 비교 및 분석

## ⚙️ 실험 시나리오

| 조건 | 목적 |
|------|----------|
| 파티셔닝 미적용 | 파티셔닝 사용전의 데이터 조회 속도와 적용후의 속도차이 실험|
|메인 파티셔닝 종류 차이 | 메인 파티셔닝 `RANGE`와`LIST`의 사용 방식에 대한 속도차이 실험|
|하위 파티셔닝 종류 차이| 하위 파티셔닝 `HASH`와`KEY`의 사용 방식에 대한 속도차이 실험|

---

# 🛠️ 테스트 환경

- **DBMS**: MySQL 8.2.0
- **Tool**: DBeaver, MySQL
- **OS**: Windows 10 / Ubuntu 22.04

---

# 📂 데이터 셋
데이터 출처: https://www.aihub.or.kr 의 금융 데이터 이용

데이터 크기 : 총 100,000건 | 
파일 크기 : 5.6MB (.csv, UTF-8 인코딩)

### 전처리 과정
**1. python을 이용한 가상의 데이터 추가** <br>
`연체일자_B0M`, `연체잔액_B0M `, `연체잔액_일시불_B0M `, `연체잔액_할부_B0M` 의 컬럼을 값을 이용한 연체 위험도를 표시하기 위해 가상의 데이터를 추가

**2. 발급회원번호 format** <br>
발급회원번호의 값이 `SYN_0`으로 제공되어 있어 파티션의 KEY값 사용하기 위해 INT 형식으로 포멧 후 primary key 등록
	 
  ```sql
	-- SYN_0 으로 제공된 값 -> 0 으로 변경
 	UPDATE real_dataset SET 발급회원번호 = REPLACE(발급회원번호, 'SYN_', '');

	-- 0,1,2 .. 으로 변경된 값 INT 타입으로 타입변경
	ALTER TABLE real_dataset MODIFY COLUMN 발급회원번호 int;

 	-- 발급회원번호 primary key로 등록
	ALTER TABLE real_dataset MODIFY COLUMN 발급회원번호 int primary key;
 ```
**3. 데이터 삽입**

```sql
-- 테이블별 데이터 삽입
INSERT INTO 파티션테이블명
 (발급회원번호, 남녀구분코드, 연령, 거주시도명, 월중평잔_일시불_B0M, 연체일자_B0M, 연체잔액_B0M, 연체잔액_일시불_B0M, 연체잔액_할부_B0M, 연체연도)
 SELECT 발급회원번호, 남녀구분코드, 연령, 거주시도명, 월중평잔_일시불_B0M, 연체일자_B0M, 연체잔액_B0M, 연체잔액_일시불_B0M, 연체잔액_할부_B0M, 연체연도
 FROM real_dataset;
```



### 최종 테이블 구조

| 컬럼명 | 데이터 타입 | 데이터 형식 |
|------|------|------|
| 발급회원번호 | INT (PK) | 0 ,1, 2...|
| 연체연도 | INT (PK) | 2000,2001...|
| 연체일자_B0M | DATE |2002-02-10, 2024-10-30, ...|
| 남녀구분코드 | INT |1(남),2(여),1(남),...|
| 연령 | VARCHAR(20) |나이대 10대, 20대,30대,..|
| 거주시도명 | VARCHAR(20) |서울,부산,..|
| 월중평잔_일시불_B0M | INT |100,220 ,123,321...|
| 연체잔액_B0M | INT |100,000 , 200,100...|
| 연체잔액_일시불_B0M | INT |123,321...|
| 연체잔액_할부 | INT |0, 133,122...|


---

# ✍️ 파티셔닝 테이블 제작
아래 테이블 코드는 **최종 테이블 구조**를 토대로 파티셔닝기능을 추가하여 제작한  코드입니다.

## 1. LIST 파티셔닝 코드
### 1-1. LIST 파티셔닝

  ```sql
  CREATE TABLE list (
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
) PARTITION BY LIST (연체연도)(
		PARTITION P2005 VALUES IN (2000,2001, 2002, 2003, 2004),
		PARTITION P2010 VALUES IN (2005, 2006, 2007, 2008, 2009),
		PARTITION P2015 VALUES IN (2010, 2011, 2012, 2013, 2014),
		PARTITION P2020 VALUES IN (2015, 2016, 2017, 2018, 2019),
		PARTITION P2025 VALUES IN (2020, 2021, 2022, 2023, 2024, 2025)
	);

  -- 데이터 삽입
  INSERT INTO list
  (발급회원번호, 남녀구분코드, 연령, 거주시도명, 월중평잔_일시불_B0M, 연체일자_B0M, 연체잔액_B0M, 연체잔액_일시불_B0M, 연체잔액_할부_B0M, 연체연도)
  SELECT 발급회원번호, 남녀구분코드, 연령, 거주시도명, 월중평잔_일시불_B0M, 연체일자_B0M, 연체잔액_B0M, 연체잔액_일시불_B0M, 연체잔액_할부_B0M, 연체연도
  FROM real_dataset;
  
  ```
LIST 파티셔닝을 이용해 만들어진 `list` 테이블에 대한 이미지입니다.
<img width="1038" height="123" alt="리스트 파티셔닝 확인" src="https://github.com/user-attachments/assets/18d939d8-b6c3-42b2-be56-ef75cb5191a2" />



### 1-2. LIST+HASH 파티셔닝
  
  ```sql
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
) PARTITION BY list (연체연도)
	SUBPARTITION BY hash(발급회원번호)
	SUBPARTITIONS 5(
		PARTITION P2005 VALUES IN (2000,2001, 2002, 2003, 2004),
		PARTITION P2010 VALUES IN (2005, 2006, 2007, 2008, 2009),
		PARTITION P2015 VALUES IN (2010, 2011, 2012, 2013, 2014),
		PARTITION P2020 VALUES IN (2015, 2016, 2017, 2018, 2019),
		PARTITION P2025 VALUES IN (2020, 2021, 2022, 2023, 2024, 2025)
	);

-- 데이터 삽입
INSERT INTO list_hash
(연령,발급회원번호,남녀구분코드 ,거주시도명,월중평잔_일시불_B0M,연체일자_B0M, 연체연도,연체잔액_B0M,연체잔액_일시불_B0M,연체잔액_할부_B0M)
SELECT 연령,발급회원번호,남녀구분코드 ,거주시도명,월중평잔_일시불_B0M,연체일자_B0M,year(연체일자_B0M),연체잔액_B0M,연체잔액_일시불_B0M,연체잔액_할부_B0M
FROM real_dataset;
  
  ```

LIST+HASH 파티셔닝을 이용해 만들어진 `list_hash` 테이블에 대한 이미지입니다.
<img width="1040" height="507" alt="리스트-해쉬 파티셔닝 확인" src="https://github.com/user-attachments/assets/71926527-e306-49be-b8b4-00375cbe1a8d" />



### 1-3. LIST+KEY 파티셔닝
  
  ```sql
 CREATE TABLE list_key (
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
) PARTITION BY list (연체연도)
	SUBPARTITION BY key(발급회원번호)
	SUBPARTITIONS 5(
		PARTITION P2005 VALUES IN (2000,2001, 2002, 2003, 2004),
		PARTITION P2010 VALUES IN (2005, 2006, 2007, 2008, 2009),
		PARTITION P2015 VALUES IN (2010, 2011, 2012, 2013, 2014),
		PARTITION P2020 VALUES IN (2015, 2016, 2017, 2018, 2019),
		PARTITION P2025 VALUES IN (2020, 2021, 2022, 2023, 2024, 2025)
	);

-- 데이터 삽입
INSERT INTO list_key
(연령,발급회원번호,남녀구분코드 ,거주시도명,월중평잔_일시불_B0M,연체일자_B0M, 연체연도,연체잔액_B0M,연체잔액_일시불_B0M,연체잔액_할부_B0M)
SELECT 연령,발급회원번호,남녀구분코드 ,거주시도명,월중평잔_일시불_B0M,연체일자_B0M,year(연체일자_B0M),연체잔액_B0M,연체잔액_일시불_B0M,연체잔액_할부_B0M
FROM real_dataset;
  
  ```

LIST+KEY 파티셔닝을 이용해 만들어진 `list_key` 테이블에 대한 이미지입니다.
<img width="1040" height="510" alt="리스트-키 파티셔닝 확인" src="https://github.com/user-attachments/assets/daa5d1a4-e67b-4b24-afd7-a28376a813ff" />


---

## 2. RANGE 파티셔닝 코드

### 2-1. RANGE 파티셔닝

  ```sql
  CREATE TABLE p_range (
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
) PARTITION BY range (연체연도)(
		PARTITION P2005 VALUES LESS THAN (2005),
		PARTITION P2010 VALUES LESS THAN (2010),
		PARTITION P2015 VALUES LESS THAN (2015),
		PARTITION P2020 VALUES LESS THAN (2020),
		PARTITION P2025 VALUES LESS THAN MAXVALUE
	);

  -- 데이터 삽입
  INSERT INTO p_range
  (발급회원번호, 남녀구분코드, 연령, 거주시도명, 월중평잔_일시불_B0M, 연체일자_B0M, 연체잔액_B0M, 연체잔액_일시불_B0M, 연체잔액_할부_B0M, 연체연도)
  SELECT 발급회원번호, 남녀구분코드, 연령, 거주시도명, 월중평잔_일시불_B0M, 연체일자_B0M, 연체잔액_B0M, 연체잔액_일시불_B0M, 연체잔액_할부_B0M, 연체연도
  FROM real_dataset;
  
  ```
RANGE 파티셔닝을 이용해 만들어진 `p_range` 테이블에 대한 이미지입니다.
<img width="1042" height="122" alt="레인지 파티셔닝 확인" src="https://github.com/user-attachments/assets/7bec90de-dc54-44e4-9549-8f8570e6c390" />



### 2-2. RANGE+HASH 파티셔닝
  
  ```sql
 CREATE TABLE range_hash (
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
) PARTITION BY range (연체연도)
	SUBPARTITION BY HASH(발급회원번호)
	SUBPARTITIONS 5(
		PARTITION P2005 VALUES LESS THAN (2005),
		PARTITION P2010 VALUES LESS THAN (2010),
		PARTITION P2015 VALUES LESS THAN (2015),
		PARTITION P2020 VALUES LESS THAN (2020),
		PARTITION P2025 VALUES LESS THAN MAXVALUE
	);

-- 데이터 삽입
INSERT INTO range_hash
(연령,발급회원번호,남녀구분코드 ,거주시도명,월중평잔_일시불_B0M,연체일자_B0M, 연체연도,연체잔액_B0M,연체잔액_일시불_B0M,연체잔액_할부_B0M)
SELECT 연령,발급회원번호,남녀구분코드 ,거주시도명,월중평잔_일시불_B0M,연체일자_B0M,year(연체일자_B0M),연체잔액_B0M,연체잔액_일시불_B0M,연체잔액_할부_B0M
FROM real_dataset;
  
  ```

RANGE+HASH 파티셔닝을 이용해 만들어진 `range_hash` 테이블에 대한 이미지입니다.
<img width="1042" height="503" alt="레인지-해쉬 파티셔닝 확인" src="https://github.com/user-attachments/assets/49cbb1c3-1073-4748-b344-2a92e63cba1e" />



### 2-3. RANGE+KEY 파티셔닝
  
  ```sql
 CREATE TABLE range_key (
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
) PARTITION BY range (연체연도)
	SUBPARTITION BY key(발급회원번호)
	SUBPARTITIONS 5(
		PARTITION P2005 VALUES LESS THAN (2005),
		PARTITION P2010 VALUES LESS THAN (2010),
		PARTITION P2015 VALUES LESS THAN (2015),
		PARTITION P2020 VALUES LESS THAN (2020),
		PARTITION P2025 VALUES LESS THAN MAXVALUE
	);

-- 데이터 삽입
INSERT INTO range_key
(연령,발급회원번호,남녀구분코드 ,거주시도명,월중평잔_일시불_B0M,연체일자_B0M, 연체연도,연체잔액_B0M,연체잔액_일시불_B0M,연체잔액_할부_B0M)
SELECT 연령,발급회원번호,남녀구분코드 ,거주시도명,월중평잔_일시불_B0M,연체일자_B0M,year(연체일자_B0M),연체잔액_B0M,연체잔액_일시불_B0M,연체잔액_할부_B0M
FROM real_dataset;

  ```

RANGE+KEY 파티셔닝을 이용해 만들어진 `range_key` 테이블에 대한 이미지입니다.
<img width="1041" height="503" alt="레인지-키 파티셔닝" src="https://github.com/user-attachments/assets/8723ca74-4ea4-4f33-bbb2-b08a6744cf4e" />


---

## 3. KEY 파티셔닝 코드

### 3-1. KEY 파티셔닝

  ```sql
 CREATE TABLE p_key (
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
) PARTITION BY key (연체연도)
	PARTITIONS 5;

-- 데이터 삽입
INSERT INTO p_key
(발급회원번호, 남녀구분코드, 연령, 거주시도명, 월중평잔_일시불_B0M, 연체일자_B0M, 연체잔액_B0M, 연체잔액_일시불_B0M, 연체잔액_할부_B0M, 연체연도)
SELECT 발급회원번호, 남녀구분코드, 연령, 거주시도명, 월중평잔_일시불_B0M, 연체일자_B0M, 연체잔액_B0M, 연체잔액_일시불_B0M, 연체잔액_할부_B0M, 연체연도
FROM real_dataset;

  ```

KEY 파티셔닝을 이용해 만들어진 `p_key` 테이블에 대한 이미지입니다.
<img width="1042" height="125" alt="키 파티셔닝" src="https://github.com/user-attachments/assets/2e322b99-fa50-487b-9ade-169a70d7ff9d" />


---

## 4. HASH 파티셔닝 코드

### 4-1. HASH 파티셔닝

  ```sql
 CREATE TABLE hash (
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
) PARTITION BY hash (연체연도)
	PARTITIONS 5;

-- 데이터 삽입
INSERT INTO hash
(발급회원번호, 남녀구분코드, 연령, 거주시도명, 월중평잔_일시불_B0M, 연체일자_B0M, 연체잔액_B0M, 연체잔액_일시불_B0M, 연체잔액_할부_B0M, 연체연도)
SELECT 발급회원번호, 남녀구분코드, 연령, 거주시도명, 월중평잔_일시불_B0M, 연체일자_B0M, 연체잔액_B0M, 연체잔액_일시불_B0M, 연체잔액_할부_B0M, 연체연도
FROM real_dataset;

  ```

HASH 파티셔닝을 이용해 만들어진 `hash` 테이블에 대한 이미지입니다.
<img width="1044" height="122" alt="해쉬 파티셔닝 확인" src="https://github.com/user-attachments/assets/ca44f94c-0e44-4ce9-977a-aeb7e8f3d54f" />



<br>

# ⌛ 실행 코드
`PROCEDURE`를 이용하여 파티셔닝 테이블 별 100번씩 ` 연체연도 = 2015;` 조건을 조회합니다. <br>
(2015년 기준으로  이전이면 연체 위험도 **고** | 이후면 연체 위험도 **저** 로 임시 설정)
### 📌 PROCEDURE 란
- 컴퓨터 프로그래밍에서 특정 작업을 수행하기 위해 **일련의 명령어들을 모아놓은 것**
- 이러한 명령어 집합은 **하나의 단위로서 작동하며, 반복적으로 수행되어야 하는 작업들을 효율적으로 처리할 수 있게 해준다**

### PROCEDURE 를 이용한 테스트 코드

  ```sql
  -- 파티션 미적용 테이블
  CREATE PROCEDURE bench_non_partitioned()
  BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < 100 DO
      SELECT SQL_NO_CACHE * FROM real_dataset WHERE 연체연도 = 2015;
      SET i = i + 1;
    END WHILE;
  END;

  -- LIST 파티셔닝 테이블
  CREATE PROCEDURE bench_partitioned_list_()
  BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < 100 DO
      SELECT SQL_NO_CACHE * FROM list WHERE 연체연도 = 2015;
      SET i = i + 1;
    END WHILE;
  END;

  -- RANGE 파티셔닝 테이블
  CREATE PROCEDURE bench_partitioned_range_()
  BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < 100 DO
      SELECT SQL_NO_CACHE * FROM p_range WHERE 연체연도 = 2015;
      SET i = i + 1;
    END WHILE;
  END;

  -- LIST + HAST 파티셔닝 테이블
  CREATE PROCEDURE bench_partitioned_list_hash()
  BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < 100 DO
      SELECT SQL_NO_CACHE * FROM list_hash WHERE 연체연도 = 2015;
      SET i = i + 1;
    END WHILE;
  END;

  -- LIST + KEY 파티셔닝 테이블
  CREATE PROCEDURE bench_partitioned_list_key()
  BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < 100 DO
      SELECT SQL_NO_CACHE * FROM list_key WHERE 연체연도 = 2015;
      SET i = i + 1;
    END WHILE;
  END;

  -- RANGE + HASH 파티셔닝 테이블
  CREATE PROCEDURE bench_partitioned_range_hash()
  BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < 100 DO
      SELECT SQL_NO_CACHE * FROM range_hash WHERE 연체연도 = 2015;
      SET i = i + 1;
    END WHILE;
  END;

  -- RANGE + KEY 파티셔닝 테이블
  CREATE PROCEDURE bench_partitioned_range_key()
  BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < 100 DO
      SELECT SQL_NO_CACHE * FROM range_key WHERE 연체연도 = 2015;
      SET i = i + 1;
    END WHILE;
  END;

 -- KEY 파티셔닝 테이블
  CREATE PROCEDURE bench_partitioned_key()
  BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < 100 DO
      SELECT SQL_NO_CACHE * FROM p_key WHERE 연체연도 = 2015;
      SET i = i + 1;
    END WHILE;
  END;

 -- HASH 파티셔닝 테이블
  CREATE PROCEDURE bench_partitioned_hash()
  BEGIN
    DECLARE i INT DEFAULT 0;
    WHILE i < 100 DO
      SELECT SQL_NO_CACHE * FROM hash WHERE 연체연도 = 2015;
      SET i = i + 1;
    END WHILE;
  END;

  ```
### PROCEDURE 테스트 함수 실행 코드

```sql
-- 파티션X
CALL bench_non_partitioned();

-- list 파티션
CALL bench_partitioned_list_();

-- range 파티션
CALL bench_partitioned_range_();

-- list + hash 파티션
CALL bench_partitioned_list_hash();

-- list + key 파티션
CALL bench_partitioned_list_key();

-- range + hash 파티션
CALL bench_partitioned_range_hash();

-- range + key 파티션
CALL bench_partitioned_range_key();

-- key 파티션
CALL bench_partitioned_key();

-- hash 파티션
CALL bench_partitioned_hash();

```


# 📈 성능 비교 결과
`PROCEDURE`로 파티셔닝 종류별 테스트 결과입니다.


| 실험명 | 평균 실행 시간 (s) | 성능 향상률 (%) |
|--------|----------------------|------------------|
| 파티셔닝 미적용 | 18s  | - |
| LIST 파티셔닝(list()) | 4.195s | ▲ 76.7% |
| LIST+HASH(list_hash()) | 1.01s | ▲ 94.4% |
| LIST+KEY(list_key()) | 1.001s | ▲ 94.4% |
| RANGE 파티셔닝(p_range()) | 4.125s | ▲ 77.1% |
| RANGE+HASH(range_hash()) | 0.98s | ▲ 94.6% |
| RANGE+KEY(range_key()) | 1.032s | ▲ 94.3% |
| KEY(p_key()) | 4.982s | ▲ 72.3% |
| HASH(hash()) | 4.531s | ▲ 74.8% |


## 🔍 파티션 분포 및 예외 결과에 대한 고찰

본 실험에서는 총 **10만 건의 연체 데이터를 대상으로 8가지 파티셔닝 전략**을 적용하였으며, 실험의 일관성을 위해 파티셔닝 기준을 **5개의 파티션으로 고정**하였습니다.

### ✅ 파티션당 레코드 수 예측

- **단일 파티셔닝 (RANGE, LIST 등)** 의 경우:  
  전체 10만 건 데이터를 5개 파티션으로 분할 → 각 파티션당 **약 2만 건** 예상  
- **복합 파티셔닝 (LIST+HASH, RANGE+KEY 등)** 의 경우:  
  5개 메인 파티션 × 2개 서브파티션 = 총 10개의 서브 파티션  
  → 각 서브파티션당 **약 4천 건** 분포 예상

이러한 데이터 분포를 기반으로 쿼리 성능을 비교하고자 했으며, 대부분의 전략이 예상한 대로 성능 향상을 보여주었습니다.

### ⚠️ KEY 파티셔닝의 예외적 결과

8개의 전략 중 유일하게 **KEY 파티셔닝 기반 전략만이 기대와 다른 결과**를 보였습니다.
  - `HASH`는 사용자가 지정한 필드를 기준으로 **명시적인 해시 함수 분산**이 이루어지는 반면,
  - `KEY`는 **MySQL 내부의 비공개 해시 알고리즘을 사용**하며, 사용자 입장에서 분산 방식이나 키 값을 **예측하거나 통제할 수 없습니다.**
- 이로 인해 동일한 입력값이라도 **어떤 파티션으로 분배될지 명확하지 않으며**, 결과적으로 일부 파티션에 데이터가 **편중**될 수 있습니다.
<img width="1042" height="125" alt="키 파티셔닝" src="https://github.com/user-attachments/assets/e146af2e-c403-4f8a-98e9-a86334bda246" />


### ✅ 결론
- 파티션 개수, 서브파티션 구조를 고려한 설계는 실험 정확도를 높이고, 성능 향상 예측을 가능하게 했습니다.
- **KEY 파티셔닝은 데이터 특성 및 분포에 민감하므로 실무 적용 시 주의가 필요**가 필요합니다.
- 실험 설계 시 단순 파티션 수만이 아니라, **분산 방식과 조건 필드의 관계를 사전 분석하는 접근이 필수적**임을 확인할 수 있었습니다.


<br>

# 🚀 트러블 슈팅

## 🧠 초기 아이디어 소통 오류

<img width="548" height="400" alt="Image" src="https://github.com/user-attachments/assets/e642efb2-da42-4cb9-9db7-630438dd725a" />

- 프로젝트 초반 아이디어를 도출하고 정리하는 과정에서,**동일한 주제를 바라보는 관점과 해석이 구성원마다 다르게 전달되는 상황**이 발생했습니다.
- **해결 방법**
	- 서로가 생각하는 프로젝트의 방향성과 핵심 목표에 대해 **구체적으로 대화하는 시간을 마련하였고**,  
	이를 통해 각자의 관점과 해석 차이 이해하기<br>
 	✅ *해결 완료*
<br>

## 🧹 데이터 정제화 이슈

- `.csv` 파일을 `UTF-8`로 저장했음에도 업로드 시 **한글 깨짐** 현상 발생했습니다.
- **해결 방법**  
  - 저장 시 **BOM(Byte Order Mark)** 포함 설정 적용  
  - 업로드 전 `SET NAMES utf8mb4`로 문자셋 동기화 처리  
  ✅ *문제 해결 완료*

---

## 🧩 MySQL 파티셔닝 전략 실험

 ### ⚙️ 1차 시도: `LIST + RANGE`

- **목표**  
  `성별` 기준으로 리스트 분할 후, `연체원금_최근` 기준 범위로 서브 파티셔닝

- **시도한 코드**
  ```sql
  CREATE TABLE temp_data (
      발급회원번호 VARCHAR(20),
      성별 CHAR(1),
      연체원금_최근 INT
  )
  PARTITION BY LIST (성별)
  SUBPARTITION BY RANGE (연체원금_최근)
  (
      PARTITION p_male VALUES IN ('M')
          SUBPARTITIONS 3 (
              SUBPARTITION sp_male_low VALUES LESS THAN (100000),
              SUBPARTITION sp_male_mid VALUES LESS THAN (500000),
              SUBPARTITION sp_male_high VALUES LESS THAN MAXVALUE
          ),
      PARTITION p_female VALUES IN ('F')
          SUBPARTITIONS 3 (
              SUBPARTITION sp_female_low VALUES LESS THAN (100000),
              SUBPARTITION sp_female_mid VALUES LESS THAN (500000),
              SUBPARTITION sp_female_high VALUES LESS THAN MAXVALUE
          )
  );
  
- **결과** <br>
   ❌ MySQL에서 `LIST + RANGE` 조합은 직접적인 서브 파티셔닝으로 지원되지 않았습니다.


 
 ### ⚙️ 2차 시도: `RANGE → HASH → LIST` 조합의 3차 파티셔닝
 
- **목표**  
  다차원 기준 (연체일자, 정보아이디, 금액)을 모두 반영하기 위해  
  `RANGE → HASH → LIST` 구조의 **3단계 파티셔닝** 시도했습니다.
  
 - **결과** <br>
   ❌ 서브 파티셔닝으로 3차는 MySQL에서 허용되지 않았습니다.



📢 **결론** <br>
파티셔닝 방식별 성능 차이와 query문 작성을 경험하기를 **주 목적**으로 하여<br>
4명이서 각각 `list+hash` , `list+key` , `range+hast`, `range+key` 방식으로 간단하게 개발을 진행하기로 결정했습니다.

---

## 📟 파티셔닝 제작시 이슈
 
 ### ⚙️ `LIST`에서 속성 설정시 값 정의 이슈

- **이슈**  
  LIST에 부여할 값을 연도 (2001,2002,2003...) 범위로 설정하여 적용할려고 했지만
  에러 발생했습니다.
  
- **해결 방법**  
  연체연도 column 생성 후 해당 column을 통해 파티셔닝 진행했습니다.
    
  ✅ *문제 해결 완료*

<br>

 ### ⚙️ 파티션 테이블을 파티션 키로 조회 시 탐색하는 row의 수가 1이되는 현상

- **이슈**  
 
```sql
explain analyze select * from range_hash
where 연체연도=2000 and 발급회원번호=9945;
```

<img width="545" height="50" alt="PK 트러블 슈팅(전)" src="https://github.com/user-attachments/assets/9667496c-818f-4673-9358-e6b0d3e0eb52" /><br>
row의 수가 서브파티션의 row(약 400개)로 출력되지 않는 이슈가 발생했습니다.
  
- **해결 방법**
```sql
explain analyze select * from range_hash
IGNORE INDEX (PRIMARY)
where 연체연도=2000 and 발급회원번호=9945;
```

 <img width="1316" height="50" alt="PK 트러블 슈팅(후)" src="https://github.com/user-attachments/assets/20fa270a-7c49-4347-bfe1-3a33214fa7c6" /><br>

 파티셔닝 기법만으로 성능 비교를 위해 PK 인덱스 탐색을 배제했습니다.
    
  ✅ *문제 해결 완료*

<br>
