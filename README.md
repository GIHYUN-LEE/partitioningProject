# 🧪 MySQL Partition

MySQL의 `PARTITION BY` 구문을 실습하며 파티셔닝의 동작 원리와 성능 차이를 테스트하기 위한 미니 프로젝트입니다.

---

## 🎯 목적

- MySQL 파티셔닝 기능(`RANGE`, `LIST`, `HASH`, `KEY`) 이해
- 실제 데이터를 기반으로 파티션 전략을 테스트하고 동작 방식 확인
- `EXPLAIN`, `SELECT`, `INSERT` 등을 통해 파티션 분기 여부 확인

---

## 🛠️ 테스트 환경

- **DBMS**: MySQL 8.2.0
- **Tool**: DBeaver, VS Code, Docker MySQL
- **OS**: Windows 10 / Ubuntu 22.04

---

## 📂 주요 실험 내용

| 유형 | 설명 | 예시 |
|------|------|------|
| `RANGE` | 연속된 값 구간으로 파티션 | `birth_year` 기준 |
| `LIST` | 특정 값 집합으로 분리 | 지역 코드 기준 |
| `HASH` | 해시로 균등 분배 | `MONTH(tr_date)` 기준 |
| `KEY` | 기본 키 기반 자동 해싱 | `id` 컬럼 기반 |

---

## 📄 예제 테이블 생성

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

## 🚀 트러블 슈팅

작성란

---
