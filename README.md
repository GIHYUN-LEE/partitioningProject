# 🧪 MySQL Partition

MySQL의 `PARTITION BY` 구문을 실습하며 파티셔닝의 동작 원리와 성능 차이를 테스트하기 위한 미니 프로젝트입니다.

---

# 🎯 목적

- MySQL 파티셔닝 기능(`RANGE`, `LIST`, `HASH`, `KEY`) 이해
- 실제 데이터를 기반으로 파티션 전략을 테스트하고 동작 방식 확인
- `EXPLAIN`, `SELECT`, `INSERT` 등을 통해 파티션 분기 여부 확인

---

# 🛠️ 테스트 환경

- **DBMS**: MySQL 8.2.0
- **Tool**: DBeaver, MySQL
- **OS**: Windows 10 / Ubuntu 22.04

---

# 📂 주요 실험 내용

| 유형 | 설명 | 컬럼명 |
|------|------|------|
| `RANGE` | 연체일자 년도 기준으로 분리 | `연체일자_B0M` 기준 |
| `LIST` |  연체일자 년도 기준으로 분리 | `연체일자_B0M` 기준 |

---

# 🚀 트러블 슈팅

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


# 📄 예제 테이블 생성

```sql
CREATE TABLE transactions (
  id INT NOT NULL,
  amount DECIMAL(7,2),
  tr_date DATE,
  PRIMARY KEY (id, tr_date)
)
PARTITION BY HASH(MONTH(tr_date))
PARTITIONS 6;
```

---


---
