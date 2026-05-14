# 🛡️ 시스템 관제 자동화 및 보안 구축 프로젝트

## 1. 프로젝트 개요
본 프로젝트는 단순한 리눅스 명령어 실행을 넘어, 실제 현업 엔지니어의 서버 운영 프로세스를 모델링하여 **보안-권한-관제-자동화 파이프라인**을 구축한 프로젝트입니다 [1]. 서버 장애 발생 시 로그와 관제 데이터를 통해 원인을 즉각 분석하고, 외부 공격으로부터 서버를 요새화하는 전체 과정을 구현했습니다 [1, 2].

---

## 2. 주요 시스템 설계 및 아키텍처

### 2-1. 보안 및 네트워크 설정 (Security Hardening)
외부 공격 표면을 최소화하고 허가된 통로만 이용하도록 서버를 요새화했습니다 [3].
* **SSH 보안 강화:** 기본 포트를 `22`에서 `20022`로 변경하고, Root 계정의 원격 로그인(`PermitRootLogin no`)을 엄격히 차단했습니다 [3].
* **방화벽(UFW) 화이트리스트:** 서비스 운영에 필수적인 포트인 `20022/TCP(SSH)`와 `15034/TCP(APP)` 두 가지만 개방하여 보안을 강화했습니다 [3].

### 2-2. 계정 및 권한 체계 (RBAC Design)
최소 권한 원칙(Principle of Least Privilege)에 따라 용도별로 계정과 그룹을 분리하여 접근 범위를 엄격히 제어합니다 [4].

| 구분 | 이름 | 소속 그룹 | 역할 및 권한 |
|---|---|---|---|
| **계정** | `agent-admin` | `agent-common`, `agent-core` | 운영/관리, Cron 스케줄러 실행자 |
| **계정** | `agent-dev` | `agent-common`, `agent-core` | 개발/운영, 관제 스크립트(`monitor.sh`) 작성자 |
| **계정** | `agent-test` | `agent-common` | QA 및 테스트용 제한 계정 |
| **권한** | `upload_files/` | `agent-common` 그룹 | 일반 공유 디렉토리 (R/W 가능) |
| **권한** | `api_keys/`, `log/`| `agent-core` 그룹 | **보안 키 및 로그 격리 디렉토리 (test 계정 접근 불가)** |

---

## 3. 핵심 자동화 기능 (Monitor & Cron)

### 3-1. 관제 스크립트 (`bin/monitor.sh`)
백그라운드에서 실행되는 앱의 상태와 시스템 리소스를 헬스 체크합니다. 이 스크립트는 보안을 위해 소유자 `agent-dev`, 그룹 `agent-core`로 설정되었으며 권한은 `750`으로 제한됩니다 [5].
* **프로세스 및 포트 체크:** `agent_app.py` 프로세스와 `15034` 포트 정상 작동 여부 확인 (실패 시 즉시 종료) [5].
* **리소스 임계치 경고:** CPU > 20%, Memory > 10%, Disk Used > 80% 초과 시 경고([WARNING]) 알림 발생 [6].
* **순환 로깅(Log Rotation):** 로그는 `/var/log/agent-app/monitor.log`에 기록되며, 무한 증식을 막기 위해 최대 10MB 크기로 10개의 파일만 유지되도록 보장합니다 [6].

### 3-2. 무인 자동화 (Crontab)
* `agent-admin` 계정의 crontab에 등록하여 매 1분마다 관제 스크립트가 백그라운드에서 자동 실행되도록 구축했습니다 [6].

---

## 4. 시작하기 (Quick Start)

### 4-1. 필수 환경 변수 및 키 파일 세팅
애플리케이션이 루트(Root) 권한 없이 안전하게 실행되도록 `.bash_profile`에 필수 환경 변수를 등록합니다 [7].
```bash
# 환경 변수 설정
export AGENT_HOME="/home/agent-admin/agent-app"
export AGENT_PORT=15034
export AGENT_UPLOAD_DIR="$AGENT_HOME/upload_files"
export AGENT_KEY_PATH="$AGENT_HOME/api_keys/t_secret.key"
export AGENT_LOG_DIR="/var/log/agent-app"
(참고: $AGENT_HOME/api_keys/t_secret.key 파일 내부에 agent_api_key_test 문자열이 1줄로 존재해야 앱이 정상 구동됩니다
.)
4-2. 무인 관제 자동화 등록
# agent-admin 계정에서 crontab -e 실행 후 아래 줄 추가
* * * * * /home/agent-admin/agent-app/bin/monitor.sh

--------------------------------------------------------------------------------
5. 요구사항 수행 결과 (증빙 자료)
5-1. 애플리케이션 정상 구동 (Boot Sequence)
비루트(Non-Root) 계정으로 실행 시 5단계 보안 및 환경 검증을 완벽히 통과합니다
.
> Starting Agent Boot Sequence...
[1/5] Checking User Account           [OK]
[2/5] Verifying Environment Variables [OK]
[3/5] Checking Required Files         [OK]
[4/5] Checking Port Availability      [OK]
[5/5] Verifying Log Permission        [OK]
All Boot Checks Passed!
Agent READY
5-2. 시스템 상태 수집 결과 (monitor.log)
관제 스크립트가 1분 단위로 수집한 시스템 리소스 로깅 결과입니다
.
[2026-05-10 13:58:01] PID:48291 CPU:10.2% MEM:3.2% DISK_USED:23%
[2026-05-10 13:59:01] PID:48291 CPU:18.7% MEM:5.0% DISK_USED:23%
[2026-05-10 14:00:01] PID:48291 CPU:25.3% MEM:9.8% DISK_USED:23%

--------------------------------------------------------------------------------
6. 트러블슈팅 및 배운 점
UFW 방화벽 차단 타임아웃 문제
상황: 기본 SSH 포트(22)를 20022로 변경한 후, UFW를 무작정 활성화(ufw enable)했다가 원격 접속이 끊어지는 상황 우려.
해결: UFW를 활성화하기 전에 반드시 새롭게 변경한 포트 번호(ufw allow 20022/tcp)를 가장 먼저 허용하는 순서를 준수하여 방화벽 적용 사고를 예방했습니다.
Cron 백그라운드 환경 변수 누락 현상
상황: 터미널에서 ./monitor.sh를 수동으로 쳤을 때는 잘 작동하지만, Crontab으로 자동 실행시킬 때는 경로(AGENT_HOME 등) 에러가 발생.
해결: Cron 데몬은 사용자의 기본 쉘 프로필을 로드하지 않고 빈 환경에서 실행된다는 리눅스 OS의 원리를 학습했습니다. 스크립트 최상단에 source ~/.bash_profile을 명시적으로 추가하여 백그라운드 환경에서도 변수들을 정상적으로 가져오도록 구조를 개선했습니다.

--------------------------------------------------------------------------------
📂 프로젝트 구조
.
├── bin/
│   └── monitor.sh       # 시스템 관제 자동화 스크립트 (권한: 750)
├── upload_files/        # 일반 공유 디렉토리 (agent-common R/W)
├── api_keys/            # 보안 키 관리 디렉토리 (agent-core 전용)
│   └── t_secret.key     # 앱 실행 필수 인증 키 
├── README.md            # 프로젝트 가이드 문서
└── report.sh            # (Bonus) 로그 통계 분석 리포트