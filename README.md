# 🧪 연체 위험도 분석

MySQL의 `PARTITION BY` 구문을 실습하며 파티셔닝의 동작 원리와 성능 차이를 테스트하기 위한 미니 프로젝트입니다.

---

# 🎯 목적

- MySQL 파티셔닝 기능(`RANGE`, `LIST`, `HASH`, `KEY`) 이해
- `EXPLAIN`, `SELECT`, `INSERT` 등을 통해 파티션 분기 여부 확인
- 파티셔닝 기능별로 성능 차이 비교 및 분석
---

# 🛠️ 테스트 환경

- **DBMS**: MySQL 8.2.0
- **Tool**: DBeaver, MySQL
- **OS**: Windows 10 / Ubuntu 22.04

---

# 📂 데이터 셋
데이터 출처: https://www.aihub.or.kr

데이터 크기 : 총 100,000건 | 
파일 크기 : 5.6MB (.csv, UTF-8 인코딩)

### 전처리 과정
**1. python을 이용한 가상의 데이터 추가** <br>
`연체일자_B0M`, `연체잔액_B0M `, `연체잔액_일시불_B0M `, `연체잔액_할부_B0M` 의 컬럼을 값을 이용한 연체 위험도를 표시하기 위해 가상의 데이터를 추가

**2. 발급회원번호 format** <br>
발급회원번호의 값이 `SYN_0`으로 제공되어 있어 파티션의 KEY값 사용하기 위해 INT 형식으로 포멧 후 primary key 등록
	 
  ```
	-- SYN_0 으로 제공된 값 -> 0 으로 변경
 	UPDATE real_dataset SET 발급회원번호 = REPLACE(발급회원번호, 'SYN_', '');

	-- 0,1,2 .. 으로 변경된 값 INT 타입으로 타입변경
	ALTER TABLE real_dataset MODIFY COLUMN 발급회원번호 int;

 	-- 발급회원번호 primary key로 등록
	ALTER TABLE real_dataset MODIFY COLUMN 발급회원번호 int primary key;
 ```



### 최종 테이블 구조

| 컬럼명 | 데이터 타입 | 설명글 |
|------|------|------|
| 발급회원번호 | INT (PK) |------|
| 연체연도 | INT (PK) |------|
| 연체일자_B0M | DATE |------|
| 남녀구분코드 | INT |------|
| 연령 | VARCHAR(20) |------|
| 거주시도명 | VARCHAR(20) |------|
| 월중평잔_일시불_B0M | INT |------|
| 연체잔액_B0M | INT |------|
| 연체잔액_일시불_B0M | INT |------|
| 연체잔액_할부 | INT |------|


---

# 📄 파티션 테이블 생성
## 📌 파티셔닝의 의미
- **논리적으로는 하나의 테이블**, 물리적으로는 여러 테이블로 나누어 관리하는 기법
- **대용량 테이블을 분할하여 성능 향상 및 관리 용이성 확보** 효능이 있다.

<br>

### ✍️ 파티셔닝 테이블 제작
아래 코드 테이블을 토대로 파티셔닝 기능에 맞게 **제작된 파티셔닝 테이블** 코드입니다.
<details>
<summary>LIST + HAST</summary>
  
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
  ) PARTITION BY LIST (연체연도)
  	SUBPARTITION BY HASH(발급회원번호)
  	SUBPARTITIONS 5(
  		PARTITION P2005 VALUES IN (2000,2001, 2002, 2003, 2004),
  		PARTITION P2010 VALUES IN (2005, 2006, 2007, 2008, 2009),
  		PARTITION P2015 VALUES IN (2010, 2011, 2012, 2013, 2014),
  		PARTITION P2020 VALUES IN (2015, 2016, 2017, 2018, 2019),
  		PARTITION P2025 VALUES IN (2020, 2021, 2022, 2023, 2024, 2025)
  	);
  
  ```

</details>


<details>
<summary>LIST + KEY</summary>
  
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
) PARTITION BY LIST (연체연도)
   SUBPARTITION BY KEY(발급회원번호)
   SUBPARTITIONS 5(
      PARTITION P2005 VALUES IN (2000,2001, 2002, 2003, 2004),
      PARTITION P2010 VALUES IN (2005, 2006, 2007, 2008, 2009),
      PARTITION P2015 VALUES IN (2010, 2011, 2012, 2013, 2014),
      PARTITION P2020 VALUES IN (2015, 2016, 2017, 2018, 2019),
      PARTITION P2025 VALUES IN (2020, 2021, 2022, 2023, 2024, 2025)
   );
  
  ```
</details>


<details>
<summary>RANGE + HASH</summary>
  
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
) 
PARTITION BY RANGE (연체연도)
SUBPARTITION BY HASH (발급회원번호)
SUBPARTITIONS 5 (
  PARTITION p_before_2005 VALUES LESS THAN (2005),
  PARTITION p_before_2010 VALUES LESS THAN (2010),
  PARTITION p_before_2015 VALUES LESS THAN (2015),
  PARTITION p_before_2020 VALUES LESS THAN (2020),
  PARTITION p_before_2025 VALUES LESS THAN MAXVALUE
);
  
  ```
</details>


<details>
<summary>RANGE + KEY</summary>
  
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
) 
PARTITION BY LIST (연체연도)
SUBPARTITION BY KEY (발급회원번호)
SUBPARTITIONS 5 (
 	PARTITION P2005 VALUES IN (2000,2001, 2002, 2003, 2004),
  	PARTITION P2010 VALUES IN (2005, 2006, 2007, 2008, 2009),
    PARTITION P2015 VALUES IN (2010, 2011, 2012, 2013, 2014),
    PARTITION P2020 VALUES IN (2015, 2016, 2017, 2018, 2019),
    PARTITION P2025 VALUES IN (2020, 2021, 2022, 2023, 2024, 2025)
);
  
  ```
</details>

<br>

# 📢 분석

<img width="887" height="298" alt="Image" src="https://github.com/user-attachments/assets/7ebae2ae-4e38-469e-9338-9aaa6b3c83a2" /><br>
파티션 테이블에서 조회 결과
<br>
각 코드별 테스트
<br>
<img width="452" height="118" alt="Image" src="https://github.com/user-attachments/assets/b07b65a0-02a4-4b66-80d3-617e98f70cbd" />
<br>
해당 코드를 통해 쿼리문을 100번 반복하여 소요된 시간을 측정
<br>
LIST<br>
<img width="670" height="16" alt="Image" src="https://github.com/user-attachments/assets/784a36af-89f0-4beb-839e-d5200672e98d" />
<br>
RANGE<br>
<img width="669" height="19" alt="Image" src="https://github.com/user-attachments/assets/c2148f1c-9d98-46a0-b742-52b91fe60e46" />
<br>
LIST + HASH<br>
<img width="673" height="21" alt="Image" src="https://github.com/user-attachments/assets/58cae26d-b946-423f-bfc7-e7fcbaca81ef" />
<br>
LIST + KEY<br>
<img width="676" height="19" alt="Image" src="https://github.com/user-attachments/assets/8ede0c1c-51e8-4e5d-b2af-e64d5df99b5a" />
<br>
RANGE + HASH<br>
<img width="679" height="18" alt="Image" src="https://github.com/user-attachments/assets/b6061047-406a-4e62-8089-22914795e21f" />
<br>
RANGE + KEY<br><img width="671" height="19" alt="Image" src="https://github.com/user-attachments/assets/2fd0d4f4-0e7d-4191-9f00-77bee4790fd1" />
<br>
# 🚀 트러블 슈팅

## 🧠아이디어 정하기

<img width="948" height="800" alt="Image" src="https://github.com/user-attachments/assets/e642efb2-da42-4cb9-9db7-630438dd725a" />

<br>

## 🧹 데이터 정제화 이슈

- `.csv` 파일을 `UTF-8`로 저장했음에도 업로드 시 **한글 깨짐** 현상 발생  
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
   ❌ MySQL에서 `LIST + RANGE` 조합은 직접적인 서브 파티셔닝으로 지원되지 않음


 
 ### ⚙️ 2차 시도: `RANGE → HASH → LIST` 조합의 3차 파티셔닝
 
- **목표**  
  다차원 기준 (연체일자, 정보아이디, 금액)을 모두 반영하기 위해  
  `RANGE → HASH → LIST` 구조의 **3단계 파티셔닝** 시도
  
 - **결과** <br>
   ❌ 서브 파티셔닝으로 3차는 MySQL에서 허용되지 않음 



📢 **결론** <br>
파티셔닝 방식별 성능 차이와 query문 작성을 경험하기를 **주 목적**으로 하여<br>
4명이서 각각 `list+hash` , `list+key` , `range+hast`, `range+key` 방식으로 간단하게 개발을 진행하기로 결정

---

## 📟 파티셔닝 제작시 이슈
 
 ### ⚙️  `LIST`에서 속성 설정시 값 정의 이슈

- **목표**  
  LIST에 부여할 값을 연도 (2001,2002,2003...) 범위로 설정하여 적용할려고 했지만
  에러 발생
  
- **해결 방법**  
  year()사용하여 column을 생성하여 사용으로 해결
    
  ✅ *문제 해결 완료*

<br>

