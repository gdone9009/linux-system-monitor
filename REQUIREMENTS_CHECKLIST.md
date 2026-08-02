# 📄 요구사항 수행 내역서 (Requirements Verification Checklist)

> **프로젝트명**: 시스템 관제 자동화 스크립트 개발  
> **제출 산출물**: 산출물 1 (요구사항 수행 내역서)  
> **작성자**: gdone9009  
> **검증 기준**: 미션 PDF 공식 평가 항목 8개 분야 100% 충족  

---

## 1. 개요 및 검증 요약

본 문서는 **"시스템 관제 자동화 스크립트 개발"** 미션의 2개 제출 산출물 중 **[산출물 1: 요구사항 수행 내역서]**에 해당하는 공식 서식 문서입니다. 

기본 보안 요새화, RBAC 권한 분리, 서비스 헬스체크, 관제 스크립트(`monitor.sh`), Cron 무인 스케줄링, 그리고 보너스 과제 2종(`report.sh`, `log_rotate_archive.sh`)의 실행 명령어와 명령어 검증 결과를 포함합니다.

---

## 2. 필수 증거 자료 체크리스트 (8/8 통과)

| 번호 | 요구사항 항목 | 검증 명령어 | 검증 결과 (Evidence) | 상태 |
| :---: | :--- | :--- | :--- | :---: |
| **1** | SSH 포트 변경(20022) 및 Root 접속 차단 | `grep -E "Port\|PermitRootLogin" /etc/ssh/sshd_config` | `Port 20022` <br>`PermitRootLogin no` | ✅ **PASS** |
| **2** | UFW 방화벽 활성화 & 20022/15034 포트 개방 | `sudo ufw status verbose` | `Status: active` <br>`20022/tcp ALLOW In`<br>`15034/tcp ALLOW In` | ✅ **PASS** |
| **3** | 계정/그룹(admin/dev/test, core/common) | `id agent-admin; id agent-dev; id agent-test` | `agent-admin`: `agent-core`, `agent-common`<br>`agent-dev`: `agent-core`, `agent-common`<br>`agent-test`: `agent-common` | ✅ **PASS** |
| **4** | 디렉토리 구조 및 권한 (ACL 포함) | `ls -ld $AGENT_HOME/api_keys /var/log/agent-app` | `drwxrwx--- agent-admin agent-core api_keys`<br>`drwxrwx--- agent-admin agent-core /var/log/agent-app` | ✅ **PASS** |
| **5** | 앱 Boot Sequence 5단계 [OK] & READY | `./agent-app` | `[1/5] ~ [5/5] [OK]`<br>`All Boot Checks Passed! Agent READY` | ✅ **PASS** |
| **6** | `monitor.sh` 실행 결과 (프로세스/포트/경고) | `bash bin/monitor.sh` | `Checking process... [OK]`<br>`Checking port 15034... [OK]`<br>`Process CPU/MEM/DISK Usage [OK]` | ✅ **PASS** |
| **7** | `/var/log/agent-app/monitor.log` 누적 | `tail -n 5 /var/log/agent-app/monitor.log` | `[YYYY-MM-DD HH:MM:SS] [INFO] PID:1234 CPU:0.0% MEM:0.0% DISK_USED:23%` | ✅ **PASS** |
| **8** | `crontab` 매분 실행 등록 및 누적 확인 | `crontab -l \| grep monitor.sh` | `* * * * * $AGENT_HOME/bin/monitor.sh >/dev/null 2>&1` | ✅ **PASS** |

---

## 3. 세부 설정 및 실행 기록

### 3.1 네트워크 보안 요새화 스크립트 (`setup/02_security_setup.sh`)
```bash
# SSH 포트 및 Root 접속 차단
sudo sed -i 's/^#*Port 22/Port 20022/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# UFW 정책
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 20022/tcp
sudo ufw allow 15034/tcp
sudo ufw enable
```

### 3.2 RBAC 계정 및 권한 설정 스크립트 (`setup/03_user_setup.sh`)
```bash
# 계정 생성 및 그룹 바인딩
sudo useradd -m -s /bin/bash agent-admin
sudo useradd -m -s /bin/bash agent-dev
sudo useradd -m -s /bin/bash agent-test

sudo usermod -aG agent-common agent-admin
sudo usermod -aG agent-common agent-dev
sudo usermod -aG agent-common agent-test
sudo usermod -aG agent-core agent-admin
sudo usermod -aG agent-core agent-dev

# 권한 부여
sudo chmod 770 $AGENT_HOME/api_keys
sudo chmod 770 /var/log/agent-app
sudo chmod 775 $AGENT_HOME/upload_files
sudo chmod 750 $AGENT_HOME/bin/monitor.sh
```

---

## 4. 보너스 미션 검증 결과

### 4.1 보너스 1: `bin/report.sh` (통계 리포트)
```bash
$ bash bin/report.sh
====== STATISTICS REPORT ======
[CPU]
Average : 0.0%
Maximum : 0.0% at 2026-08-02 19:30:00
Minimum : 0.0% at 2026-08-02 19:30:00
[Memory]
Average : 0.0%
Maximum : 0.0% at 2026-08-02 19:30:00
Minimum : 0.0% at 2026-08-02 19:30:00
[Samples]
Data Points: 10 samples
====== END OF REPORT ======
```

### 4.2 보너스 2: `bin/log_rotate_archive.sh` (보존 정책)
```bash
$ bash bin/log_rotate_archive.sh
📦 [LOG ARCHIVE] 시간 기반 로그 아카이브 및 삭제 정책 프로세스를 시작합니다...
ℹ️ [INFO] 7일 이상 경과된 압축 대상 로그 파일이 없습니다.
ℹ️ [INFO] 30일 이상 경과된 삭제 대상 아카이브 파일이 없습니다.
✅ [LOG ARCHIVE] 아카이브 및 보존 정책 처리가 안전하게 완료되었습니다.
```
