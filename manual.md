# 📘 초보 개발자를 위한 리눅스 시스템 관제 & 인프라 보충 설명서 (manual.md)

> **문서 목적**: 본 설명서는 컴퓨터 프로그래밍 및 리눅스 시스템 운영을 처음 배우는 초급 개발자분들을 위해 작성된 **독학용 백과사전식 입문 가이드**입니다.  
> 기술 문서(`README.md`)와 소스 코드를 읽기 전 필요한 기초 지식부터 라인별 코드 작동 원리, 보안 정책의 이유까지 누구나 쉽게 이해할 수 있도록 가장 친절하게 해설합니다.

---

## 📑 목차 (Table of Contents)

- [1. 기초 지식 백과사전 (Prerequisite Foundations)](#1-기초-지식-백과사전-prerequisite-foundations)
  - [1.1 서버(Server)와 클라이언트(Client)의 차이](#11-서버server와-클라이언트client의-차이)
  - [1.2 왜 리눅스(Linux)가 서버 운영체제의 표준인가?](#12-왜-리눅스linux가-서버-운영체제의-표준인가)
  - [1.3 터미널(Terminal), 쉘(Shell), Bash의 관계](#13-터미널terminal-쉘shell-bash의-관계)
  - [1.4 Shebang (`#!/bin/bash`) 선언의 의미](#14-shebang-binbash-선언의-의미)
  - [1.5 환경 변수(Environment Variables)란 무엇인가?](#15-환경-변수environment-variables란-무엇인가)
  - [1.6 프로세스(PID)와 네트워크 포트(Port)의 원리](#16-프로세스pid와-네트워크-포트port의-원리)
  - [1.7 리눅스 권한 체계 (rwx 숫자 770, 775, 750의 계산법)](#17-리눅스-권한-체계-rwx-숫자-770-775-750의-계산법)
  - [1.8 RBAC (역할 기반 접근 제어)와 최소 권한 원칙](#18-rbac-역할-기반-접근-제어와-최소-권한-원칙)
- [2. 보안 요새화 (Security Hardening) 원리 해설](#2-보안-요새화-security-hardening-원리-해설)
  - [2.1 SSH 접속 포트를 20022로 바꾸는 이유](#21-ssh-접속-포트를-20022로-바꾸는-이유)
  - [2.2 Root 원격 접속 차단 (`PermitRootLogin no`)의 필수성](#22-root-원격-접속-차단-permitrootlogin-no의-필수성)
  - [2.3 UFW 방화벽의 인바운드/아웃바운드 포트 통제 원리](#23-ufw-방화벽의-인바운드아웃바운드-포트-통제-원리)
- [3. 계정 및 디렉터리 권한 설계 완전 해설](#3-계정-및-디렉터리-권한-설계-완전-해설)
  - [3.1 계정 3종과 그룹 2종의 역할 분담](#31-계정-3종과-그룹-2종의-역할-분담)
  - [3.2 디렉터리 격리: 왜 api_keys는 770이고 upload_files는 775인가?](#32-디렉터리-격리-왜-api_keys는-770이고-upload_files는-775인가)
  - [3.3 ACL(Access Control List) 확장 권한이란?](#33-aclaccess-control-list-확장-권한이란)
- [4. 관제 스크립트(`monitor.sh`) 줄별 완전 해설](#4-관제-스크립트monitorsh-줄별-완전-해설)
  - [4.1 1단계: 환경 변수 로드 및 경로 계산](#41-1단계-환경-변수-로드-및-경로-계산)
  - [4.2 2단계: 헬스체크 (프로세스 PID 및 포트 점검)](#42-2단계-헬스체크-프로세스-pid-및-포트-점검)
  - [4.3 3단계: 리소스 수집 (CPU%, MEM%, DISK%)](#43-3단계-리소스-수집-cpu-mem-disk)
  - [4.4 4단계: Awk 실수(Float) 연산 및 임계치 검사](#44-4단계-awk-실수float-연산-및-임계치-검사)
  - [4.5 5단계: Log Rotation (10MB 크기 체킹 & 밀어내기 알고리즘)](#45-5단계-log-rotation-10mb-크기-체킹--밀어내기-알고리즘)
- [5. 보너스 스크립트 해설 (`report.sh` & `log_rotate_archive.sh`)](#5-보너스-스크립트-해설-reportsh--log_rotate_archivesh)
  - [5.1 `report.sh` 통계 분석 알고리즘 (Awk BEGIN/Loop/END)](#51-reportsh-통계-분석-알고리즘-awk-beginloopend)
  - [5.2 `log_rotate_archive.sh` 7일 압축 및 30일 삭제 보존 정책](#52-log_rotate_archivesh-7일-압축-및-30일-삭제-보존-정책)
- [6. 무인 스케줄링(Cron) 및 자동 검증 수트 가이드](#6-무인-스케줄링cron-및-자동-검증-수트-가이드)
- [7. 자주 묻는 질문 및 트러블슈팅 (FAQ)](#7-자주-묻는-질문-및-트러블슈팅-faq)

---

## 1. 기초 지식 백과사전 (Prerequisite Foundations)

### 1.1 서버(Server)와 클라이언트(Client)의 차이
- **클라이언트(Client)**: 서비스를 요청하는 주체입니다. (예: 스마트폰, 내 맥북의 브라우저)
- **서버(Server)**: 24시간 꺼지지 않고 켜져서 클라이언트의 요청을 받아 응답(데이터 전달)을 처리하는 컴퓨터입니다.

### 1.2 왜 리눅스(Linux)가 서버 운영체제의 표준인가?
- 윈도우(Windows)나 macOS와 달리, 리눅스는 **무료(Open Source)**이며 텍스트 명령어(CLI) 위주로 구동되어 컴퓨터 자원(CPU, Memory)을 최소한으로 사용합니다. 따라서 구글, 네이버, AWS 등 전 세계 서버의 90% 이상이 리눅스(Ubuntu, RedHat 등)를 사용합니다.

### 1.3 터미널(Terminal), 쉘(Shell), Bash의 관계
- **터미널(Terminal)**: 사용자가 글자를 입력할 수 있는 '검은색 화면 창'입니다.
- **쉘(Shell)**: 사용자가 터미널에 입력한 명령어를 해석해서 리눅스 커널(자원 관리자)에 전달해 주는 '번역기'입니다.
- **Bash (Bourne-Again SHell)**: 가장 표준적으로 사용되는 쉘 프로그램의 이름입니다.

### 1.4 Shebang (`#!/bin/bash`) 선언의 의미
- 쉘 스크립트 파일의 첫 번째 줄에 나오는 `#!/bin/bash`를 **Shebang(쉬뱅)**이라고 부릅니다.
- 컴퓨터에게 "이 문서 안에 적힌 수많은 명령어들을 `/bin/bash` 프로그램으로 실행해라" 하고 지정해 주는 약속입니다.

### 1.5 환경 변수(Environment Variables)란 무엇인가?
- 운영체제 전체에서 언제 어디서나 참조할 수 있는 **전역 설정값**입니다.
- 예: `AGENT_HOME=/home/agent-admin/agent-app` 으로 등록해 두면, 어떤 스크립트에서든 `$AGENT_HOME`이라는 단어로 그 폴더 경로를 바로 불러와 쓸 수 있습니다.
- 사용자 프로파일 파일(`~/.bash_profile`)에 작성해 두어야 컴퓨터를 껐다 켜거나 Cron 백그라운드가 실행되어도 환경 변수가 유실되지 않습니다.

### 1.6 프로세스(PID)와 네트워크 포트(Port)의 원리
- **프로세스(Process)**: 현재 컴퓨터 메모리상에서 실행 중인 프로그램입니다. 각 프로세스는 고유한 ID 숫자(예: `PID 10312`)를 부여받습니다.
- **포트(Port)**: 한 대의 서버 안에서 여러 프로그램(웹서버, DB 등)이 통신할 수 있도록 마련된 **'디지털 문 번호'**입니다. (0 ~ 65535번 존재)
  - 예: SSH 접속 문 = `22번` (본 과제에서는 `20022번`), 우리가 만든 앱 = `15034번`

### 1.7 리눅스 권한 체계 (rwx 숫자 770, 775, 750의 계산법)
리눅스는 파일과 폴더의 접근 권한을 **읽기(r=4), 쓰기(w=2), 실행(x=1)**의 3가지 숫자의 합으로 표기합니다. 권한은 `[소유자][그룹][기타사용자]` 3자릿수로 부여됩니다.

```text
권한 기호: r (Read = 4) / w (Write = 2) / x (eXecute = 1)

• 7 = 4 + 2 + 1 (rwx: 읽기, 쓰기, 실행 모두 가능)
• 5 = 4 + 0 + 1 (r-x: 읽기와 실행만 가능, 수정 불가)
• 0 = 0 + 0 + 0 (---: 아무 권한 없음, 접근 금지)

[예시 권한 분석]
- 770 (rwxrwx---) : 소유자(7:rwx), 그룹(7:rwx), 남(0:--- 접근금지) ➡️ 핵심 보안 폴더(api_keys, log)
- 775 (rwxrwxr-x) : 소유자(7:rwx), 그룹(7:rwx), 남(5:r-x 읽기만) ➡️ 공용 업로드 폴더(upload_files)
- 750 (rwxr-x---) : 소유자(7:rwx), 그룹(5:r-x), 남(0:--- 접근금지) ➡️ 관제 스크립트(monitor.sh)
```

### 1.8 RBAC (역할 기반 접근 제어)와 최소 권한 원칙
- **최소 권한 원칙(Least Privilege)**: 업무를 수행하는 데 꼭 필요한 최소한의 권한만 주고, 나머지는 전부 차단하는 보안 원칙입니다.
- **RBAC**: 사용자에게 직접 권한을 하나씩 주지 않고, **'그룹(Role)'**을 만들어 그룹에 권한을 준 뒤 사용자를 해당 그룹에 가입시키는 정교한 관리 방식입니다.

---

## 2. 보안 요새화 (Security Hardening) 원리 해설

### 2.1 SSH 접속 포트를 20022로 바꾸는 이유
- 인터넷에 연결된 모든 리눅스 서버는 24시간 내내 해커들의 자동 스캔 봇(Bot)으로부터 침입 시도를 받습니다.
- 봇들은 기본 포트인 **22번**으로만 공격을 시도하므로, 포트를 **20022번**으로 바꿔두는 것만으로도 무차별 대입 무차별 공격(Brute-force)의 99%를 자동으로 차단할 수 있습니다.

### 2.2 Root 원격 접속 차단 (`PermitRootLogin no`)의 필수성
- `root` 계정은 리눅스의 모든 것을 삭제하고 변경할 수 있는 '최고 관리자 계정'입니다.
- 외부에서 `root` 아이디로 직접 로그인하는 것을 허용하면 해커가 root 비밀번호만 맞추면 서버가 완전히 점령당합니다. 따라서 root 원격 접속을 금지하고, 일반 계정(`agent-admin`)으로 로그인한 뒤 필요한 때만 `sudo` 명령어로 관리자 권한을 승인받아 사용하는 것이 최고 수준의 보안입니다.

### 2.3 UFW 방화벽의 인바운드/아웃바운드 포트 통제 원리
- **UFW(Uncomplicated Firewall)**: 리눅스 신호등 역할의 방화벽입니다.
- `sudo ufw default deny incoming`: 외부에서 들어오는 모든 접속을 일단 **전면 차단**합니다.
- `sudo ufw allow 20022/tcp` 및 `15034/tcp`: 꼭 필요한 2개의 포트(SSH용 20022, 앱용 15034)만 **화이트리스트로 구멍을 뚫어 개방**합니다.

---

## 3. 계정 및 디렉터리 권한 설계 완전 해설

### 3.1 계정 3종과 그룹 2종의 역할 분담

```text
[계정 구조]
• agent-admin : 운영/관리자 계정 (Cron 무인 관제 실행자)
• agent-dev   : 개발자 계정 (monitor.sh 작성자)
• agent-test  : QA/테스트 계정 (테스터)

[그룹 바인딩 구조]
• agent-core   그룹 : agent-admin, agent-dev 포함 (민감 자산 접근 권한)
• agent-common 그룹 : agent-admin, agent-dev, agent-test 포함 (공용 데이터 접근 권한)
```

### 3.2 디렉터리 격리: 왜 api_keys는 770이고 upload_files는 775인가?
- **`$AGENT_HOME/api_keys` (770 권한)**: API 비밀키가 들어있는 극비 폴더이므로 `agent-core` 그룹(`admin`, `dev`)만 접근할 수 있고, 외부 사용자나 `test` 계정은 진입조차 못 하도록 `0`으로 격리합니다.
- **`$AGENT_HOME/upload_files` (775 권한)**: 협업용 공용 폴더이므로 `agent-common` 그룹 전체가 읽고 쓸 수 있도록 허용합니다.

### 3.3 ACL(Access Control List) 확장 권한이란?
- 전통적인 리눅스 권한은 "단 1개의 소유자"와 "단 1개의 그룹"만 지정할 수 있습니다.
- 만약 특정 제3의 그룹에도 추가 권한을 주고 싶을 때 `setfacl -m g:agent-core:rwx /var/log/agent-app` 명령어를 사용하면 리눅스 기본 권한을 손상시키지 않고 정밀하게 권한을 덧붙일 수 있습니다.

---

## 4. 관제 스크립트(`monitor.sh`) 줄별 완전 해설

이 장에서는 [`bin/monitor.sh`](file:///Users/gdone/dev/codyssey/linux-system-monitor/bin/monitor.sh) 소스 코드가 실제로 어떻게 한 줄씩 구동되는지 완벽하게 해설합니다.

```bash
#!/bin/bash
# 1. 환경 변수 로드 (Cron 백그라운드 실행 시 환경 변수 누락 방지)
source ~/.bash_profile 2>/dev/null
```
- **해설**: Cron은 백그라운드에서 최소한의 환경으로 구동되므로, `source ~/.bash_profile` 명령어로 사용자의 환경 변수(`AGENT_HOME` 등)를 강제로 로드합니다. `2>/dev/null`은 만약 파일이 없어서 생기는 에러 메시지를 화면에 띄우지 않고 조용히 무시하라는 의미입니다.

```bash
AGENT_HOME="${AGENT_HOME:-$HOME/agent-app}"
LOG_FILE="$AGENT_LOG_DIR/monitor.log"
```
- **해설**: `${AGENT_HOME:-$HOME/agent-app}` 구문은 `AGENT_HOME` 변수가 비어 있으면 기본값으로 내 홈 디렉토리의 `agent-app` 경로를 대입하라는 안전장치입니다.

```bash
# 3.1 프로세스 구동 확인
PID=$(pgrep -f "$APP_NAME" | head -n 1)
if [ -z "$PID" ]; then
    echo "Checking process '$APP_NAME'... [FAILED]"
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] [ERROR] Process '$APP_NAME' is NOT running!" >> "$LOG_FILE"
    exit 1
fi
```
- **해설**: `pgrep -f`로 `agent_app.py` 프로세스가 켜져 있는지 확인하고 PID(프로세스 번호)를 가져옵니다. 만약 PID가 비어있다면(`[ -z "$PID" ]`), 즉시 에러 메시지를 로그 파일 끝에 붙여쓰고(`>>`), `exit 1`로 스크립트를 즉시 비정상 종료시킵니다.

```bash
# 3.2 포트 리슨 상태 확인 (TCP 15034)
if command -v ss &>/dev/null; then
    PORT_CHECK=$(ss -tuln | grep -q ":$AGENT_PORT " && echo "OK" || echo "FAILED")
else
    PORT_CHECK=$(netstat -an | grep -q "\.$AGENT_PORT " && echo "OK" || echo "FAILED")
fi
```
- **해설**: `ss -tuln` 명령어로 15034 포트가 열려(LISTEN) 있는지 확인합니다. `ss` 명령어가 없는 환경(macOS 등)을 위해 `command -v ss`로 확인 후 없으면 `netstat` 명령어로 자동 호환 처리(Fallback)합니다.

```bash
# 리소스 수집 및 POSIX df 파싱
DISK_USED=$(df -P / | awk 'NR==2 {print $5}' | tr -d '%')
```
- **해설**: `df -P /` 옵션의 `-P`는 POSIX 표준 포맷으로 출력하라는 의미입니다. 디렉터리 경로가 길어도 2줄로 꺾이지 않아 오탐을 방지합니다. `awk 'NR==2 {print $5}'`로 2번째 줄의 5번째 열(사용률 %)을 가져온 뒤 `tr -d '%'`로 `%` 기호를 떼어내고 순수 숫자만 남깁니다.

```bash
check_threshold() {
    awk -v val="$1" -v limit="$2" 'BEGIN { if (val > limit) exit 0; else exit 1; }'
}
```
- **해설**: Bash 쉘은 `25.3 > 20.0` 같은 소수점(실수) 비교를 못 하고 정수만 다룹니다. 따라서 소수점 비교를 할 때 내부적으로 `awk` 유틸리티를 호출하여 정밀하게 비교합니다.

```bash
# Log Rotation (10MB 초과 시 10개 파일 순환 관리)
if [ "$FILE_SIZE" -ge 10485760 ]; then
    rm -f "$LOG_FILE.11"
    for i in {9..1}; do
        if [ -f "$LOG_FILE.$i" ]; then
            mv "$LOG_FILE.$i" "$LOG_FILE.$((i+1))"
        fi
    done
    mv "$LOG_FILE" "$LOG_FILE.1"
    touch "$LOG_FILE"
fi
```
- **해설**: 로그 파일 크기가 10MB(10,485,760바이트) 이상이 되면, 10개를 넘어가는 옛날 로그(`monitor.log.11`)를 삭제하고, `monitor.log.9`를 `monitor.log.10`으로, `monitor.log.1`을 `monitor.log.2`로 한 단계씩 이름을 밀어낸 뒤, 현재 로그를 `monitor.log.1`로 변경하고 새로 빈 `monitor.log`를 만듭니다.

---

## 5. 보너스 스크립트 해설 (`report.sh` & `log_rotate_archive.sh`)

### 5.1 `report.sh` 통계 분석 알고리즘 (Awk BEGIN/Loop/END)
[`bin/report.sh`](file:///Users/gdone/dev/codyssey/linux-system-monitor/bin/report.sh)는 `monitor.log`를 읽어 파싱하는 분석 도구입니다.

```text
[BEGIN 블록] ➡️ 변수 초기화 (count=0, sum=0, max=-1, min=9999)
     │
[라인별 Loop 블록] ➡️ 매 라인을 읽으며 CPU%, MEM% 수치 누적 (sum += val)
     │                최댓값(max) / 최솟값(min) 및 발생 시간 교체
     ▼
[END 블록] ➡️ 평균값 계산 (avg = sum / count) ➡️ 규격 보고서 콘솔 출력
```

### 5.2 `log_rotate_archive.sh` 7일 압축 및 30일 삭제 보존 정책
[`bin/log_rotate_archive.sh`](file:///Users/gdone/dev/codyssey/linux-system-monitor/bin/log_rotate_archive.sh)는 시간 흐름에 따른 로그 관리 스크립트입니다.

1. `find $LOG_DIR -mtime +7`: 최종 수정 후 7일(168시간)이 지난 로그 파일을 검색합니다.
2. `gzip -f [파일명]`: 7일이 넘은 텍스트 파일 용량을 80% 이상 획기적으로 줄이는 `.gz` 압축을 실행하고 아카이브 폴더로 이동합니다.
3. `find $ARCHIVE_DIR -name "*.gz" -mtime +30`: 압축된 지 30일이 넘은 아카이브 데이터는 `rm -f`로 영구 삭제하여 디스크를 무한 보존 관리합니다.

---

## 6. 무인 스케줄링(Cron) 및 자동 검증 수트 가이드

### 6.1 Cron 1분 주기 설정 (`setup/04_cron_setup.sh`)
```bash
* * * * * /home/agent-admin/agent-app/bin/monitor.sh >/dev/null 2>&1
```
- **해설**: 맨 앞의 별 5개(`* * * * *`)는 **"매분, 매시, 매일, 매월, 매요일마다"** 실행하라는 크론 표현식입니다. 뒤의 `>/dev/null 2>&1`은 크론 실행 시 화면으로 나오는 임시 출력을 버려서 시스템 메일 박스가 가득 차는 현상을 방지합니다.

### 6.2 통합 자동화 검증 수트 (`tests/run_tests.sh`)
```bash
./tests/run_tests.sh
```
- 스크립트의 문법 오류(`bash -n`), 디렉터리 권한 상태, 헬스체크 동작 여부 7가지 항목을 한 번에 자동 검사하여 `PASS` / `FAIL` 리포트를 보여줍니다.

---

## 7. 자주 묻는 질문 및 트러블슈팅 (FAQ)

### Q1. `Permission denied` 오류가 발생해요!
- **원인**: 실행하려는 스크립트에 실행(`x`) 권한이 없거나, 디렉터리 소유권이 다를 때 발생합니다.
- **해결**: `chmod +x 스크립트명.sh` 명령어로 실행 권한을 주거나 `sudo`를 사용하여 실행하세요.

### Q2. 스크립트 안의 환경 변수가 자꾸 사라져요!
- **원인**: 쉘을 새로 열거나 Cron 백그라운드로 실행할 때는 이전 쉘의 변수가 전달되지 않습니다.
- **해결**: 스크립트 상단에 `source ~/.bash_profile 2>/dev/null` 구문을 반드시 포함하세요.

### Q3. `df` 명령어가 2줄로 출력되어 스크립트가 깨져요!
- **원인**: 리눅스에서 길거나 특수한 마운트 경로를 볼 때 일어나는 현상입니다.
- **해결**: 반드시 `df -P /` 옵션(-P: POSIX 포맷)을 사용하여 한 줄 출력을 강제하세요.

---

이 **`manual.md`** 설명서 문서 하나만으로도 리눅스 기초부터 시스템 관제 엔지니어링의 전체 원리를 완벽하게 마스터하실 수 있습니다!
