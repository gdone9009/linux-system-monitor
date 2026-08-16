# 📋 B1-1 시스템 관제 및 보안 평가 문항 & 완벽 해설서

> **평가 영역**: B1-1 시스템 관제 자동화 및 보안 구축 프로젝트  
> **문서 목적**: 실무 평가 문항 4개 영역(총 19문항)에 대한 표준 질문과 심층 모범 답변, 검증 명령어 및 엔지니어링 근거 총정리  
> **작성자**: gdone9009  

---

## 📌 목차 (Table of Contents)

- [항목 1. 실무 기능 동작 및 증적 검증 (8문항)](#항목-1-실무-기능-동작-및-증적-검증-8문항)
- [항목 2. 스크립트 설계 및 구현 심층 설명 (4문항)](#항목-2-스크립트-설계-및-구현-심층-설명-4문항)
- [항목 3. 보안 아키텍처 및 운영 철학 (4문항)](#항목-3-보안-아키텍처-및-운영-철학-4문항)
- [항목 4. 장애 트러블슈팅 및 확장 시나리오 대응 (3문항)](#항목-4-장애-트러블슈팅-및-확장-시나리오-대응-3문항)

---

## 🛠️ 항목 1. 실무 기능 동작 및 증적 검증 (8문항)

### Q1.1. SSH 포트가 20022로 변경되었고, Root 원격 접속이 차단되었는가?

#### 🎯 검증 명령어 및 증적 (Evidence)
```bash
# 1. SSH 설정 파일(/etc/ssh/sshd_config) 파라미터 확인
grep -E "^Port|^PermitRootLogin" /etc/ssh/sshd_config
```
```text
Port 20022
PermitRootLogin no
```

```bash
# 2. 실제 네트워크 레이어 20022 포트 LISTEN 상태 확인
sudo ss -tulnp | grep 20022
```
```text
tcp   LISTEN 0      4096         *:20022            *:*    users:(("sshd",pid=...,fd=...))
```

#### 💡 모범 답변 및 해설
* `setup/02_security_setup.sh` 스크립트를 통해 `sshd_config`의 기본 포트를 `20022`로 전환하고 `PermitRootLogin no`를 적용했습니다.
* 최신 Ubuntu 24.04 LTS의 systemd 소켓 활성화 방식에 대응하기 위해 `/etc/systemd/system/ssh.socket.d/listen.conf` 오버라이드 설정을 적용하여 22번 포트 점유를 해제하고 20022 포트로 완전 이관하였습니다.

---

### Q1.2. 방화벽이 활성화되어 있고(택1: UFW 또는 firewalld), 20022/tcp와 15034/tcp만 허용되는가?

#### 🎯 검증 명령어 및 증적 (Evidence)
```bash
sudo ufw status verbose
```
```text
Status: active
Logging: on (low)
Default: deny (incoming), allow (outgoing), deny (routed)
New profiles: skip

To                         Action      From
--                         ------      ----
20022/tcp                  ALLOW IN    Anywhere                  
15034/tcp                  ALLOW IN    Anywhere                  
20022/tcp (v6)             ALLOW IN    Anywhere (v6)             
15034/tcp (v6)             ALLOW IN    Anywhere (v6)             
```

#### 💡 모범 답변 및 해설
* UFW(Uncomplicated Firewall)를 채택하여 기본 인바운드 정책을 `default deny incoming`으로 전면 차단하였습니다.
* 원격 보안 관리를 위한 `20022/tcp`(SSH)와 관제 애플리케이션 서비스를 위한 `15034/tcp` 포트만 명시적 화이트리스트(`ALLOW IN`)로 개방하여 공격 표면(Attack Surface)을 최소화했습니다.

---

### Q1.3. agent-admin/dev/test 계정과 agent-common/core 그룹이 요구사항대로 구성되어 있는가?

#### 🎯 검증 명령어 및 증적 (Evidence)
```bash
id agent-admin; id agent-dev; id agent-test
```
```text
uid=1000(agent-admin) gid=1002(agent-admin) groups=1002(agent-admin),1000(agent-core),1001(agent-common)
uid=1001(agent-dev) gid=1003(agent-dev) groups=1003(agent-dev),1000(agent-core),1001(agent-common)
uid=1002(agent-test) gid=1004(agent-test) groups=1004(agent-test),1001(agent-common)
```

#### 💡 모범 답변 및 해설
* **`agent-admin` (운영자)**: `agent-core`, `agent-common` 그룹 소속 (전체 인프라 관리 및 Cron 무인 관제 실행)
* **`agent-dev` (개발자)**: `agent-core`, `agent-common` 그룹 소속 (`monitor.sh` 소유 및 수정/개발)
* **`agent-test` (외부 테스터)**: `agent-common` 그룹만 소속 (공용 `upload_files` 접근만 허용, 핵심 보안 자산인 `api_keys` 및 `log` 디렉토리 접근은 원천 차단)

---

### Q1.4. 앱이 Boot Sequence 5단계 [OK]를 통과하고 “Agent READY”가 출력되는가?

#### 🎯 검증 명령어 및 증적 (Evidence)
```bash
./agent-app
```
```text
[1/5] Checking Environment Variables... [OK]
[2/5] Checking Secret API Key... [OK]
[3/5] Binding TCP Service Port 15034... [OK]
[4/5] Checking Log Storage Permissions... [OK]
[5/5] Initializing Monitoring Subsystems... [OK]
==================================================
All Boot Checks Passed! Agent READY
==================================================
```

#### 💡 모범 답변 및 해설
* `setup/01_env_setup.sh`와 `setup/03_user_setup.sh`를 통해 사전에 `AGENT_HOME`, `AGENT_PORT=15034`, `$AGENT_HOME/api_keys/t_secret.key` 및 `/var/log/agent-app` 권한(`770`)을 완벽히 준비하여 5개 부트 검증을 모두 `[OK]`로 통과하고 `Agent READY` 상태로 기동됩니다.

---

### Q1.5. monitor.sh가 프로세스/포트 상태를 점검하고, 비정상 상태에서 exit 1로 종료되는가?

#### 🎯 검증 명령어 및 증적 (Evidence)
```bash
# 1. 정상 상태 점검 (Exit Code: 0)
bash bin/monitor.sh
echo "Exit Code: $?"
```
```text
====== SYSTEM MONITOR START ======
[HEALTH CHECK]
Checking process 'agent_app.py'... [OK] (PID: 1234)
Checking port 15034... [OK]
Checking Firewall... [OK]

[RESOURCE MONITORING]
Process CPU Usage: 0.0%
Process MEM Usage: 0.1%
System DISK Used: 23%
[INFO] Log appended: /var/log/agent-app/monitor.log
====== SYSTEM MONITOR END ======
Exit Code: 0
```

```bash
# 2. 비정상 상태 시뮬레이션 (프로세스 미실행 시 Exit Code: 1)
APP_NAME="non_exist_app" bash bin/monitor.sh
echo "Exit Code: $?"
```
```text
====== SYSTEM MONITOR START ======
[HEALTH CHECK]
Checking process 'non_exist_app'... [FAILED]
Exit Code: 1
```

#### 💡 모범 답변 및 해설
* `monitor.sh`는 헬스체크 단계에서 `pgrep`과 `ss`를 통해 서비스 생존을 검증하며, 프로세스가 없거나 포트가 LISTEN 상태가 아닐 경우 에러 로그를 남기고 즉시 `exit 1`로 비정상 종료하여 상위 감시 체계에 장애를 즉각 통보합니다.

---

### Q1.6. /var/log/agent-app/monitor.log가 지정 포맷으로 누적 기록되는가?

#### 🎯 검증 명령어 및 증적 (Evidence)
```bash
tail -n 3 /var/log/agent-app/monitor.log
```
```text
[2026-08-16 17:00:01] [INFO] PID:1234 CPU:0.0% MEM:0.1% DISK_USED:23%
[2026-08-16 17:01:01] [INFO] PID:1234 CPU:0.0% MEM:0.1% DISK_USED:23%
[2026-08-16 17:02:01] [WARNING] PID:1234 CPU:25.4% MEM:0.1% DISK_USED:23% Details: [CPU threshold exceeded (25.4% > 20%)]
```

#### 💡 모범 답변 및 해설
* 로그는 `[YYYY-MM-DD HH:MM:SS] [STATUS] PID:<PID> CPU:<VAL>% MEM:<VAL>% DISK_USED:<VAL>%` 표준 포맷을 엄격히 준수하며, `>>` 리다이렉션을 통해 누락 없이 시계열로 누적 기록됩니다.

---

### Q1.7. cron 매분 실행으로 monitor.log가 자동 증가하는가?

#### 🎯 검증 명령어 및 증적 (Evidence)
```bash
# Crontab 등록 확인
crontab -l | grep monitor.sh
```
```text
* * * * * /home/gdone90098008/agent-app/bin/monitor.sh >/dev/null 2>&1
```

```bash
# 2분간 대기 후 로그 라인 수 증가 확인
wc -l /var/log/agent-app/monitor.log
```

#### 💡 모범 답변 및 해설
* `setup/04_cron_setup.sh`를 통해 `* * * * *` (매분) 주기로 `monitor.sh`가 자동 실행되도록 등록되어 있으며, Cron의 제한된 환경 변수 문제를 해결하기 위해 스크립트 내부에서 `source ~/.bash_profile`을 로드하여 24/7 무인 자동 관제가 이루어집니다.

---

### Q1.8. monitor.log 용량 관리(10MB/10개)가 설정되어 있고 동작을 설명할 수 있는가?

#### 🎯 구현 로직 및 검증 증적
```bash
# monitor.sh 내부 용량 관리 로직 (Line 154~175)
if [ -f "$LOG_FILE" ]; then
    FILE_SIZE=$(stat -c%s "$LOG_FILE" 2>/dev/null || stat -f%z "$LOG_FILE")
    if [ "$FILE_SIZE" -ge 10485760 ]; then # 10MB = 10,485,760 bytes
        rm -f "$LOG_FILE.11"
        for i in {9..1}; do
            [ -f "$LOG_FILE.$i" ] && mv "$LOG_FILE.$i" "$LOG_FILE.$((i+1))"
        done
        mv "$LOG_FILE" "$LOG_FILE.1"
        touch "$LOG_FILE"
    fi
fi
```

#### 💡 모범 답변 및 해설
* 외부 데몬 없이 스크립트 런타임 자체에서 파일 크기를 체크합니다.
* 파일 크기가 10MB(10,485,760 bytes)에 도달하면 보존 한도(10개)를 초과하는 11번 파일을 삭제하고, 기존 백업 파일(`monitor.log.9` ~ `monitor.log.1`)의 인덱스를 1씩 증가시킨 뒤 현재 로그를 `monitor.log.1`로 이동하고 새 `monitor.log`를 생성하여 최대 100MB 이내로 디스크 점유를 완벽히 통제합니다.

---

## 🔍 항목 2. 스크립트 설계 및 구현 심층 설명 (4문항)

### Q2.1. monitor.sh에서 프로세스 식별(pgrep/ps 등)과 포트 확인(ss/netstat 등)에 사용한 명령과 선택 이유를 설명할 수 있는가?

#### 💡 모범 답변 및 해설
1. **프로세스 식별: `pgrep -f "$APP_NAME"` 선택 이유**
   * 전통적인 `ps -ef | grep "$APP_NAME"` 방식은 `grep` 명령어 자체 프로세스가 검색 결과에 포함되는 **오탐(False Positive)** 문제가 발생하여 별도의 `grep -v grep` 파이프라인 처리가 필요합니다.
   * `pgrep -f`는 커널 레벨에서 프로세스 커맨드라인을 정규식으로 직접 매칭하므로 오탐이 없으며 파이프라인 오버헤드가 적고 실행 속도가 월등히 빠릅니다.
2. **포트 확인: `ss -tuln` (Fallback: `netstat -an`) 선택 이유**
   * `netstat`은 구형 `net-tools` 패키지에 속하며 `/proc/net` 텍스트 파일을 직접 순회 파싱하므로 대규모 연결 상태에서 심각한 병목이 발생합니다.
   * `ss`(Socket Statistics)는 최신 Linux 커널의 **Netlink 인터페이스**를 직접 호출하므로 매우 빠르고 정확합니다.
   * 또한 이식성(Portability)을 고려하여 `ss` 명령어가 없는 환경에서는 `netstat`으로 자동 대체(Fallback)되도록 설계하였습니다.

---

### Q2.2. CPU/MEM/DISK 값을 어떤 방식으로 추출/파싱했고, 로그 포맷을 왜 그 형태로 고정했는지 설명할 수 있는가?

#### 💡 모범 답변 및 해설
1. **수치 추출 및 파싱 방식**
   * **CPU & MEM**: `ps -p $PID -o %cpu= -o %mem=` 옵션을 사용하여 헤더를 생략하고 대상 프로세스의 순수 점유율 수치만 깔끔하게 추출하였습니다.
   * **DISK**: `df -P /`를 사용했습니다. `-P`(POSIX 표준 포맷) 옵션을 사용해야 긴 마운트 경로에서도 줄바꿈(Line-break) 현상이 방지되어 `awk 'NR==2 {print $5}'`로 2번째 줄 5번째 컬럼(사용률 %)을 오탐 없이 정확히 파싱할 수 있습니다.
   * **임계치 실수(Float) 연산**: Bash 쉘의 정수 연산 한계를 극복하기 위해 `awk` 기반의 `check_threshold()` 함수를 작성하여 `20.0%`, `10.0%`와 같은 소수점 비교를 정확하게 처리했습니다.
2. **로그 포맷 고정 이유 (`[TIMESTAMP] [STATUS] PID:... CPU:...% MEM:...% DISK_USED:...%`)**
   * **기계 판독성(Machine Readability)**: Awk, Logstash, Fluentbit, Vector 등 로그 수집기가 정규식(Regex)으로 타임스탬프, 로그 레벨, 메트릭을 단번에 파싱할 수 있는 표준 Key-Value 구조입니다.
   * **가독성(Human Readability)**: 엔지니어가 터미널에서 `tail -f`나 `grep WARNING`으로 조회할 때 시각적으로 장애 원인을 즉각 식별할 수 있습니다.

---

### Q2.3. 소유자(agent-dev)와 실행자(agent-admin, cron) 권한 정책을 어떻게 만족시켰는지(소유/그룹/권한) 설명할 수 있는가?

#### 💡 모범 답변 및 해설
```text
-rwxr-x--- 1 agent-dev agent-core 10120 bin/monitor.sh  (권한: 750)
```
* **소유자 (`agent-dev`, 7 = `rwx`)**: 스크립트를 직접 개발하고 유지보수하는 개발자는 읽기/쓰기/실행 권한을 모두 가집니다.
* **소유 그룹 (`agent-core`, 5 = `r-x`)**: 운영자인 `agent-admin`은 `agent-core` 그룹에 속하므로 스크립트를 **실행(`x`)하고 읽을(`r`) 수 있으나, 임의로 코드를 수정(`w`)할 수는 없습니다.** 이를 통해 운영 중 스크립트가 오염되는 것을 방지합니다.
* **기타 사용자 (`Others`, 0 = `---`)**: `agent-test`나 외부 계정은 스크립트에 접근조차 불가능합니다.
* **Cron 실행 환경**: `agent-admin` 계정의 Crontab에 등록되어 그룹 권한(`r-x`)을 통해 안전하게 무인 실행됩니다.

---

### Q2.4. 용량 기반 로그 관리(10MB/10개)를 어떤 방식(logrotate/스크립트)으로 구현했는지 설명할 수 있는가?

#### 💡 모범 답변 및 해설
* 외부 데몬인 시스템 `logrotate` 유틸리티에 의존할 경우 별도의 설정 파일 배포(`/etc/logrotate.d/`)와 root 권한이 필요하며, 주기(daily/hourly)가 길어 로그 폭증 시 즉각 대응이 어렵습니다.
* 따라서 `monitor.sh` 런타임 내에 **자체 로테이션 알고리즘**을 내재화(In-script Rotation)했습니다.
* 매 실행 시 `stat` 명령으로 파일 크기를 바이트 단위로 측정하여 `10,485,760 bytes`(10MB) 초과 시 역순 루프(`for i in {9..1}`)로 백업 파일명을 하나씩 밀어내고(`monitor.log.9` -> `monitor.log.10`), 10개를 초과하는 `monitor.log.11`은 자동 삭제(`rm -f`)합니다.
* 이를 통해 **의존성 없는 독립 스크립트(Zero-Dependency)**로 어디서나 안전한 용량 관리가 보장됩니다.

---

## 🛡️ 항목 3. 보안 아키텍처 및 운영 철학 (4문항)

### Q3.1. SSH 포트 변경과 Root 접속 차단이 왜 보안에 효과적인지 위협 모델 관점에서 설명할 수 있는가?

#### 💡 모범 답변 및 해설
1. **SSH 포트 20022 변경 (공격 표면 축소 및 무작위 스캔 차단)**
   * 인터넷 상의 해커 및 악성 봇(Botnet)은 24시간 내내 기본 `22번` 포트만을 대상으로 전수 스캔(Port Scan) 및 무차별 대입 공격(Brute-Force)을 수행합니다.
   * 포트를 `20022`와 같은 비표준 포트로 변경하면 인터넷 상의 자동화 공격 시도를 **99% 이상 사전에 무력화**할 수 있습니다.
2. **Root 원격 접속 차단 (`PermitRootLogin no`)**
   * `root`는 모든 파일과 설정을 파괴할 수 있는 슈퍼유저입니다. 계정명이 고정되어 있어 공격자는 비밀번호나 키만 탈취하면 즉시 서버 장악이 가능합니다.
   * Root 접속을 차단하고 일반 계정(`agent-admin`)으로만 진입하게 강제하면:
     1) 사용자 계정명을 알아내야 하는 1차 방어선 구축
     2) 권한 작업 시 `sudo`를 강제함으로써 **명령어 실행 이력에 대한 책임 추적성(Audit Trail / 감사 로그)을 확보**할 수 있습니다.

---

### Q3.2. api_keys와 로그 디렉토리를 agent-core로 제한한 이유를 “최소 권한 원칙”으로 설명할 수 있는가?

#### 💡 모범 답변 및 해설
* **최소 권한 원칙(Principle of Least Privilege)**: 모든 주체(사용자, 프로세스)는 업무를 수행하는 데 꼭 필요한 최소한의 자산에만 접근해야 한다는 정보보안의 기본 원칙입니다.
* **`api_keys` (770, `agent-core` 전용)**: 시스템의 인증 키(`t_secret.key`)가 담겨 있어, 외부 테스터(`agent-test`)나 비인가 계정에 유출될 경우 시스템 권한 탈취 및 데이터 위변조 사고로 직결되므로 핵심 그룹으로 격리합니다.
* **`log` 디렉토리 (770, `agent-core` 전용)**: 시스템의 내부 동작 현황, PID, 잠재적 취약점 및 에러 정보가 기록됩니다. 권한이 없는 계정이 로그를 열람하면 시스템 내부 구조가 노출(Information Disclosure)되며, 로그를 임의 변조/삭제하여 침해 사고 증거를 인멸할 수 있으므로 엄격히 차단해야 합니다.

---

### Q3.3. “경고는 출력하되 종료하지 않는 항목”(방화벽 비활성/임계치 초과)을 분리한 운영상의 이유를 설명할 수 있는가?

#### 💡 모범 답변 및 해설
1. **치명적 장애 (Fatal Error -> `exit 1` 종료)**
   * 프로세스 미실행(`PID 없음`) 또는 서비스 포트 미오픈(`15034 FAILED`) 상태입니다.
   * 서비스가 제공되지 않으므로 리소스 측정이 무의미하며, 즉각 스크립트를 중단하고 상위 모니터링 알람(On-call Alert)을 발생시켜야 합니다.
2. **경고성 상태 (Warning -> 스크립트 정상 지속 및 `exit 0`)**
   * CPU 20% 초과, 메모리 10% 초과, 디스크 80% 초과, 방화벽 일시 비활성화 상태입니다.
   * **서비스 자체는 정상 동작 중**이므로 관제 스크립트가 중단되면 이후의 리소스 추이(Spike가 지속되는지, 메모리 누수가 선형 증가하는지)를 관측할 수 없게 됩니다.
   * 따라서 로그에 `[WARNING]` 플래그와 `alert_events.json`을 남기되 관제 파이프라인을 계속 유지하여 **연속적인 시계열 데이터 수집과 추적**을 가능하게 합니다.

---

### Q3.4. 리다이렉션 기호 > 와 >> 차이를 설명하고, 로그 누적에 >>가 필요한 이유를 설명할 수 있는가?

#### 💡 모범 답변 및 해설
1. **`>` (Overwrite, 덮어쓰기)**: 대상 파일의 기존 내용을 완전히 지우고 새로운 내용으로 처음부터 다시 작성합니다.
2. **`>>` (Append, 이어쓰기)**: 대상 파일의 기존 내용을 보존한 채 파일의 맨 마지막 줄(EOF)에 새로운 데이터를 덧붙입니다.
3. **로그 관리에 `>>`가 필수적인 이유**
   * 서버 관제에서는 과거 특정 시점에 발생한 장애 원인을 사후 추적(RCA, Root Cause Analysis)하고 성능 추세를 분석해야 합니다.
   * `>`를 사용하면 이전 분의 관제 데이터가 모두 삭제되어 오직 마지막 1건의 로그만 남게 되므로, 과거 이력 분석 및 통계 집계(`report.sh`)가 불가능해집니다. 따라서 시계열 누적을 위해 `>>` 사용이 필수적입니다.

---

## 🚨 항목 4. 장애 트러블슈팅 및 확장 시나리오 대응 (3문항)

### Q4.1. 모니터링 대상이 웹 서버(Nginx 등)로 바뀐다면, monitor.sh에서 바꿔야 할 핵심 포인트(프로세스/포트/로그/임계값)를 설명할 수 있는가?

#### 💡 모범 답변 및 해설
1. **프로세스 식별 변수 (`APP_NAME`)**
   * `APP_NAME="nginx"`로 변경. Nginx는 Master-Worker 멀티 프로세스 구조이므로 `pgrep -f "nginx: master process"`를 지정하여 메인 마스터 프로세스 PID를 타깃팅.
2. **서비스 포트 변수 (`AGENT_PORT`)**
   * 웹 표준 포트인 `80`(HTTP) 또는 `443`(HTTPS)으로 변경.
3. **로그 경로 및 권한 (`AGENT_LOG_DIR`)**
   * `/var/log/nginx/` 또는 전용 웹 관제 경로로 설정하고, 웹 서버 실행 계정(`www-data` 또는 `nginx`)의 권한과 일치시킴.
4. **리소스 임계치(Threshold) 현실화**
   * 웹 서버는 동시 접속자 처리에 따라 순간 CPU 점유가 높아질 수 있으므로 CPU 임계치를 `70~80%`, 메모리 `50%` 수준으로 웹 트래픽 특성에 맞게 상향 조정.

---

### Q4.2. “프로세스는 살아있는데 포트가 안 열리는 상황”을 발견했다면, 원인 후보와 확인 순서를 설명할 수 있는가?

#### 💡 모범 답변 및 해설
#### [원인 후보 (4가지)]
1. **부팅 초기화 지연 (Slow Initialization)**: DB 커넥션 풀링 또는 대용량 모델 로딩 중이라 아직 `bind()`/`listen()` 단계에 도달하지 못함.
2. **포트 충돌 (Address Already in Use)**: 다른 프로세스가 이미 15034 포트를 선점하고 있어 바인딩 실패.
3. **소프트웨어 교착상태 (Deadlock)**: 메인 스레드가 락(Lock)에 걸려 소켓 리스닝 이벤트 루프를 시작하지 못함.
4. **바인딩 IP 설정 오류**: `0.0.0.0`(전체 개방)이 아닌 `127.0.0.1`(로컬 전용)로 바인딩되어 외부 및 포트 스캔에서 탐지되지 않음.

#### [체크 순서 (Troubleshooting Pipeline)]
1. **1단계: 애플리케이션 로그 확인**
   ```bash
   tail -n 50 /var/log/agent-app/app.log (또는 stderr 로그 확인)
   ```
2. **2단계: 포트 선점 여부 확인**
   ```bash
   sudo ss -tulnp | grep 15034 (어떤 PID가 포트를 쥐고 있는지 확인)
   ```
3. **3단계: 프로세스 스레드 및 시스템 콜 상태 추적**
   ```bash
   ps -T -p <PID>          # 스레드 상태 점검
   sudo strace -p <PID>   # 프로세스가 어떤 시스템 콜에서 멈춰(Block) 있는지 추적
   ```
4. **4단계: 네트워크 바인딩 설정 점검**
   * 애플리케이션 설정 파일 내 IP 바인딩 주소(`Host: 0.0.0.0`) 확인.

---

### Q4.3. 로그가 급증해 디스크가 가득 찰 위험이 있다면, 운영자가 취할 대응(단기/중기)을 설명할 수 있는가?

#### 💡 모범 답변 및 해설
#### [단기 긴급 대응 (Immediate Action - 디스크 풀 방지)]
1. **오래된 백업 로그 즉시 압축 및 수동 정리**
   ```bash
   # 3일 이상 지난 백업 로그 즉각 삭제
   find /var/log/agent-app -type f -name "*.log.*" -mtime +3 -delete
   # 현재 큰 로그 파일 임시 압축
   gzip -f /var/log/agent-app/monitor.log.1
   ```
2. **로그 파일 Truncate (프로세스를 죽이지 않고 용량 확보)**
   ```bash
   # rm 대신 크기만 0으로 비움 (File Descriptor 유지)
   : > /var/log/agent-app/monitor.log
   ```

#### [중·장기 근본 대책 (Permanent Solution)]
1. **로그 로테이션 정책 강화**: 임계치 크기를 10MB에서 `5MB`로 하향하고, 최대 보존 개수를 10개에서 `5개`로 축소.
2. **로그 레벨 튜닝**: 불필요하게 많은 출력을 발생시키는 `DEBUG` 레벨을 프로덕션 환경에 맞게 `INFO` 또는 `WARN`으로 조정.
3. **전용 로그 파티션 분리 (Mount Separation)**: `/var/log`를 루트(`/`) 파일시스템과 별도의 물리 디스크/볼륨으로 마운트하여, 로그가 가득 차더라도 OS 전체가 다운(System Crash)되는 사태 원천 방지.
4. **외부 중앙 집중형 로그 파이프라인 구축**: Fluentbit / Vector 등을 통해 로그를 Elasticsearch, Loki, 또는 S3/Cold Storage로 실시간 스트리밍 전송하고 로컬 서버에는 최소 24시간 분량만 보존.

---

## 📊 종합 요약 매핑 테이블

| 영역 | 평가 항목 | 핵심 검증 포인트 | 주요 도구 / 명령어 | 상태 |
| :--- | :--- | :--- | :--- | :---: |
| **항목 1** | 실무 기능 검증 | SSH 20022, UFW, RBAC, Ready, monitor, cron, 로테이션 | `ss`, `ufw`, `id`, `crontab`, `run_tests.sh` | ✅ PASS |
| **항목 2** | 스크립트 설계 | pgrep vs ps, ss vs netstat, Awk float 연산, 750 권한 | `pgrep`, `ss`, `awk`, `stat`, `chmod 750` | ✅ PASS |
| **항목 3** | 보안 및 운영 철학 | 위협 모델, 최소 권한 원칙, Fatal vs Warning, `>>` 누적 | `PermitRootLogin no`, `agent-core`, `exit 1` | ✅ PASS |
| **항목 4** | 장애 및 확장 대응 | Nginx 전환, 포트 미오픈 트러블슈팅, 디스크 풀 대응 | `strace`, `truncate`, 파티션 분리, 로그 레벨 조정 | ✅ PASS |

---
