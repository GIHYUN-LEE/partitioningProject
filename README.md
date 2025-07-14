# 🧪 프로젝트
연체 이력 데이터를 기반으로 파티셔닝 방식(RANGE, LIST, HASH 등)을 적용하고, 방식별 쿼리 성능을 분석한 프로젝트입니다.

---
# 👥팀소개
<div align="center">
  
|이제현|김동민|이기현|장송하|
|:---:|:---:|:---:|:---:|
|[lyjh98](https://github.com/lyjh98)|[kddmmm](https://github.com/kddmmm)|[GIHYUN-LEE](https://github.com/GIHYUN-LEE)|[jangongha](https://github.com/songhajang)|
|<img width="200" height="250" alt="Image" src="https://github.com/user-attachments/assets/0302181c-9610-4743-9637-5c51a235579a" />|<img width="200" height="250" alt="Image" src="https://github.com/user-attachments/assets/0a3636dc-b947-4d83-ae30-6dbb5708b189" />|<img width="200" height="250" alt="Image" src="https://github.com/user-attachments/assets/417f7091-5fee-4d60-b975-0d67b5a37486" />|<img width="200" height="250" alt="Image" src="https://github.com/user-attachments/assets/36f811b5-e8e9-43f4-b833-b4b9dae40e82" />|
  
</div>

<br>

### 📌 파티셔닝이란
- **논리적으로는 하나의 테이블을**, 물리적으로 여러 테이블로 나누어 관리하는 기법입니다.
- **대용량 테이블을 분할하여 성능 향상 및 관리 용이성 확보** 등의 효과가 있습니다.
- [파티셔닝 학습](https://www.notion.so/22c7a1eb10db8045b6f7c8404e439c3d?source=copy_link)


# 🎯 목적

- MySQL 파티셔닝 방식(`RANGE`, `LIST`, `HASH`, `KEY`) 이해
- 단일 파티셔닝과 복합 파티셔닝의 성능 차이 비교 및 분석
- 파티셔닝 방식별 `PROCEDURE`를 통해 성능 차이 비교 및 분석

## ⚙️ 성능 테스트 시나리오

| 구분 | 내용 |
|------|----------|
| 측정 항목 | 쿼리 실행시간|
| 측정 대상 | 일반 테이블 및 파티셔닝 적용 테이블 8개<br>(Range,List,Hash,Key,Range-Hash,Range-Key,List-Hash,List-Key)|
| 비교 조건 | 1. 파티셔닝 적용 유무에 따른 차이<br>2. 단일 파티셔닝 방식별 차이<br>3. 복합 파티셔닝 방식별 차이|
| 사전 조건 | 대상 테이블 9개에 동일한 데이터(10만건) 삽입|
| 입력 조건 | 동일 조회쿼리 500회 반복 입력|
| 절&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;차 | 1. 대상 테이블에 입력 조건 3회 실행<br>2. QueryManager로 실행시간 평균값 도출<br>3. Mysql서버 재시작<br>4.나머지 테이블에 반복 실행|

---

# 🛠️ 테스트 환경

- **DBMS**: MySQL 8.2.0
- **Tool**: DBeaver, MySQL
- **OS**: Windows 10 / Ubuntu 22.04

---

# 📂 데이터 셋
데이터 출처: https://www.aihub.or.kr 의 금융 데이터(회원정보, 잔액정보) 이용하였습니다.

데이터 크기 : 총 100,000건 | 
파일 크기 : 5.6MB (csv, UTF-8 인코딩)

### 전처리 과정
**1. python을 이용한 테이블 생성** <br>
사용자별 연체 위험도를 표시하기 위해 연체 관련 컬럼(일자, 잔액 등)과 회원정보를 추출하여 병합하였습니다.

**2. 발급회원번호 format** <br>
발급회원번호의 값이 `SYN_0`형태의 varchar타입으로 제공되어 있어 INT 형식으로 포멧하였습니다.
	 
  ```sql
	-- SYN_0 으로 제공된 값 -> 0 으로 변경
 	UPDATE real_dataset SET 발급회원번호 = REPLACE(발급회원번호, 'SYN_', '');

	-- 0,1,2 .. 으로 변경된 값 INT 타입으로 타입변경
	ALTER TABLE real_dataset MODIFY COLUMN 발급회원번호 INT;
 ```
**3. PK 설정** <br>
파티션 및 서브파티션 KEY로 사용하기 위해 복합PK 설정하였습니다.

  ```sql
 	-- 발급회원번호, 연체연도 primary key로 등록
	ALTER TABLE real_dataset ADD PRIMARY KEY (발급회원번호, 연체연도);
 ```
**4. 데이터 삽입**

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
| 연령 | VARCHAR(20) |10대, 20대,30대,..|
| 거주시도명 | VARCHAR(20) |서울,부산,..|
| 월중평잔_일시불_B0M | INT |100,220 ,123,321...|
| 연체잔액_B0M | INT |100,000 , 200,100...|
| 연체잔액_일시불_B0M | INT |123,321...|
| 연체잔액_할부 | INT |0, 133,122...|


---

# ✍️ 파티셔닝 적용 테이블 제작
### 1. 파티셔닝 기준
 - 파티션 개수 5개로 분할(단일 파티셔닝 5개, 복합 파티셔닝 25개)
 - 파티션 키 : 발급회원번호, 연체연도

### 2. 파티셔닝 테이블 정보 확인 쿼리
  
```sql
  SELECT
    TABLE_NAME, PARTITION_NAME, SUBPARTITION_NAME, PARTITION_METHOD, SUBPARTITION_METHOD, TABLE_ROWS
  FROM
    information_schema.PARTITIONS
    WHERE TABLE_NAME='테이블명';
  
 ```

### 3. 아래 테이블은 최종 테이블 셋을 토대로 파티셔닝을 적용한 테이블입니다.

**1. LIST 파티셔닝**
<details>
<summary>1-1. LIST 파티셔닝</summary>
	
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

  ```
LIST 파티셔닝 적용 테이블 확인
<img width="1038" height="123" alt="리스트 파티셔닝 확인" src="https://github.com/user-attachments/assets/18d939d8-b6c3-42b2-be56-ef75cb5191a2" />
</details>
<details>
<summary>1-2. LIST-HASH 파티셔닝</summary>
  
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
  
  ```

LIST-HASH 파티셔닝 적용 테이블 확인
<img width="1040" height="507" alt="리스트-해쉬 파티셔닝 확인" src="https://github.com/user-attachments/assets/71926527-e306-49be-b8b4-00375cbe1a8d" />
</details>
<details>
<summary>1-3. LIST-KEY 파티셔닝<br><hr></summary>
  
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
  
  ```

LIST-KEY 파티셔닝 적용 테이블 확인
<img width="1040" height="510" alt="리스트-키 파티셔닝 확인" src="https://github.com/user-attachments/assets/daa5d1a4-e67b-4b24-afd7-a28376a813ff" />
</details>

**2. RANGE 파티셔닝**
<details>
<summary>2-1. RANGE 파티셔닝</summary>

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
  
  ```
RANGE 파티셔닝 적용 테이블 확인
<img width="1042" height="122" alt="레인지 파티셔닝 확인" src="https://github.com/user-attachments/assets/7bec90de-dc54-44e4-9549-8f8570e6c390" />
</details>
<details>
<summary>2-2. RANGE-HASH 파티셔닝</summary>
  
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
  
  ```

RANGE-HASH 파티셔닝 적용 테이블 확인
<img width="1042" height="503" alt="레인지-해쉬 파티셔닝 확인" src="https://github.com/user-attachments/assets/49cbb1c3-1073-4748-b344-2a92e63cba1e" />
</details>
<details>
<summary>2-3. RANGE-KEY 파티셔닝<br><hr></summary>
  
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

  ```

RANGE-KEY 파티셔닝 적용 테이블 확인
<img width="1041" height="503" alt="레인지-키 파티셔닝" src="https://github.com/user-attachments/assets/8723ca74-4ea4-4f33-bbb2-b08a6744cf4e" />
</details>


**3. HASH 파티셔닝**

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

  ```

HASH 파티셔닝 적용 테이블 확인
<img width="1044" height="122" alt="해쉬 파티셔닝 확인" src="https://github.com/user-attachments/assets/ca44f94c-0e44-4ce9-977a-aeb7e8f3d54f" />
</details>

**4. KEY 파티셔닝**

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

  ```

KEY 파티셔닝 적용 테이블 확인
<img width="1042" height="125" alt="키 파티셔닝" src="https://github.com/user-attachments/assets/2e322b99-fa50-487b-9ade-169a70d7ff9d" />
</details>

<br>

# ⌛ 실행 코드
`PROCEDURE`를 이용하여 파티셔닝 테이블 별 500번씩 `연체연도 = 2000 and 발급회원번호=9945` 조건을 조회합니다.(임시설정) <br>
### 📌 PROCEDURE 란
- 컴퓨터 프로그래밍에서 특정 작업을 수행하기 위해 **일련의 명령어들을 모아놓은 것입니다.**
- 이러한 명령어 집합은 **하나의 단위로서 작동하며, 반복적으로 수행되어야 하는 작업들을 효율적으로 처리할 수 있게 해줍니다.**

### PROCEDURE 를 이용한 테스트 코드

  ```sql
-- 테스트 프로시져
CREATE PROCEDURE test()
BEGIN
  DECLARE i INT DEFAULT 0;
  WHILE i < 500 DO
    SELECT * FROM 테이블명 IGNORE INDEX (PRIMARY) WHERE 연체연도=2000 and 발급회원번호=9945;
    SET i = i + 1;
  END WHILE;
END;

-- 프로시져 호출
CALL test();

```


# 📈 성능 비교 결과

## 파티셔닝 방식별 테스트 결과

| 파티셔닝 방식 | 평균 실행 시간 (s) | 단일 테이블 대비 성능 향상률 (%) |
|--------|----------------------|------------------|
| 파티셔닝 미적용 | 18s  | - |
| LIST | 4.195s | ▲ 76.7% |
| LIST-HASH | 1.01s | ▲ 94.4% |
| LIST-KEY | 1.001s | ▲ 94.4% |
| RANGE | 4.125s | ▲ 77.1% |
| RANGE-HASH | 0.98s | ▲ 94.6% |
| RANGE-KEY | 1.032s | ▲ 94.3% |
| HASH | 4.531s | ▲ 74.8% |
| KEY | 4.982s | ▲ 72.3% |
<br>

<details>
<summary>파티셔닝 방식별 테스트 출력화면</summary>
1. 단일테이블 성능<br>
<img width="354" height="79" alt="파티션 안한 테이블 성능" src="https://github.com/user-attachments/assets/3f43d228-f9d2-4d04-897f-d87f29f5eda1" />
<br>
2. LIST 파티셔닝<br>
<img width="353" height="82" alt="리스트 파티셔닝 테이블 성능" src="https://github.com/user-attachments/assets/0d941ae2-f0b3-42d6-bdf3-b0d174679e02" /><br>
3. LIST-HASH 파티셔닝<br>
<img width="350" height="78" alt="리스트-해쉬 파티셔닝 성능" src="https://github.com/user-attachments/assets/8021a0c0-14b0-4cae-b2e8-63f900d51cc9" /><br>
4. LIST-KEY 파티셔닝<br>
<img width="352" height="82" alt="리스트-키 성능" src="https://github.com/user-attachments/assets/bc4cfc06-4fc8-4bdb-8a8f-13b0f13e45ab" /><br>
5. RANGE 파티셔닝<br>
<img width="355" height="80" alt="레인지 파티셔닝 테이블 성능" src="https://github.com/user-attachments/assets/54655617-e961-4e85-891c-81fd8c38ba2d" /><br>
6. RANGE-HASH 파티셔닝<br>
<img width="356" height="79" alt="레인지-해쉬 성능" src="https://github.com/user-attachments/assets/c94a4f82-80df-4ab7-b46f-7ab1cb9fb230" /><br>
7. RANGE-KEY 파티셔닝<br>
<img width="350" height="73" alt="레인지-키 파티셔닝 성능" src="https://github.com/user-attachments/assets/3cd99ee0-c284-417b-9cf0-174bb262e073" /><br>
8. HASH 파티셔닝<br>
<img width="355" height="78" alt="해쉬 파티셔닝 성능" src="https://github.com/user-attachments/assets/7533099b-2ece-4f18-a69b-81107bfa4794" /><br>
9. KEY 파티셔닝<br>
<img width="353" height="80" alt="키 파티셔닝 성능" src="https://github.com/user-attachments/assets/72eb4ad2-a7d9-430b-807a-bd67a547ca98" /><br>
</details>


## 🔍 테스트 결과에 대한 고찰

### ✅ 단일 테이블 대비 성능 향상

- **단일 파티셔닝** 의 경우 : 약 75% 향상 했습니다.
- **복합 파티셔닝** 의 경우 : 약 94% 향상 했습니다.
- **복합** 파티셔닝은 **단일** 파티셔닝보다 약 77% 향상 했습니다.

### ✅ 파티셔닝 방식별 성능

- **단일 파티셔닝** 의 경우 : `RANGE`
- **복합 파티셔닝** 의 경우 : `RANGE-HASH`
- **고려사항** : 파티셔닝 방식에 따른 상이한 데이터 타입, 방대한 데이터 및 파티션 개수를 고려해야합니다.

### ⚠️ KEY 파티셔닝의 예외적 결과

- 8개의 방식 중 유일하게 데이터가 균등하게 분할되지 않았습니다.
- `KEY`는 **MySQL 내부의 비공개 해시 알고리즘을 사용**하여, 분산 방식의 **예측이 불가** 하며 데이터가 **편중**될 수 있습니다.
<img width="1042" height="125" alt="키 파티셔닝" src="https://github.com/user-attachments/assets/e146af2e-c403-4f8a-98e9-a86334bda246" />

### ✅ 결론
- KEY 파티셔닝은 데이터 특성 및 분포에 민감하므로 실무 적용 시 주의 필요합니다.
- 데이터 양과 파티션 개수에 따른 분석 필요합니다.

<br>

# 🚀 트러블 슈팅

## 🧠 초기 아이디어 소통 오류

<img width="548" height="400" alt="Image" src="https://github.com/user-attachments/assets/e642efb2-da42-4cb9-9db7-630438dd725a" />

- 프로젝트 초반 아이디어를 도출하고 정리하는 과정에서,**동일한 주제를 바라보는 관점과 해석이 구성원마다 달라** 아이디어 선정에 시간이 걸렸습니다.
- **해결 방법**
	- 서로가 생각하는 프로젝트의 방향성과 핵심 목표에 대해 **구체적으로 대화하는 시간을 마련하고**,  
	이를 통해 각자의 관점과 해석 차이 이해하는 단계를 통해 문제를 해결했습니다.<br>
 	✅ *해결 완료*
<br>

## 🧹 데이터 import 이슈

- `csv` 파일을 `UTF-8`로 저장했음에도 업로드 시 **한글 깨짐** 현상 발생했습니다.
- **해결 방법**  
  - 업로드 전 `SET NAMES utf8mb4`로 문자셋 동기화 처리를 통해 해결했습니다.<br>
  ✅ *문제 해결 완료*

---

## 🧩 MySQL 파티셔닝 방식 실험

 ### ⚙️ 1차 시도: `LIST - RANGE`

- **목표**  
  `성별` 기준으로 리스트 분할 후, `연체원금_최근` 기준 범위로 서브 파티셔닝을 목표로 진행해 보았습니다.

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
  `RANGE → HASH → LIST` 구조의 **3단계 파티셔닝** 시도해 보았습니다.
  
 - **결과** <br>
   ❌ 서브 파티셔닝으로 3차는 MySQL에서 허용되지 않았습니다.



📢 **결론** <br>
MYSQL 기준 **2단계 파티셔닝**까지 지원하며, **메인 파티셔닝은 RANGE와 LIST 서브 파티셔닝은 HASH와 KEY** 사용 가능하다는걸 알게되었습니다.

---

## ⚙️ 파티션 키로 조회 시 탐색하는 row의 수가 1이되는 현상

- **이슈**  
 
```sql
explain analyze select * from range_hash
where 연체연도=2000 and 발급회원번호=9945;
```

<img width="545" height="50" alt="PK 트러블 슈팅(전)" src="https://github.com/user-attachments/assets/9667496c-818f-4673-9358-e6b0d3e0eb52" /><br>
row의 수가 서브파티션의 row(약 4000개)로 출력되지 않는 이슈 발생했습니다.
  
- **해결 방법**
```sql
explain analyze select * from range_hash
IGNORE INDEX (PRIMARY)
where 연체연도=2000 and 발급회원번호=9945;
```

 <img width="1316" height="50" alt="PK 트러블 슈팅(후)" src="https://github.com/user-attachments/assets/20fa270a-7c49-4347-bfe1-3a33214fa7c6" /><br>

 파티셔닝 기법만으로 성능 비교를 위해 PK 인덱스 탐색을 배제하여 문제를 해결했습니다.

 ---
 ## 🔍 향후 발전방향

 ### 1. 방대한 데이터양과 파티션 개수에 따른 파티셔닝 성능 비교
 ### 2. 적절한 파티셔닝 기법으로 연체 위험도 분석 실시
