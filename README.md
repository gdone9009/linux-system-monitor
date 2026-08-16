# 🛡️ 시스템 관제 자동화 및 보안 구축 프로젝트

## 1. 프로젝트 개요 (Overview)

### 1.1 목적 및 배경

본 프로젝트는 단순한 명령어 실행을 넘어, 실제 현업 엔지니어의 서버 운영 프로세스를 모델링하여 **보안-권한-관제-자동화 파이프라인**을 구축하는 데 목적이 있습니다. 서버 장애 발생 시 로그와 관제 데이터를 통해 원인을 즉각 분석하고, 외부 공격으로부터 서버를 요새화하는 전 과정을 구현합니다.

### 1.2 핵심 기술 및 수행 항목 (Core Tasks)

이번 미션에서는 안정적인 서버 관제 시스템 구축을 위해 다음 항목을 중심으로 연구 및 실습을 진행하였습니다.

* **서버 보안 및 네트워크 요새화 (Hardening)**
    * **SSH 포트 리스닝 변경:** 기본 포트(22)를 비표준 포트(20022)로 변경하여 봇(Bot)에 의한 자동 스캔 및 무차별 대입 공격(Brute-force) 방어
    * **접근 제어 강화:** Root 계정의 원격 접속(`PermitRootLogin no`)을 차단하고, UFW(Uncomplicated Firewall) 화이트리스트 정책을 통해 인가된 포트(`20022`, `15034`)만 개방

* **사용자 및 권한 체계 설계 (RBAC Design)**
    * **최소 권한 원칙(Least Privilege):** 운영(`admin`), 개발(`dev`), 테스트(`test`) 계정을 분리하여 업무 영역별 책임과 권한 한정
    * **그룹 기반 보안 정책:** `agent-core` 및 `agent-common` 그룹 설정을 통해 디렉토리 및 파일 단위의 정교한 접근 제어 구현
    * **자산 격리:** 민감 자산(API Key)과 시스템 로그 디렉토리를 물리적·논리적으로 격리하여 권한이 없는 계정의 접근을 원천 차단

* **시스템 관제 및 자동화 (Monitoring & Automation)**
    * **서비스 헬스체크:** `monitor.sh` 스크립트를 통해 프로세스(PID) 생존 여부와 서비스 포트 응답 상태를 실시간 감시 (비정상 시 `exit 1` 종료)
    * **리소스 메트릭 수집:** CPU, Memory, Disk 사용량을 수집하고, 설정된 임계치 초과 시 경고(`[WARNING]`)를 발생시키는 관제 로직 구현
    * **로깅 전략 수립:** `>>` 리다이렉션을 활용하여 데이터 누적 및 보존을 위한 표준 로깅 정책 적용 및 자체 10MB/10개 로그 로테이션 구현

* **무인 운영 파이프라인 구축 (Job Scheduling)**
    * **작업 스케줄링:** `Crontab`을 활용하여 1분 단위로 관제 스크립트를 자동 실행하고, 백그라운드 실행 시 환경 변수(`AGENT_HOME` 등) 누락 방지 최적화
    * **IaC(Infrastructure as Code) 지향:** 수동 설정을 배제하고 전체 구축 과정을 모듈형 쉘 스크립트(`01_env`, `02_security`, `03_user`, `04_cron`)로 자산화하여 환경 재현성 확보

### 1.3 핵심 엔지니어링 가치

* **보안 요새화(Hardening):** SSH 포트 변경 및 Root 접속 차단을 통한 공격 표면 최소화.
* **RBAC 설계:** 최소 권한 원칙에 따른 계정별 역할 분리 및 접근 제어.
* **무인 관제(Automation):** 스크립트와 Cron을 결합하여 인적 개입 없는 24/7 상태 감시 체계 구축.

---

## 2. 실행 환경 및 도구 (Environment & Tools)

### 2.1 하드웨어 및 OS 사양

* **Host Machine:** Intel-based iMac
* **Host OS:** macOS 15.7.4 (Sequoia)
* **Virtualization:** OrbStack (Intel x86_64 기반 경량 VM 및 Docker 엔진)
    * *선택 근거:* VirtualBox 대비 적은 리소스 점유율 및 고성능 커널 연동 지원
* **Guest OS:** Ubuntu 24.04 LTS (Noble Numbat)
    * *선택 근거:* 최신 보안 패치 라이프사이클 및 인프라 자동화 도구와의 높은 호환성

### 2.2 기술 스택 및 버전 (System Stack)

* **Infrastructure & Security:**
    * **Shell:** GNU bash (version 5.2.x) - 스크립트 표준 문법 준수
    * **Firewall:** UFW (Uncomplicated Firewall) - 인바운드 트래픽 제어 및 포트 화이트리스트 관리
    * **SSH Server:** OpenSSH Server (포트 20022 커스텀 설정)
* **Automation & Monitoring:**
    * **Scheduler:** Cron (Vixie Cron) - 1분 주기 무인 관제 자동화
    * **Monitoring Tools:** `procps` (top, ps), `iproute2` (ss), `df`, `free` 등 리눅스 표준 시스템 유틸리티
    * **Permissions:** ACL (Access Control Lists) - 그룹 단위의 정교한 디렉토리 접근 제어

### 2.3 환경 운영 및 보안 정책 (Operational Policy)

* **비루트(Non-Root) 최소 권한 정책:**
    * 애플리케이션(`agent-app`) 및 관제 스크립트(`monitor.sh`) 실행 시 루트 권한을 엄격히 배제함.
    * 특정 서비스 계정(`agent-admin`, `agent-dev`)을 활용하여 프로세스를 격리함으로써, 잠재적인 시스템 침해 사고 시 피해 범위를 해당 계정의 권한 내로 국한함.
* **환경 변수 자산화:**
    * `~/.bash_profile`을 통해 시스템 전역 환경 변수를 관리하여, 어떤 쉘 세션에서도 관제 경로(`AGENT_HOME`)와 포트 정보가 일관되게 유지되도록 설계함.

---

## 3. 수행 체크리스트 (Task Checklist)

### 3.1 단계별 마일스톤

**Step 1: 리눅스 기초 환경 구축 및 자산 초기화**
* [x] 시스템 패키지 최신화: apt update/upgrade 및 필수 도구(cron, ufw, acl, ssh) 일괄 설치
* [x] 관제 환경 변수 설계: `AGENT_HOME`, `AGENT_PORT` 등 전역 변수 등록
* [x] 디렉토리 구조 표준화: bin, api_keys, upload_files 등 역할별 물리적 저장소 생성

---

**Step 2: 보안 강화 및 네트워크 요새화 (Hardening)**
* [x] SSH 서비스 커스텀 설정: 기본 22번 포트 해제 및 20022 포트 전환, Root 원격 접속 차단
* [x] 방화벽(UFW) 화이트리스트 적용: 인가된 포트(20022, 15034) 외 모든 인바운드 트래픽 차단 정책 수립
* [x] 접근 제어 검증: 외부망에서의 불법 접속 시도 차단 및 신규 포트 접속 정상 여부 테스트

---

**Step 3: 계정 설계 및 RBAC 권한 체계 구축**
* [x] 용도별 계정/그룹 생성: admin, dev, test 계정 생성 및 agent-core/common 그룹 바인딩
* [x] 디렉토리별 권한 제어(ACL): 민감 디렉토리(api_keys, log)에 대한 agent-core 전용 권한 설정
* [x] 최소 권한 검증: test 계정으로 로그인하여 보안 디렉토리 접근 차단 상태 확인

---

**Step 4: 관제 로직(monitor.sh) 개발 및 고도화**
* [x] 헬스체크 로직 구현: 서비스 프로세스(PID) 존재 여부 및 네트워크 포트 응답 상태 확인 기능 (실패 시 exit 1)
* [x] 리소스 임계치 경보 설계: CPU(20%), MEM(10%), Disk(80%) 초과 시 로그 내 [WARNING] 발생 로직
* [x] 로깅 전략 적용: 로그 파일 크기 제한(10MB) 및 최대 10개 파일 유지(Log Rotation 개념) 적용

---

**Step 5: 무인 자동화 및 통합 운영 환경 등록**
* [x] Crontab 스케줄링 등록: agent-admin 권한으로 1분 단위 관제 스크립트 실행 스케줄 설정
* [x] 실행 환경 보정: Cron 백그라운드 환경 변수 로드 문제 해결을 위한 source 명령 보완
* [x] 통합 테스트 수트 구축: 전체 검증 항목을 한 번에 제어하고 상태를 확인하는 run_tests.sh 구성

### 3.2 작업 증적(Evidence) 매핑 테이블
| 대분류 | 중분류 항목 | 검증 도구/방법 | 상태 |
| :--- | :--- | :--- | :--- :
| **환경구축** | 패키지 및 환경변수 | `dpkg -l`, `printenv` | ✅ PASS |
| **보안강화** | SSH & UFW 설정 | `ss -tulnp`, `ufw status verbose` | ✅ PASS |
| **권한설계** | RBAC 및 계정 격리 | `id [User]`, `ls -ld` | ✅ PASS |
| **앱기동** | 5단계 부트 시퀀스 | `./agent-app` | ✅ PASS |
| **관제개발** | 리소스 모니터링 | `bash bin/monitor.sh` | ✅ PASS |
| **자동화** | Crontab 상시 가동 | `crontab -l`, `tail -n 5 monitor.log` | ✅ PASS |
| **보너스1** | 통계 리포트 생성 | `bash bin/report.sh` | ✅ PASS |
| **보너스2** | 시간 기반 로그 보존 | `bash bin/log_rotate_archive.sh` | ✅ PASS |

---

## 4. 프로젝트 아키텍처 및 구조 (Structure)

### 4.1 디렉토리 계층 구조 (Tree)

```text
.
├── MISSION_SPEC_B1_1.md        # 미션 공식 요구사항 명세서
├── EVALUATION_QUESTIONS_1_1.md # 평가 문항 4개 영역 19문항 모범 해설서
├── REQUIREMENTS_CHECKLIST.md   # 산출물 1: 공식 평가 항목 증적 체크리스트
├── DEMO_MANUAL_1_1.md          # 실시간 라이브 시연 매뉴얼
├── PRESENTATION_SCRIPT_1_1.md  # 구술 평가 발표 대본
├── manual.md                   # 초보자용 9부작 백과사전 교재
├── setup/                      # [Provisioning] 인프라 초기화 스크립트 모듈
│   ├── 01_env_setup.sh         # OS 환경 및 패키지 최적화
│   ├── 02_security_setup.sh    # SSH 하드닝 및 UFW 화이트리스트 구성
│   ├── 03_user_setup.sh        # RBAC 계정 설계 및 권한 격리
│   └── 04_cron_setup.sh        # 1분 주기 Cron 무인 관제 자동 등록
├── bin/                        # [Execution] 런타임 실행 바이너리 및 스크립트
│   ├── monitor.sh              # [산출물 2] 핵심 관제 엔진 (Resource & Health Check)
│   ├── report.sh               # (보너스 1) 로그 통계 분석 리포터
│   └── log_rotate_archive.sh   # (보너스 2) 시간 기반 로그 압축 및 보존 관리
├── api_keys/                   # [Security] 민감 정보 격리 (agent-core 전용 / 권한: 770)
│   └── t_secret.key            # 앱 구동 인증용 마스터 보안 키
├── /var/log/agent-app/         # [Logging] 시스템 운영 기록 (agent-core 소유 / 권한: 770)
│   ├── monitor.log             # 관제 메트릭 수집 및 경고 로그
│   └── alert_events.json       # 임계치 초과 이벤트 JSON 기록
├── upload_files/               # [Storage] 공용 업로드 데이터 저장소 (agent-common / 권한: 775)
├── tests/                      # [Testing] 무결성 검증 수트
│   └── run_tests.sh            # 8대 요구사항 자동화 검증 스크립트
└── README.md                   # 기술 문서
```

### 4.2 디렉토리 구조 설계 근거 (Design Rationale)

1. **설치 로직과 실행 로직의 분리 (Provisioning vs Execution)**:
   초기 인프라 구축 스크립트를 `setup/`으로 격리하고 상시 관제 스크립트는 `bin/`에 배치하여 환경 오염(Configuration Drift)을 원천 방지합니다.
2. **데이터 성격에 따른 권한 격리 (Access Control Enforcement)**:
   인증 키(`api_keys/`)와 로그(`/var/log/agent-app/`)는 `agent-core` 그룹(770)으로 한정하고, 협업 저장소(`upload_files/`)는 `agent-common` 그룹(775)으로 분리합니다.
3. **표준 로그 관리 체계 (Standardized Logging)**:
   리눅스 FHS 표준에 따라 가변 로그를 `/var/log/agent-app/monitor.log`에 중앙 집중 관리합니다.

---

## 5. 실행 및 자동화 가이드 (Implementation)

### 5.1 보안 강화 및 네트워크 요새화 (Hardening)

```bash
# 1. SSH 포트 20022 변경 및 Root 로그인 차단
sudo sed -i 's/^#*Port 22/Port 20022/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# 2. Ubuntu 24.04 systemd SSH 소켓 오버라이드
sudo mkdir -p /etc/systemd/system/ssh.socket.d
sudo bash -c "cat <<EOF > /etc/systemd/system/ssh.socket.d/listen.conf
[Socket]
ListenStream=
ListenStream=20022
EOF"

sudo systemctl daemon-reload
sudo systemctl restart ssh.socket
sudo systemctl restart ssh

# 3. UFW 방화벽 화이트리스트 정책 구성
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 20022/tcp
sudo ufw allow 15034/tcp
echo "y" | sudo ufw enable
```

### 5.2 계정 설계 및 RBAC 권한 체계 구축

```bash
# 1. 시스템 그룹 및 계정 생성
sudo groupadd -f agent-core
sudo groupadd -f agent-common

sudo useradd -m -s /bin/bash agent-admin
sudo useradd -m -s /bin/bash agent-dev
sudo useradd -m -s /bin/bash agent-test

# 2. 그룹 바인딩
sudo usermod -aG agent-common agent-admin
sudo usermod -aG agent-common agent-dev
sudo usermod -aG agent-common agent-test
sudo usermod -aG agent-core agent-admin
sudo usermod -aG agent-core agent-dev

# 3. 디렉토리 소유권 및 권한 설정
sudo chown -R agent-admin:agent-core $AGENT_HOME/api_keys
sudo chmod 770 $AGENT_HOME/api_keys

sudo mkdir -p /var/log/agent-app
sudo chown -R agent-admin:agent-core /var/log/agent-app
sudo chmod 770 /var/log/agent-app

sudo chown -R agent-admin:agent-common $AGENT_HOME/upload_files
sudo chmod 775 $AGENT_HOME/upload_files

sudo chown agent-dev:agent-core $AGENT_HOME/bin/monitor.sh
sudo chmod 750 $AGENT_HOME/bin/monitor.sh
```

### 5.3 애플리케이션 실행 환경 및 시크릿 키 설정

애플리케이션은 비루트 계정으로 구동되며, 사전 정의된 환경 변수와 시크릿 키 파일이 없으면 부트 시퀀스에서 즉시 중단됩니다.

```bash
# 1. 환경 변수 등록 (~/.bash_profile)
export AGENT_HOME="/home/agent-admin/agent-app"
export AGENT_PORT=15034
export AGENT_UPLOAD_DIR="$AGENT_HOME/upload_files"
export AGENT_KEY_PATH="$AGENT_HOME/api_keys/t_secret.key"
export AGENT_LOG_DIR="/var/log/agent-app"

# 2. 시크릿 키 생성 및 권한 설정
mkdir -p "$AGENT_HOME/api_keys"
echo "agent_api_key_test" | sudo tee "$AGENT_HOME/api_keys/t_secret.key" >/dev/null
sudo chown agent-admin:agent-core "$AGENT_HOME/api_keys/t_secret.key"
sudo chmod 660 "$AGENT_HOME/api_keys/t_secret.key"

# 3. 애플리케이션 기동 (agent-admin 계정)
./agent-app
```

### 5.4 시스템 관제 자동화 스크립트 (`bin/monitor.sh`) 실습 시연

`monitor.sh`는 3단계 파이프라인으로 동작합니다:
1. **Health Check**: 프로세스 및 포트 15034 리스닝 상태 확인 (실패 시 즉시 `exit 1` 및 에러 로그 기록).
2. **Resource Audit**: CPU%, MEM%, DISK 사용량 수집 및 임계치(`CPU > 20%`, `MEM > 10%`, `DISK > 80%`) 판정.
3. **Log & Rotation**: `/var/log/agent-app/monitor.log` 크기가 10MB 도달 시 순환(`monitor.log.1`~`10`) 및 최신 라인 `>>` 누적.

```bash
# 관제 스크립트 실행
bash bin/monitor.sh
```

### 5.5 Crontab 무인 관제 자동화 등록 (`setup/04_cron_setup.sh`)

`agent-admin` 계정의 Crontab에 1분 단위 스케줄을 자동 등록합니다.

```bash
# Crontab 자동 등록 스크립트 실행
bash setup/04_cron_setup.sh

# 등록된 스케줄 확인
crontab -l | grep monitor.sh
# 출력: * * * * * /home/agent-admin/agent-app/bin/monitor.sh >/dev/null 2>&1
```

---

## 6. 요구사항 수행 결과 및 검증 (Evidence)

### 6.1 SSH 보안 및 UFW 방화벽 검증
```bash
$ grep -E "^Port|^PermitRootLogin" /etc/ssh/sshd_config
Port 20022
PermitRootLogin no

$ sudo ufw status verbose
Status: active
Default: deny (incoming), allow (outgoing)
To                         Action      From
--                         ------      ----
20022/tcp                  ALLOW IN    Anywhere
15034/tcp                  ALLOW IN    Anywhere
```

### 6.2 계정 및 디렉토리 권한(RBAC) 검증
```bash
$ id agent-admin; id agent-dev; id agent-test
uid=1000(agent-admin) gid=1002(agent-admin) groups=1002(agent-admin),1000(agent-core),1001(agent-common)
uid=1001(agent-dev) gid=1003(agent-dev) groups=1003(agent-dev),1000(agent-core),1001(agent-common)
uid=1002(agent-test) gid=1004(agent-test) groups=1004(agent-test),1001(agent-common)

$ ls -ld $AGENT_HOME/api_keys /var/log/agent-app $AGENT_HOME/upload_files $AGENT_HOME/bin/monitor.sh
drwxrwx--- agent-admin agent-core api_keys
drwxrwx--- agent-admin agent-core /var/log/agent-app
drwxrwxr-x agent-admin agent-common upload_files
-rwxr-x--- agent-dev   agent-core bin/monitor.sh
```

### 6.3 애플리케이션 Boot Sequence 5단계 [OK] & Agent READY 검증
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

### 6.4 `monitor.sh` 실시간 관제 및 `monitor.log` 시계열 누적 검증
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

$ sudo tail -n 5 /var/log/agent-app/monitor.log
[2026-08-16 17:21:56] [INFO] PID:4844 CPU:0.1% MEM:0.0% DISK_USED:1%
[2026-08-16 17:32:49] [INFO] PID:4844 CPU:0.0% MEM:0.0% DISK_USED:1%
[2026-08-16 17:33:01] [INFO] PID:4844 CPU:0.0% MEM:0.0% DISK_USED:1%
[2026-08-16 17:34:01] [INFO] PID:4844 CPU:0.0% MEM:0.0% DISK_USED:1%
```

### 6.5 보너스 과제 2종 검증

#### [보너스 1] 통계 리포트 자동 생성 (`bin/report.sh`)
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

#### [보너스 2] 시간 기반 로그 보존/삭제 정책 (`bin/log_rotate_archive.sh`)
```text
$ bash bin/log_rotate_archive.sh
📦 [LOG ARCHIVE] 시간 기반 로그 아카이브 및 삭제 정책 프로세스를 시작합니다...
ℹ️ [INFO] 유저 아카이브 경로로 자동 전환되었습니다 (/var/log/agent-app/archive).
ℹ️ [INFO] 7일 이상 경과된 압축 대상 로그 파일이 없습니다.
ℹ️ [INFO] 30일 이상 경과된 삭제 대상 아카이브 파일이 없습니다.
✅ [LOG ARCHIVE] 아카이브 및 보존 정책 처리가 안전하게 완료되었습니다.
```

---

## 7. 트러블슈팅 및 배운 점 (Troubleshooting)

### 💡 7.1 시크릿 키 미설정 및 경로/권한 불일치 오류
* **상황**: `./agent-app` 실행 시 `[3/5] Checking Required Files [FAIL] >>> Key file not found` 에러가 발생하며 프로세스가 중단됨.
* **원인**: `$AGENT_KEY_PATH` 환경 변수가 누락되었거나, `$AGENT_HOME/api_keys/t_secret.key` 파일이 존재하지 않고 권한이 `agent-core` 그룹에 부여되지 않아 발생.
* **해결**: `$AGENT_HOME/api_keys/t_secret.key`에 필수 인증 문자열(`agent_api_key_test`)을 생성하고, 디렉토리를 `770`(`agent-admin:agent-core`), 키 파일을 `660`으로 설정한 뒤 `export AGENT_KEY_PATH`를 등록하여 `[3/5] [OK]` 통과를 완료함.

### 💡 7.2 UFW 방화벽 차단 타임아웃 문제
* **상황**: 기본 SSH 포트(22)를 20022로 변경한 후, UFW를 무작정 활성화(`ufw enable`)했다가 원격 접속이 끊어지는 상황 우려.
* **해결**: UFW를 활성화하기 전에 반드시 새롭게 변경한 포트 번호(`ufw allow 20022/tcp`)를 가장 먼저 허용하는 순서를 준수하여 방화벽 적용 사고를 예방함.

### 💡 7.3 Cron 백그라운드 환경 변수 누락 현상
* **상황**: 터미널에서 `monitor.sh`를 수동 실행했을 때는 잘 작동하지만, Crontab으로 자동 실행시킬 때는 경로(`AGENT_HOME` 등) 에러 발생.
* **원인**: Cron 데몬은 사용자의 기본 쉘 프로필을 로드하지 않고 빈 환경에서 실행된다는 리눅스 OS의 원리 때문임.
* **해결**: 스크립트 최상단에 `source ~/.bash_profile 2>/dev/null`을 명시적으로 추가하고, 기본 로그 디렉토리를 `/var/log/agent-app`으로 Fallback 처리하여 백그라운드 환경에서도 변수들을 정상 로드하도록 구조를 개선함.

### 💡 7.4 최신 Ubuntu 24.04의 SSH 소켓 액티베이션 이슈
* **상황**: `/etc/ssh/sshd_config` 수정 후에도 서비스가 계속 22번 포트로 실행됨.
* **원인**: `systemd`의 `ssh.socket` 설정이 `sshd_config` 설정을 덮어쓰기 때문임.
* **해결**: `/etc/systemd/system/ssh.socket.d/listen.conf` 파일을 생성하여 소켓 리스닝 포트를 20022로 강제 지정 후 `daemon-reload`를 통해 해결함.

### 💡 7.5 비루트 계정에서의 UFW 점검 sudo 패스워드 오류 방지
* **상황**: 일반 계정(`agent-admin`)이 `sudo ufw status`를 호출할 때 sudo 패스워드 미입력 오류가 `/var/log/auth.log`에 남음.
* **해결**: `monitor.sh` 내에서 `/etc/ufw/ufw.conf` 파일(`ENABLED=yes`)을 직접 검사하고 `sudo -n`을 활용하여 패스워드 프롬프트 없이도 방화벽 상태를 안전하게 판별하도록 로직을 개선함.

### 💡 7.6 타 사용자 홈 디렉토리 내 스크립트 실행 불가 이슈
* **상황**: `agent-admin` 계정으로 타 계정 홈 디렉토리의 스크립트 실행 시 `Permission denied` 발생.
* **원인**: 리눅스 보안 정책상 상위 디렉토리에 대한 실행(x) 권한이 없으면 내부 파일에 접근할 수 없음.
* **해결**: 스크립트를 공용 실행 경로(`~/agent-app/bin`)로 복사 후 소유자 및 권한을 재설정하여 해결.

### 💡 7.7 교차 플랫폼(macOS/Linux) 환경 실행 및 호환성 이슈
* **상황**: macOS 및 미니멀 Linux 배포판에서 스크립트 실행 시 `stat` 명령어 인자 오류 및 `ss` 부재 발생.
* **원인**: BSD(macOS)와 GNU(Linux)의 `stat` 포맷 차이 및 미니멀 배포판의 `iproute2` 패키지 누락.
* **해결**: 스크립트 내부에서 `stat -c%s`와 `stat -f%z`를 분기 처리하고, `ss` 없을 시 `netstat`으로 자동 Fallback 구현.

---

## 8. 기술적 제언 및 향후 과제 (Insights)

### 8.1 로그 순환(Rotation) 정책 내재화 완료
* 기존에는 외부 `logrotate` 도구에 의존하는 방향을 검토하였으나, 스크립트 런타임에 직접 파일 크기(10MB) 및 백업 순환(최대 10개 파일) 로직을 내재화하여 단일 스크립트 배포만으로도 디스크 오버헤드를 완벽히 방어할 수 있도록 고도화함.

### 8.2 알림 시스템 연동
* 리소스 임계치 초과(`WARNING`) 시 로그 기록에 그치지 않고, Webhook을 활용하여 슬랙(Slack)이나 이메일로 즉시 알림을 발송하는 파이프라인 확장이 가능함.

---

## 9. 제출 및 주요 산출물 (Submission)

### 9.1 최종 제출 결과물
* **핵심 관제 엔진:** `bin/monitor.sh` (리소스 수집, 헬스체크 및 자체 로그 로테이션 지원)
* **인프라 셋업 스크립트:** `setup/01_env_setup.sh`, `setup/02_security_setup.sh`, `setup/03_user_setup.sh`, `setup/04_cron_setup.sh`
* **보너스 스크립트:** `bin/report.sh` (통계 리포트), `bin/log_rotate_archive.sh` (시간 기반 아카이브)
* **기술 문서:** `README.md` (본 기술 문서), `MISSION_SPEC_B1_1.md`, `EVALUATION_QUESTIONS_1_1.md`

---

## 10. 🎓 초보 개발자를 위한 리눅스 시스템 관제 핵심 개념 완전 해설서

### 💡 10.1 필수 핵심 개념 용어집 (Glossary)

1. **Bash 쉘 (Bash Shell)**: 리눅스 운영체제와 사용자가 대화하는 '명령어 해석기'입니다. 스크립트 상단의 `#!/bin/bash`는 Bash 프로그램으로 해석하라는 선언입니다.
2. **Cron 스케줄러 (Crontab)**: 리눅스에서 24시간 365일 무인으로 정해진 시간(예: 1분마다) 명령어를 자동으로 실행해 주는 유틸리티입니다.
3. **SSH 포트 변경 (Security Hardening)**: SSH 기본 22번 포트를 비표준 포트(20022)로 바꾸어 외부 공격 시도 자체를 99% 차단하는 1차 방어선입니다.
4. **RBAC & 최소 권한 원칙**: 사용자마다 역할을 분리(`admin`, `dev`, `test`)하고 필요 최소한의 권한만 부여하여 침해 사고 시 피해를 국한합니다.
5. **Log Rotation**: 로그 파일이 10MB에 도달하면 `monitor.log.1`~`10`으로 밀어내고 노후 로그를 삭제하여 디스크를 보호하는 기술입니다.
6. **Awk 유틸리티**: 대용량 로그 파일에서 특정 컬럼의 수치 데이터를 뽑아내어 평균, 최댓값, 최솟값을 고속으로 연산하는 텍스트 처리 언어입니다.

### 🔍 10.2 관제 스크립트(`monitor.sh`) 3단계 작동 흐름 해설

```text
[1단계: Health Check] ──> 실패 시: ERROR 로그 기록 ➡️ exit 1 (즉시 비정상 종료)
         │ 성공
         ▼
[2단계: Resource Audit] ──> 프로세스 CPU%, MEM%, 디스크 사용률 수집 (임계치 초과 시 [WARNING])
         │
         ▼
[3단계: Log & Rotation] ──> 10MB 초과 시 파일 시프트(Rotate) ➡️ monitor.log 누적 ➡️ exit 0
```