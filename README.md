# 🛡️ 시스템 관제 자동화 및 보안 구축 프로젝트 (B1-1)

| 항목 | 상세 정보 |
| :--- | :--- |
| **학습 단계** | AI/SW 기초 (AI/SW Basic) |
| **학습 주제** | Linux와 OS (Linux & OS) |
| **미션 과제명** | **컴퓨터가 알아서 자기 상태를 점검하게 만들기** |
| **작성자 (탐험가명)** | 정창석 (`gdone9009`) |
| **프로젝트 URL** | [https://github.com/gdone9009/linux-system-monitor](https://github.com/gdone9009/linux-system-monitor) |
| **대상 브랜치** | `main` |
| **요구사항 충족도** | **8/8 필수 항목 PASS (100%) + 보너스 2종 완수** |

---

## 📚 프로젝트 핵심 문서 바로가기

* 📋 **[미션 공식 명세서 (MISSION_SPEC_B1_1.md)](MISSION_SPEC_B1_1.md)**: 미션 배경, 기능 요구사항, 제약사항 및 테스트 케이스 기준
* ❓ **[평가 문항 & 완벽 해설서 (EVALUATION_QUESTIONS_1_1.md)](EVALUATION_QUESTIONS_1_1.md)**: 4개 평가 영역(총 19문항)에 대한 실전 검증 증적 및 모범 답변서
* 📄 **[요구사항 수행 내역서 (REQUIREMENTS_CHECKLIST.md)](REQUIREMENTS_CHECKLIST.md)**: [산출물 1] 8대 공식 평가 항목 증적 체크리스트 (100% 통과)
* 🎬 **[실전 시연 매뉴얼 (DEMO_MANUAL_1_1.md)](DEMO_MANUAL_1_1.md)**: 라이브 데모 5단계 실행 명령어 및 기술 배경
* 🎤 **[구조화 발표 스크립트 (PRESENTATION_SCRIPT_1_1.md)](PRESENTATION_SCRIPT_1_1.md)**: 구술 평가용 대본 및 심층 Q&A 대응 가이드
* 📖 **[초보자용 9부작 백과사전 교재 (manual.md)](manual.md)**: OS 원리부터 네트워크 보안, Awk 파싱까지 완전 해설

---

## 1. 프로젝트 개요 (Overview)

### 1.1 목적 및 배경
본 프로젝트는 단순한 리눅스 명령어 실행을 넘어, 실제 현업 엔지니어의 서버 운영 프로세스를 모델링하여 **보안(Hardening) - 권한(RBAC) - 관제(Monitoring) - 무인 자동화(Automation) 파이프라인**을 구축하는 데 목적이 있습니다. 

서버 장애 발생 시 로그가 없으면 원인 분석이 불가능해지므로, 프로세스/포트 헬스체크와 시스템 자원(CPU, MEM, DISK)을 주기적으로 계측하여 시계열 데이터로 보존하고, 디스크 풀(Full)을 방지하는 자체 로그 로테이션 및 아카이브 생명주기 정책을 구현합니다.

### 1.2 핵심 엔지니어링 4대 원칙
1. **보안 요새화 (Hardening)**: 비표준 SSH 포트(`20022`) 전환 및 Root 원격 접속 차단, UFW 최소 화이트리스트 개방으로 공격 표면(Attack Surface) 최소화.
2. **최소 권한 원칙 (Least Privilege & RBAC)**: 운영(`admin`), 개발(`dev`), 테스트(`test`) 역할 분리 및 그룹(`agent-core`, `agent-common`) 단위의 엄격한 자산 격리.
3. **무인 관제 자동화 (Automation)**: `monitor.sh`와 `Crontab`을 결합하여 인적 개입 없이 24/7 장애 탐지 및 리소스 추세 로깅.
4. **인프라 코드화 (IaC)**: 수동 설정 없이 멱등성(Idempotency)이 보장된 쉘 스크립트(`setup/*.sh`)로 환경 재현성 100% 확보.

---

## 2. 주요 시스템 설계 및 아키텍처 (Architecture)

### 2.1 보안 및 네트워크 요새화 (Security Hardening)
외부 침입 시도를 차단하고 허가된 통로만 이용하도록 서버를 요새화했습니다.
* **SSH 포트 20022 전환 & Root 원격 차단**: 
  * 기본 22번 포트를 비표준 포트 `20022`로 변경하여 인터넷 자동 공격 봇의 스캔을 99% 차단.
  * `/etc/ssh/sshd_config` 내 `PermitRootLogin no` 설정으로 최고 권한자의 직접 침입을 봉쇄하고 `sudo`를 통한 감사 추적성(Audit Trail) 강제.
  * 최신 Ubuntu 24.04 LTS의 systemd 소켓 활성화 방식에 대응하여 `/etc/systemd/system/ssh.socket.d/listen.conf` 오버라이드 적용.
* **UFW 방화벽 화이트리스트**: 
  * 기본 정책 `default deny incoming`을 적용하여 인바운드 트래픽을 전면 차단.
  * 관리용 `20022/tcp`(SSH)와 서비스용 `15034/tcp`(APP) 2개 포트만 명시적 개방(`ALLOW IN`).

### 2.2 계정 및 RBAC 권한 체계 (RBAC Design)
최소 권한 원칙에 따라 사용자 계정과 그룹을 분리하고 디렉토리별 접근 권한을 엄격히 격리하였습니다.

| 계정/그룹 | 유형 | 소속 그룹 | 권한 및 역할 설명 |
| :--- | :---: | :--- | :--- |
| **`agent-admin`** | 계정 | `agent-core`, `agent-common` | **시스템 운영자**: 인프라 관리 및 Cron 무인 관제 실행자 |
| **`agent-dev`** | 계정 | `agent-core`, `agent-common` | **개발자**: 관제 스크립트(`bin/monitor.sh`) 소유자 및 작성자 |
| **`agent-test`** | 계정 | `agent-common` | **테스터**: QA용 제한 계정 (보안 자산 접근 불가) |
| **`agent-core`** | 그룹 | `agent-admin`, `agent-dev` | **보안 핵심 그룹**: `api_keys/` 및 `log/` 디렉토리 전용 접근 권한 |
| **`agent-common`**| 그룹 | `admin`, `dev`, `test` 모두 | **공용 그룹**: `upload_files/` 협업 디렉토리 접근 권한 |

#### 디렉토리 권한 정책:
* `$AGENT_HOME/api_keys` 및 `/var/log/agent-app`: `770` (`drwxrwx---`, 소유: `agent-admin:agent-core`) ➔ **`agent-test` 및 외부 계정 접근 원천 차단**
* `$AGENT_HOME/upload_files`: `775` (`drwxrwxr-x`, 소유: `agent-admin:agent-common`) ➔ 모든 그룹원 R/W 협업 허용
* `$AGENT_HOME/bin/monitor.sh`: `750` (`-rwxr-x---`, 소유: `agent-dev:agent-core`) ➔ 개발자는 수정/실행(`rwx`), 관리자는 실행만 허용(`r-x`)하여 **코드 무결성 보호**

---

## 3. 핵심 자동화 기능 (Monitoring, Cron & Retention)

### 3.1 관제 스크립트 (`bin/monitor.sh`)
백그라운드에서 실행되는 애플리케이션의 상태와 시스템 리소스를 정밀 감시합니다.
1. **Health Check (치명적 장애 시 `exit 1` 종료)**:
   * `pgrep`을 통해 `agent_app.py` 및 실행 바이너리 `agent-app` 생존 여부 확인.
   * `ss -tuln` (Fallback: `netstat -an`)으로 `15034` TCP 포트의 `LISTEN` 수신 대기 상태 확인.
   * 서비스가 죽어있으면 에러 로그를 남기고 즉시 `exit 1`로 종료하여 빠른 장애 통보 유도.
2. **상태 점검 (경고 출력 후 관제 지속)**:
   * UFW 및 firewalld 방화벽 활성화 상태 점검. 비활성 시 `[WARNING]`을 출력하되 스크립트는 중단하지 않음.
3. **자원 수집 및 임계치 판정**:
   * `ps -p $PID -o %cpu= -o %mem=` 및 `df -P /`를 통해 CPU%, MEM%, DISK 사용률 추출.
   * Awk 기반 실수(Float) 연산으로 임계치 초과 판정:
     * `CPU > 20.0%`: `[WARNING]` 발생
     * `MEM > 10.0%`: `[WARNING]` 발생
     * `DISK_USED > 80%`: `[WARNING]` 발생
4. **자체 용량 관리 (In-Script Log Rotation)**:
   * `/var/log/agent-app/monitor.log` 크기를 측정하여 `10MB (10,485,760 bytes)` 도달 시 `monitor.log.1` ~ `monitor.log.10`으로 시프트(Shift)하고 10개 초과분은 자동 삭제.

### 3.2 무인 자동화 스케줄링 (Crontab)
* `agent-admin` 계정의 Crontab에 `* * * * * /home/agent-admin/agent-app/bin/monitor.sh >/dev/null 2>&1` 스케줄을 등록.
* Cron 실행 환경의 독립성 문제를 해결하기 위해 스크립트 내부에서 `source ~/.bash_profile`을 로드하고 `/var/log/agent-app` 경로를 기본값으로 자동 보정하여 24/7 무인 자동 로깅 실현.

### 3.3 보너스 자동화 과제
1. **통계 리포터 (`bin/report.sh`)**:
   * `monitor.log`를 고성능 Awk 엔진으로 파싱하여 CPU 및 Memory의 **평균(Average), 최대값(Maximum 및 시각), 최소값(Minimum 및 시각), 총 수집 샘플 수(Data Points)**를 규격 양식으로 자동 집계.
2. **시간 기반 로그 보존 정책 (`bin/log_rotate_archive.sh`)**:
   * `find -mtime +7`로 7일 이상 경과된 로그를 `gzip` 압축 후 `/var/log/agent-app/archive/`로 이동.
   * `find -mtime +30`으로 보존 기한이 지난 30일 경과 `.gz` 아카이브 파일을 자동 영구 삭제하여 디스크 용량 보호.

---

## 4. 시작하기 (Quick Start & Setup)

### 4.1 인프라 환경 변수 및 시크릿 키 세팅
애플리케이션이 루트(Root) 권한 없이 안전하게 실행되도록 환경 변수와 필수 보안 키를 등록합니다.

```bash
# 1. 환경 변수 설정 (~/.bash_profile)
export AGENT_HOME="/home/agent-admin/agent-app"
export AGENT_PORT=15034
export AGENT_UPLOAD_DIR="$AGENT_HOME/upload_files"
export AGENT_KEY_PATH="$AGENT_HOME/api_keys/t_secret.key"
export AGENT_LOG_DIR="/var/log/agent-app"

# 2. 필수 시크릿 키 생성 및 권한 부여
mkdir -p "$AGENT_HOME/api_keys"
echo "agent_api_key_test" | sudo tee "$AGENT_HOME/api_keys/t_secret.key" >/dev/null
sudo chown -R agent-admin:agent-core "$AGENT_HOME/api_keys"
sudo chmod 770 "$AGENT_HOME/api_keys"
sudo chmod 660 "$AGENT_HOME/api_keys/t_secret.key"
```

### 4.2 인프라 자동화 스크립트 일괄 실행
```bash
# 1. 시스템 환경 및 패키지 구축
bash setup/01_env_setup.sh

# 2. SSH 포트 20022 변경 및 UFW 방화벽 화이트리스트 적용
sudo bash setup/02_security_setup.sh

# 3. RBAC 계정, 그룹 및 디렉토리 권한 격리 적용
sudo bash setup/03_user_setup.sh

# 4. 1분 주기 Cron 무인 관제 스케줄러 등록
bash setup/04_cron_setup.sh
```

---

## 5. 요구사항 수행 결과 및 실습 시연 증빙 (Evidence)

### 5.1 애플리케이션 정상 구동 (Boot Sequence 5단계 [OK] & Agent READY)
`agent-admin` 일반 계정으로 실행 시 5단계 부트 검증을 모두 `[OK]`로 완벽히 통과합니다.

```text
$ ./agent-app
>>> Starting Agent Boot Sequence...
[1/5] Checking User Account               [OK]
 ... Running as service user 'agent-admin' (uid=1000)
[2/5] Verifying Environment Variables     [OK]
 ... All required Envs correct
[3/5] Checking Required Files             [OK]
 ... Verified 'secret.key' with correct key string.
[4/5] Checking Port Availability          [OK]
 ... Port 15034 is available.
[5/5] Verifying Log Permission            [OK]
 ... Log directory is writable: /var/log/agent-app
------------------------------------------------------------
All Boot Checks Passed!
Agent READY
2026-08-16 17:21:09 [INFO] Agent listening at port 15034
```

### 5.2 `monitor.sh` 실시간 관제 및 헬스체크 시연
```text
$ bash bin/monitor.sh
====== SYSTEM MONITOR START ======
[HEALTH CHECK]
Checking process 'agent-app'... [OK] (PID: 4844)
Checking port 15034... [OK]
Checking Firewall... [OK]

[RESOURCE MONITORING]
Process CPU Usage: 0.1%
Process MEM Usage: 0.0%
System DISK Used: 1%
[INFO] Log appended: /var/log/agent-app/monitor.log
====== SYSTEM MONITOR END ======
```

### 5.3 `monitor.log` 시계열 누적 기록 확인
`>>` 리다이렉션을 통해 표준 포맷으로 매분 누적 기록되는 실제 로그 데이터입니다.

```text
$ sudo tail -n 5 /var/log/agent-app/monitor.log
[2026-08-16 17:21:56] [INFO] PID:4844 CPU:0.1% MEM:0.0% DISK_USED:1%
[2026-08-16 17:32:49] [INFO] PID:4844 CPU:0.0% MEM:0.0% DISK_USED:1%
[2026-08-16 17:33:01] [INFO] PID:4844 CPU:0.0% MEM:0.0% DISK_USED:1%
[2026-08-16 17:34:01] [INFO] PID:4844 CPU:0.0% MEM:0.0% DISK_USED:1%
```

### 5.4 Crontab 무인 1분 주기 자동화 실습 검증
```text
$ crontab -l | grep monitor.sh
* * * * * /home/agent-admin/agent-app/bin/monitor.sh >/dev/null 2>&1
```

### 5.5 보너스 과제 실행 결과

#### [보너스 1] 통계 리포트 생성 (`bin/report.sh`)
```text
$ bash bin/report.sh
====== STATISTICS REPORT ======
[CPU]
Average : 0.0%
Maximum : 0.1% at 2026-08-16 17:21:56
Minimum : 0.0% at 2026-08-16 17:32:49
[Memory]
Average : 0.0%
Maximum : 0.0% at 2026-08-16 17:21:56
Minimum : 0.0% at 2026-08-16 17:21:56
[Samples]
Data Points: 4 samples
====== END OF REPORT ======
```

#### [보너스 2] 시간 기반 아카이브 및 삭제 (`bin/log_rotate_archive.sh`)
```text
$ bash bin/log_rotate_archive.sh
📦 [LOG ARCHIVE] 시간 기반 로그 아카이브 및 삭제 정책 프로세스를 시작합니다...
ℹ️ [INFO] 유저 아카이브 경로로 자동 전환되었습니다 (/var/log/agent-app/archive).
ℹ️ [INFO] 7일 이상 경과된 압축 대상 로그 파일이 없습니다.
ℹ️ [INFO] 30일 이상 경과된 삭제 대상 아카이브 파일이 없습니다.
✅ [LOG ARCHIVE] 아카이브 및 보존 정책 처리가 안전하게 완료되었습니다.
```

---

## 6. 트러블슈팅 및 배운 점 (Troubleshooting & Lessons Learned)

### 💡 6.1 시크릿 키 미설정 및 경로/권한 불일치 오류
* **상황**: `./agent-app` 실행 시 `[3/5] Checking Required Files [FAIL] >>> Key file not found` 에러가 발생하며 프로세스가 중단됨.
* **원인**: `$AGENT_KEY_PATH` 환경 변수가 누락되었거나, `$AGENT_HOME/api_keys/t_secret.key` 파일이 존재하지 않고 권한이 `agent-core` 그룹에 부여되지 않아 발생.
* **해결**: `$AGENT_HOME/api_keys/t_secret.key`에 필수 인증 문자열(`agent_api_key_test`)을 1줄로 생성하고, 디렉토리를 `770`(`agent-admin:agent-core`), 키 파일을 `660`으로 설정한 뒤 `export AGENT_KEY_PATH`를 등록하여 `[3/5] [OK]` 통과를 완료함.

### 💡 6.2 UFW 방화벽 활성화 시 원격 세션 단절 방지
* **상황**: 기본 SSH 포트(22)를 20022로 변경한 후, UFW를 무작정 활성화(`ufw enable`)하면 본인의 SSH 접속이 즉각 차단될 위험이 있음.
* **해결**: `ufw enable`을 수행하기 전에 반드시 `sudo ufw allow 20022/tcp` 및 `15034/tcp`를 선제 허용하는 실행 순서를 강제하여 방화벽 고립 사고를 완벽히 예방함.

### 💡 6.3 Cron 백그라운드 환경 변수 누락 현상
* **상황**: 터미널에서는 정상 동작하던 `monitor.sh`가 Cron으로 자동 실행될 때 `AGENT_HOME` 등 경로 변수를 찾지 못해 실패함.
* **원인**: Cron 데몬은 사용자의 로그인 쉘 환경(`.bash_profile`)을 로드하지 않고 최소한의 비대화형 환경에서만 실행됨.
* **해결**: `monitor.sh` 최상단에 `source ~/.bash_profile 2>/dev/null`을 명시적으로 선언하고, 기본 로그 경로를 `/var/log/agent-app`으로 Fallback 처리하여 해결.

### 💡 6.4 최신 Ubuntu 24.04의 SSH 소켓 액티베이션 이슈
* **상황**: `/etc/ssh/sshd_config`의 포트를 `20022`로 변경했음에도 SSH 데몬이 계속 22번 포트로 수신 대기함.
* **원인**: systemd의 `ssh.socket` 유닛이 `sshd_config` 파일의 설정을 덮어쓰기 때문임.
* **해결**: `/etc/systemd/system/ssh.socket.d/listen.conf` 파일을 생성하여 `ListenStream=20022`를 오버라이드하고 데몬을 리로드하여 20022 포트 전환을 완료함.

### 💡 6.5 비루트(Non-Root) 계정에서의 UFW 및 프로세스 조회 권한
* **상황**: 일반 계정(`agent-admin`)이 `sudo ufw status`를 호출할 때 sudo 패스워드 인증 실패 로그가 `/var/log/auth.log`에 남음.
* **해결**: `monitor.sh` 내에서 `/etc/ufw/ufw.conf` 파일(`ENABLED=yes`)을 직접 검사하고 `sudo -n`을 활용하여 패스워드 프롬프트 없이도 방화벽 상태를 안전하게 판별하도록 로직을 개선함.

---

## 7. 프로젝트 디렉토리 구조 및 통합 검증 수트

### 7.1 디렉토리 구조 (Tree)
```text
.
├── .gitignore                      # Git 관리 제외 파일 (.DS_Store 등)
├── MISSION_SPEC_B1_1.md            # 미션 공식 명세서 및 기능 요구사항
├── EVALUATION_QUESTIONS_1_1.md     # 평가 문항 4개 영역 19문항 모범 답변서
├── REQUIREMENTS_CHECKLIST.md       # [산출물 1] 공식 평가 항목 증적 체크리스트
├── DEMO_MANUAL_1_1.md              # 실전 라이브 시연 매뉴얼
├── PRESENTATION_SCRIPT_1_1.md      # 구술 평가 발표 대본
├── manual.md                       # 초보자용 9부작 백과사전 교재
├── README.md                       # 프로젝트 종합 기술 백서 (본 문서)
├── agent-app                       # 관제 대상 애플리케이션 바이너리
├── agent-app.zip                   # 애플리케이션 원본 배포 압축 파일
├── setup/                          # 인프라 자동화 스크립트 모듈
│   ├── 01_env_setup.sh             # 환경 변수 및 패키지 설치
│   ├── 02_security_setup.sh        # SSH 포트(20022) & UFW 요새화
│   ├── 03_user_setup.sh            # RBAC 계정 및 ACL 권한 격리
│   └── 04_cron_setup.sh            # 1분 주기 Cron 무인 관제 등록
├── bin/                            # 런타임 관제 및 분석 도구
│   ├── monitor.sh                  # [산출물 2] 핵심 관제 엔진 (권한: 750)
│   ├── report.sh                   # (보너스 1) 로그 통계 분석 리포터
│   └── log_rotate_archive.sh       # (보너스 2) 시간 기반 로그 보존/삭제
├── api_keys/                       # [보안 격리] agent-core 전용 (권한: 770)
│   └── t_secret.key                # 앱 인증 마스터 키 (내용: agent_api_key_test)
└── tests/                          # 통합 무결성 테스트 수트
    └── run_tests.sh                # 8대 요구사항 자동화 검증 스크립트
```

### 7.2 통합 테스트 수트 실행 (`tests/run_tests.sh`)
```bash
./tests/run_tests.sh
```
```text
====== INTEGRATED MISSION TEST SUITE START ======
✅ [PASS] 모든 Bash 스크립트 문법 검사 (bash -n)
✅ [PASS] 필수 디렉터리 구조 검증 (/home/gdone90098008/agent-app 및 로그 디렉터리)
✅ [PASS] 인증 키 파일 가상 검증 (테스트용 키 파일 정상 구성 확인)
✅ [PASS] 관제 스크립트 실행 권한 및 위치 (bin/monitor.sh)
✅ [PASS] 보너스 1: 통계 리포트 스크립트 (bin/report.sh)
✅ [PASS] 보너스 2: 시간 기반 로그 아카이브 스크립트 (bin/log_rotate_archive.sh)
✅ [PASS] Cron 무인 관제 자동 등록 스크립트 (setup/04_cron_setup.sh)
--------------------------------------------------
📊 [테스트 요약 결과]
  - 성공 (PASS): 7
  - 실패 (FAIL): 0
====== INTEGRATED MISSION TEST SUITE END ======
```