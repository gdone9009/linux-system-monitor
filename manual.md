# 📖 [대형 교재] 초보 개발자를 위한 리눅스 시스템 관제 & 인프라 보충 설명서 (manual.md)

> **문서 목적**: 본 설명서는 컴퓨터 프로그래밍 및 리눅스 시스템 운영을 처음 시작하는 **초급/입문 개발자분들을 위해 작성된 대형 백과사전급 독학 교재**입니다.  
> 단순한 기술 요약을 넘어, 리눅스 운영체제의 기본 원리부터 네트워크 보안, 쉘 스크립팅 문법, 런타임 수치 계측, 그리고 트러블슈팅까지 **이 문서 하나만 읽어도 전체 코드와 기술 명세를 100% 독학으로 마스터할 수 있도록 5배의 분량으로 깊이 있고 쉽게 작성**되었습니다.

---

## 📑 대목차 (Table of Contents)

- [Part 1. 컴퓨터 아키텍처와 리눅스 OS 기초](#part-1-컴퓨터-아키텍처와-리눅스-os-기초)
  - [1.1 하드웨어 4대 자원(CPU, RAM, Disk, Network)의 역할](#11-하드웨어-4대-자원cpu-ram-disk-network의-역할)
  - [1.2 왜 전 세계 서버의 90% 이상이 리눅스(Linux)를 사용하는가?](#12-왜-전-세계-서버의-90-이상이-리눅스linux를-사용하는가)
  - [1.3 리눅스 디렉터리 구조 표준(FHS) 완벽 해설 (`/`, `/var`, `/etc`, `/home`, `/bin`)](#13-리눅스-디렉터리-구조-표준fhs-완벽-해설--var-etc-home-bin)
  - [1.4 터미널(Terminal), 쉘(Shell), Bash의 관계 및 작동 원리](#14-터미널terminal-쉘shell-bash의-관계-및-작동-원리)
  - [1.5 Shebang (`#!/bin/bash`) 선언의 깊은 의미](#15-shebang-binbash-선언의-깊은-의미)
- [Part 2. 리눅스 보안, 권한 및 환경 변수 완벽 마스터](#part-2-리눅스-보안-권한-및-환경-변수-완벽-마스터)
  - [2.1 쉘 환경 변수(Environment Variables)와 `~/.bash_profile` 로딩 매커니즘](#21-쉘-환경-변수environment-variables와-bash_profile-로딩-매커니즘)
  - [2.2 리눅스 계정과 그룹 관리 (`/etc/passwd`, `/etc/group`)](#22-리눅스-계정과-그룹-관리-etcpasswd-etcgroup)
  - [2.3 POSIX 파일 권한 (rwx 8진수 계산법: 770, 775, 750, 660)](#23-posix-파일-권한-rwx-8진수-계산법-770-775-750-660)
  - [2.4 ACL (Access Control Lists) 확장 권한의 필요성과 작동 원리](#24-acl-access-control-lists-확장-권한의-필요성과-작동-원리)
  - [2.5 최소 권한 원칙(Least Privilege)과 SudoERS 보안 정책](#25-최소-권한-원칙least-privilege와-sudoers-보안-정책)
- [Part 3. 네트워크 및 서버 보안 요새화 (Hardening) Masterclass](#part-3-네트워크-및-서버-보안-요새화-hardening-masterclass)
  - [3.1 TCP/IP 프로토콜, IP 주소, 포트(Port), 소켓(Socket)의 원리](#31-tcpip-프로토콜-ip-주소-포트port-소켓socket의-원리)
  - [3.2 SSH 접속 포트를 22번에서 20022번으로 바꾸는 보안적 이유](#32-ssh-접속-포트를-22번에서-20022번으로-바꾸는-보안적-이유)
  - [3.3 Root 원격 접속 차단(`PermitRootLogin no`)이 필수인 이유](#33-root-원격-접속-차단permitrootlogin-no이-필수인-이유)
  - [3.4 UFW 방화벽 패킷 필터링 원리와 화이트리스트 포트 개방](#34-ufw-방화벽-패킷-필터링-원리와-화이트리스트-포트-개방)
- [Part 4. 프로세스 관제 및 시스템 메트릭 수집 기술](#part-4-프로세스-관제-및-시스템-메트릭-수집-기술)
  - [4.1 프로세스 생명주기: PID, Exit Code 0 vs Exit Code 1](#41-프로세스-생명주기-pid-exit-code-0-vs-exit-code-1)
  - [4.2 `pgrep`과 `ps` 명령어로 프로세스 CPU%, MEM% 추출하기](#42-pgrep과-ps-명령어로-프로세스-cpu-mem-추출하기)
  - [4.3 `ss` 및 `netstat`으로 TCP LISTEN 상태 감시하기](#43-ss-및-netstat으로-tcp-listen-상태-감시하기)
  - [4.4 POSIX 표준 포맷 (`df -P /`)을 통한 디스크 줄바꿈 방지 원리](#44-posix-표준-포맷-df-p-을-통한-디스크-줄바꿈-방지-원리)
  - [4.5 stat 명령어의 macOS(BSD) vs Linux(GNU) 파일 크기 호환 처리](#45-stat-명령어의-macosbsd-vs-linuxgnu-파일-크기-호환-처리)
- [Part 5. 관제 스크립트(`monitor.sh`) 줄별 완전 해설 (Line-by-Line Breakdown)](#part-5-관제-스크립트monitorsh-줄별-완전-해설-line-by-line-breakdown)
- [Part 6. 보너스 스크립트 완전 해설 (`report.sh` & `log_rotate_archive.sh`)](#part-6-보너스-스크립트-완전-해설-reportsh--log_rotate_archivesh)
  - [6.1 `report.sh`: Awk 프로그래밍 (BEGIN/Loop/END) 통계 연산 원리](#61-reportsh-awk-프로그래밍-beginloopend-통계-연산-원리)
  - [6.2 `log_rotate_archive.sh`: 7일 압축 및 30일 아카이브 삭제 보존 정책](#62-log_rotate_archivesh-7일-압축-및-30일-아카이브-삭제-보존-정책)
- [Part 7. 무인 자동화(Cron) 및 자동 검증 수트 (`run_tests.sh`)](#part-7-무인-자동화cron-및-자동-검증-수트-run_testssh)
- [Part 8. 초보자를 위한 리눅스 명령어 대백과사전 (Command Reference)](#part-8-초보자를-위한-리눅스-명령어-대백과사전-command-reference)
- [Part 9. 실무 트러블슈팅 및 종합 FAQ](#part-9-실무-트러블슈팅-및-종합-faq)

---

## Part 1. 컴퓨터 아키텍처와 리눅스 OS 기초

### 1.1 하드웨어 4대 자원(CPU, RAM, Disk, Network)의 역할
컴퓨터 내부에는 시스템이 동작하기 위한 4가지 핵심 하드웨어 자원이 존재합니다. 관제(Monitoring) 시스템은 이 4가지 자원이 한계치에 도달하지 않도록 실시간으로 감시하는 일을 합니다.

1. **CPU (Central Processing Unit - 연산 장치)**
   - 컴퓨터의 '두뇌'에 해당합니다. 프로그램의 명령어를 계산하고 실행합니다. CPU 사용률(CPU%)이 100%에 가까워지면 서버 전체가 느려집니다.
2. **RAM / Memory (Random Access Memory - 주기억 장치)**
   - 현재 실행 중인 프로그램과 데이터를 일시적으로 올려두는 '작업대'입니다. 메모리가 부족하면 서버가 멈추거나 프로세스가 강제로 종료(OOM Kill)됩니다.
3. **Disk / Storage (보조기억 장치)**
   - 파일, 데이터베이스, 로그를 영구적으로 저장하는 '창고'입니다. 디스크 공간 사용률(Disk Used%)이 100%가 되면 새로 로그를 쓸 수 없어 앱이 다운됩니다.
4. **Network (네트워크 통신)**
   - 외부 클라이언트와 데이터를 주고받는 '도로'입니다. 포트(Port)를 열어 신호를 수신(LISTEN)합니다.

---

### 1.2 왜 전 세계 서버의 90% 이상이 리눅스(Linux)를 사용하는가?
1. **무료 및 오픈소스(Open Source)**: 별도의 라이선스 비용이 들지 않으며, 전 세계 엔지니어들이 보안을 강화합니다.
2. **최소한의 자원 사용 (CLI 기반)**: 윈도우나 macOS처럼 마우스 아이콘이나 가려진 화면(GUI)을 띄우지 않고 오직 텍스트 명령어(CLI)만으로 동작하여, 똑같은 사양의 컴퓨터에서도 서버 성능을 최대 10배 이상 끌어올릴 수 있습니다.
3. **안정성과 지속성**: 한 번 켜면 몇 년 동안 재부팅 없이 연속으로 작동할 수 있는 안정성을 제공합니다. 본 과제에서는 가장 대표적인 서버용 리눅스 배포판인 **Ubuntu 24.04 LTS (또는 22.04 LTS)**를 기반으로 구축합니다.

---

### 1.3 리눅스 디렉터리 구조 표준(FHS) 완벽 해설 (`/`, `/var`, `/etc`, `/home`, `/bin`)
리눅스는 윈도우의 `C:\`, `D:\` 드라이브 개념이 없으며, 오직 최상위 루트 디렉터리인 **`/` (Root)**로부터 모든 파일과 폴더가 나뭇가지처럼 갈라져 나갑니다.

```text
 / (Root 디렉터리: 리눅스 최고의 뿌리)
 ├── bin/          : 사용자가 실행할 수 있는 기본 명령어 프로그램 (bash, ls, cat 등)
 ├── sbin/         : 관리자(root) 전용 시스템 명령 유틸리티 (ufw, iptables 등)
 ├── etc/          : 시스템 및 모든 프로그램의 설정 파일 저장소 (etc/ssh/sshd_config 등)
 ├── home/         : 일반 사용자들의 개인 홈 디렉터리 (home/agent-admin, home/agent-dev 등)
 ├── var/          : 시스템 운영 중 계속 크기가 변하는 가변 데이터 (var/log 로그 파일 등)
 └── tmp/          : 재부팅 시 자동으로 삭제되는 임시 저장 공간
```

- **과제 적용**: 본 프로젝트의 관제 로그는 가변 데이터 저장소인 **`/var/log/agent-app/monitor.log`** 경로에 기록하도록 설계되었습니다.

---

### 1.4 터미널(Terminal), 쉘(Shell), Bash의 관계 및 작동 원리
- **터미널(Terminal)**: 사용자가 명령어를 키보드로 입력하고 결과를 화면으로 보는 '껍데기 창(UI)'입니다.
- **쉘(Shell)**: 사용자가 입력한 명령어 문자열을 읽고 해석하여 리눅스 커널(Kernel)에게 전달해 주는 '번역기(Interpreter)'입니다.
- **Bash (Bourne-Again SHell)**: 리눅스 배포판에서 가장 기본적이고 널리 쓰이는 표준 쉘 프로그램의 이름입니다.

```text
[사용자 입력] ➡️ (터미널) ➡️ [Bash 쉘 번역기] ➡️ (Linux 커널) ➡️ [하드웨어 실행]
```

---

### 1.5 Shebang (`#!/bin/bash`) 선언의 깊은 의미
모든 쉘 스크립트 파일의 맨 첫 번째 줄에는 반드시 `#!/bin/bash`라는 문자열이 적혀 있습니다.

- **`#`**: 리눅스 주석 기호
- **`!`**: 뱅(Bang) 기호
- **`#!/bin/bash`**: "이 파일 아래에 작성된 모든 문장은 `/bin/bash` 프로그램에게 전달하여 해석하고 실행하라"는 필수 선언입니다. 이 선언이 없으면 쉘의 종류에 따라 문법 오류가 발생할 수 있습니다.

---

## Part 2. 리눅스 보안, 권한 및 환경 변수 완벽 마스터

### 2.1 쉘 환경 변수(Environment Variables)와 `~/.bash_profile` 로딩 매커니즘
- **환경 변수**: 운영체제 전체에서 모든 프로그램이 참조할 수 있는 '전역 사전'입니다.
- **`export AGENT_HOME="$HOME/agent-app"`**: 환경 변수를 선언하고 외부 프로세스로 전파(export)하는 명령어입니다.
- **`source ~/.bash_profile 2>/dev/null`**: 
  - `source` 명령어는 프로파일 파일에 적힌 환경 변수 설정들을 현재 실행 중인 쉘로 곧바로 불러와 적용합니다.
  - `2>/dev/null` 구문에서 `2`는 표준 에러(Stderr)를 의미하며, `/dev/null`은 리눅스의 '블랙홀/휴지통'입니다. 파일이 없어서 에러가 나더라도 화면에 출력하지 않고 조용히 무시하라는 의미입니다.

---

### 2.2 리눅스 계정과 그룹 관리 (`/etc/passwd`, `/etc/group`)
리눅스는 다중 사용자(Multi-User) 시스템입니다. 하나의 서버를 수십 명의 엔지니어가 동시에 사용할 수 있습니다.

1. **계정 정보 파일 (`/etc/passwd`)**: 시스템에 등록된 계정 이름, UID(사용자 번호), 기본 홈 디렉토리 정보 저장.
2. **그룹 정보 파일 (`/etc/group`)**: 여러 계정을 묶어서 관리하는 그룹 이름 및 GID(그룹 번호) 저장.
3. **본 미션의 계정 설계**:
   - `agent-admin`: 시스템 관리자 (Cron 무인 관제 실행자)
   - `agent-dev`: 관제 개발자 (`monitor.sh` 작성 및 관리자)
   - `agent-test`: QA 및 테스트 담당자

---

### 2.3 POSIX 파일 권한 (rwx 8진수 계산법: 770, 775, 750, 660)
리눅스는 3가지 접근 권한과 3 종류의 사용자로 권한을 표현합니다.

```text
[권한 종류]
• r (Read - 읽기)   : 숫자 4
• w (Write - 쓰기)  : 숫자 2
• x (eXecute - 실행): 숫자 1

[권한 대상 3그룹]
[소유자 (User)] [소유 그룹 (Group)] [기타 사용자 (Other)]
```

#### 자릿수별 계산 예시:
1. **770 (`rwxrwx---`)**:
   - 소유자: 4+2+1 = **7** (`rwx`)
   - 소유 그룹: 4+2+1 = **7** (`rwx`)
   - 기타 사용자: 0+0+0 = **0** (`---` 진입 불가)
   - *의미*: 소유자와 특정 그룹원만 읽고 쓸 수 있는 **민감 보안 폴더 (`api_keys`, `log`)**
2. **775 (`rwxrwxr-x`)**:
   - 소유자: **7** (`rwx`), 그룹: **7** (`rwx`), 기타: **5** (`r-x`)
   - *의미*: 모든 사용자가 협업할 수 있는 **공용 폴더 (`upload_files`)**
3. **750 (`rwxr-x---`)**:
   - 소유자: **7** (`rwx`), 그룹: **5** (`r-x`), 기타: **0** (`---`)
   - *의미*: 스크립트 작성자만 수정하고, 그룹원은 실행만 가능한 **관제 스크립트 (`bin/monitor.sh`)**

---

### 2.4 ACL (Access Control Lists) 확장 권한의 필요성과 작동 원리
리눅스의 기본 권한(소유자-그룹-기타)만으로는 "A그룹에게는 rwx를 주고 B그룹에게는 rx를 주는" 다중 그룹 설정이 불가능합니다.
이를 해결하기 위해 **ACL(접근 제어 목록)** 유틸리티가 사용됩니다.

- `setfacl -m g:agent-core:rwx /var/log/agent-app`: 기본 권한을 변경하지 않고, `agent-core` 그룹에게 명시적으로 `/var/log/agent-app` 디렉터리에 대한 `rwx` 확장 권한을 부여합니다.
- `getfacl [경로]`: 해당 파일/폴더에 설정된 ACL 확장 권한 목록을 조회합니다.

---

### 2.5 최소 권한 원칙(Least Privilege)과 SudoERS 보안 정책
- **최소 권한 원칙**: 업무를 수행하는 데 꼭 필요한 최소한의 권한만 주고, root 관리자 권한을 남발하지 않는 원칙입니다.
- **Sudo (`sudo`)**: `SuperUser DO`의 약자로, 일반 계정이 특정 관리자 명령을 실행할 때 임시로 root 권한을 빌려 실행하는 명령어입니다. 
- 본 과제에서는 관제 스크립트 실행 시 root 권한을 사용하지 않고 비루트 일반 계정(`agent-admin`, `agent-dev`)으로 실행하도록 설계되었습니다.

---

## Part 3. 네트워크 및 서버 보안 요새화 (Hardening) Masterclass

### 3.1 TCP/IP 프로토콜, IP 주소, 포트(Port), 소켓(Socket)의 원리
- **IP 주소**: 네트워크상에서 컴퓨터를 식별하는 '집 주소'입니다. (예: `127.0.0.1` = 자기 자신 컴퓨터, Loopback)
- **포트(Port)**: 컴퓨터 안에서 실행 중인 특정 프로그램으로 안내하는 '디지털 문 번호'입니다. (예: `15034`번 포트)
- **소켓(Socket)**: IP 주소와 포트 번호가 결합하여 실제 통신이 이뤄지는 통로 객체입니다. (예: `0.0.0.0:15034`)
- **LISTEN 상태**: 외부에서 신호가 올 때까지 문을 열어두고 대기하는 정상 수신 상태입니다.

---

### 3.2 SSH 접속 포트를 22번에서 20022번으로 바꾸는 보안적 이유
- 인터넷 환경에 원격 접속 서버를 열어두면 해커들의 자동화 스캔 프로그램(Bot)이 기본 포트인 **22번**으로 초당 수십 번씩 아이디/비밀번호를 대입해 보는 무차별 대입 공격(Brute-force)을 감행합니다.
- 포트를 **20022번**과 같은 비표준 포트로 변경하는 것만으로도 자동 공격 봇의 타겟에서 완전히 벗어나 99% 이상의 무차별 무단 접속 시도를 1차 차단할 수 있습니다.

---

### 3.3 Root 원격 접속 차단(`PermitRootLogin no`)이 필수인 이유
- `root` 계정의 이름을 해커는 이미 알고 있습니다. 따라서 root 접속이 허용되어 있다면 해커는 '비밀번호' 하나만 맞추면 서버 전체를 지배할 수 있게 됩니다.
- `/etc/ssh/sshd_config` 파일에서 `PermitRootLogin no`로 설정하면, 외부에서 root 이름으로 직접 로그인하는 시도 자체가 원천 차단됩니다.

---

### 3.4 UFW 방화벽 패킷 필터링 원리와 화이트리스트 포트 개방
- **UFW (Uncomplicated Firewall)**: 리눅스의 방화벽 관리 도구입니다.
- **기본 정책 (Default Deny)**: `sudo ufw default deny incoming` 명령어로 외부에서 들어오는 모든 접속 시도를 일단 전면 차단(Blackout)합니다.
- **화이트리스트(Whitelist) 개방**: 
  - `sudo ufw allow 20022/tcp` (원격 관리용 SSH 포트 허용)
  - `sudo ufw allow 15034/tcp` (애플리케이션 서비스 포트 허용)
  - 허용 목록에 등록된 2개의 포트 외의 모든 패킷은 방화벽 레벨에서 즉시 드롭(Drop)됩니다.

---

## Part 4. 프로세스 관제 및 시스템 메트릭 수집 기술

### 4.1 프로세스 생명주기: PID, Exit Code 0 vs Exit Code 1
- **PID (Process ID)**: 실행 중인 프로그램에 할당되는 고유 번호입니다.
- **종료 코드 (Exit Code)**: 스크립트나 프로그램이 종료될 때 OS에 전달하는 상태 결과값입니다.
  - **`exit 0`**: 정상 처리 완료 (Success)
  - **`exit 1` (또는 1 이상의 숫자)**: 오류 발생 및 비정상 종료 (Failure/Error)

---

### 4.2 `pgrep`과 `ps` 명령어로 프로세스 CPU%, MEM% 추출하기
- `pgrep -f "agent_app.py"`: 실행 중인 명령어 라인 중에서 `agent_app.py`를 포함하는 프로세스의 PID만 찾아냅니다.
- `ps -p [PID] -o %cpu=`: 해당 PID를 가진 프로세스의 현재 CPU 사용률(%) 숫자만 추출합니다.
- `ps -p [PID] -o %mem=`: 해당 PID를 가진 프로세스의 현재 메모리 사용률(%) 숫자만 추출합니다.

---

### 4.3 `ss` 및 `netstat`으로 TCP LISTEN 상태 감시하기
- **`ss -tuln` 옵션 분석**:
  - `-t`: TCP 소켓만 조회
  - `-u`: UDP 소켓만 조회
  - `-l`: 현재 수신 대기 중인(Listening) 포트만 필터링
  - `-n`: 서비스 이름(http 등) 대신 숫자 포트(15034)로 표기
- `ss` 명령어가 없는 구형/미니멀 리눅스 환경을 대비하여 `command -v ss` 구문으로 점검 후 `netstat -an` 명령어로 자동 호환 처리(Fallback)합니다.

---

### 4.4 POSIX 표준 포맷 (`df -P /`)을 통한 디스크 줄바꿈 방지 원리
- 리눅스 `df -h /` 명령어를 사용할 때 마운트 지점이 길면 결과가 2줄로 꺾여서 출력될 수 있습니다. 2줄로 꺾이면 스크립트가 5번째 열(사용률)을 파싱할 때 엉뚱한 문자를 읽어 오탐 오류가 발생합니다.
- **`-P` (POSIX 표준 포맷)** 옵션을 부여하면 어떤 긴 경로라도 무조건 **'단일 줄(Single line)'**로 출력되어 안정적으로 사용률 수치를 추출할 수 있습니다.

---

### 4.5 stat 명령어의 macOS(BSD) vs Linux(GNU) 파일 크기 호환 처리
파일 크기(바이트)를 측정할 때 리눅스(GNU)와 macOS(BSD)의 옵션이 다릅니다.
- **Linux (GNU stat)**: `stat -c%s monitor.log`
- **macOS (BSD stat)**: `stat -f%z monitor.log`

스크립트 내부에서 `if stat -c%s ...` 조건 분기를 수행하여 어떤 호스트 OS에서 실행하더라도 에러 없이 파일 크기를 측정하도록 예외 처리되었습니다.

---

## Part 5. 관제 스크립트(`monitor.sh`) 줄별 완전 해설 (Line-by-Line Breakdown)

이 장에서는 [`bin/monitor.sh`](file:///Users/gdone/dev/codyssey/linux-system-monitor/bin/monitor.sh) 전체 소스 코드를 라인별로 깊이 있게 해설합니다.

```bash
1: #!/bin/bash
2: # ==============================================================================
3: # 시스템 관제 자동화 스크립트 (monitor.sh)
4: # ==============================================================================
```
- **해설 (L1-4)**: Bash 쉘 해석기 선언 및 프로젝트 헤더 주석입니다.

```bash
7: source ~/.bash_profile 2>/dev/null
```
- **해설 (L7)**: Cron 백그라운드 구동 시 유실되는 사용자 환경 변수를 로드합니다. 에러 메시지는 `/dev/null`로 버립니다.

```bash
11: CURRENT_USER=$(whoami)
12: AGENT_HOME="${AGENT_HOME:-$HOME/agent-app}"
13: AGENT_LOG_DIR="${AGENT_LOG_DIR:-$AGENT_HOME/log}"
14: AGENT_PORT="${AGENT_PORT:-15034}"
15: APP_NAME="${APP_NAME:-agent_app.py}" 
16: LOG_FILE="$AGENT_LOG_DIR/monitor.log"
```
- **해설 (L11-16)**: 현재 계정을 확인하고 `${변수:-기본값}` 문법을 사용하여 동적 경로 및 환경 변수 기본값을 안전하게 세팅합니다.

```bash
20: mkdir -p "$AGENT_LOG_DIR"
```
- **해설 (L20)**: 로그 폴더가 없으면 에러 없이 자동으로 생성합니다.

```bash
29: PID=$(pgrep -f "$APP_NAME" | head -n 1)
30: if [ -z "$PID" ]; then
31:     echo "Checking process '$APP_NAME'... [FAILED]"
32:     TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
33:     echo "[$TIMESTAMP] [ERROR] Process '$APP_NAME' is NOT running!" >> "$LOG_FILE"
34:     exit 1
35: else
36:     echo "Checking process '$APP_NAME'... [OK] (PID: $PID)"
37: fi
```
- **해설 (L29-37)**: 프로세스가 켜져 있는지 감시합니다. PID가 없으면(`-z "$PID"`), 에러 로그를 남기고 `exit 1`로 스크립트를 비정상 종료합니다.

```bash
42: if command -v ss &>/dev/null; then
43:     PORT_CHECK=$(ss -tuln | grep -q ":$AGENT_PORT " && echo "OK" || echo "FAILED")
44: else
45:     PORT_CHECK=$(netstat -an | grep -q "\.$AGENT_PORT " && echo "OK" || echo "FAILED")
46: fi
```
- **해설 (L42-46)**: 15034 포트 개방 여부를 `ss` 또는 `netstat`으로 점검합니다. 포트가 닫혀있으면 헬스체크 실패 처리됩니다.

```bash
78: if [[ "$OSTYPE" == "darwin"* ]]; then
79:     CPU_USAGE=$(ps -p $PID -o %cpu= | tr -d ' ' | awk '{print $1}')
80:     MEM_USAGE=$(ps -p $PID -o %mem= | tr -d ' ' | awk '{print $1}')
81: else
82:     CPU_USAGE=$(ps -p $PID -o %cpu= | tr -d ' ')
83:     MEM_USAGE=$(ps -p $PID -o %mem= | tr -d ' ')
84: fi
```
- **해설 (L78-84)**: macOS 및 Linux OS별로 `ps` 명령어 공백 출력 형태를 정제하여 정확한 CPU/MEM % 사용량을 계측합니다.

```bash
89: DISK_USED=$(df -P / | awk 'NR==2 {print $5}' | tr -d '%')
```
- **해설 (L89)**: POSIX 표준 포맷으로 루트 디스크 사용량 % 수치를 숫자로 잘라옵니다.

```bash
101: check_threshold() {
102:     awk -v val="$1" -v limit="$2" 'BEGIN { if (val > limit) exit 0; else exit 1; }'
103: }
```
- **해설 (L101-103)**: Bash의 정수 비교 한계를 극복하기 위해 `awk` 유틸리티로 실수(Float, 예: 25.3 > 20.0) 비교를 수행하는 헬퍼 함수입니다.

```bash
109: if check_threshold "$CPU_USAGE" "20.0"; then
110:     STATUS="WARNING"
111:     WARNING_MSG="[CPU threshold exceeded (${CPU_USAGE}% > 20%)]"
112: fi
```
- **해설 (L109-112)**: CPU 사용률이 20.0%를 초과하면 상태를 `WARNING`으로 변경하고 경고 메시지를 만듭니다.

```bash
130: if [ -f "$LOG_FILE" ]; then
131:     if stat -c%s "$LOG_FILE" >/dev/null 2>&1; then
132:         FILE_SIZE=$(stat -c%s "$LOG_FILE")
133:     else
134:         FILE_SIZE=$(stat -f%z "$LOG_FILE")
135:     fi
136:     if [ "$FILE_SIZE" -ge 10485760 ]; then
137:         rm -f "$LOG_FILE.11"
138:         for i in {9..1}; do
139:             if [ -f "$LOG_FILE.$i" ]; then
140:                 mv "$LOG_FILE.$i" "$LOG_FILE.$((i+1))"
141:             fi
142:         done
143:         mv "$LOG_FILE" "$LOG_FILE.1"
144:         touch "$LOG_FILE"
145:     fi
146: fi
```
- **해설 (L130-146)**: 로그 파일 크기가 10MB(10,485,760바이트)에 도달하면 11번째 옛날 로그는 지우고, 9번~1번 파일 이름을 1씩 늘려 밀어낸 뒤 새 `monitor.log` 파일을 생성하는 Log Rotation 순환 관리 알고리즘입니다.

```bash
157: TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
158: LOG_LINE="[$TIMESTAMP] [$STATUS] PID:$PID CPU:${CPU_USAGE}% MEM:${MEM_USAGE}% DISK_USED:${DISK_USED}%"
167: echo "$LOG_LINE" >> "$LOG_FILE"
171: exit 0
```
- **해설 (L157-171)**: 최종 규격화된 로그를 `monitor.log`에 저장하고 정상 종료(`exit 0`)합니다.

---

## Part 6. 보너스 스크립트 완전 해설 (`report.sh` & `log_rotate_archive.sh`)

### 6.1 `report.sh`: Awk 프로그래밍 (BEGIN/Loop/END) 통계 연산 원리
[`bin/report.sh`](file:///Users/gdone/dev/codyssey/linux-system-monitor/bin/report.sh)는 `monitor.log` 전체 데이터를 1번만 읽어 통계를 산출합니다.

1. **`BEGIN { ... }`**: 분석 시작 전 합계(`cpu_sum=0`), 최댓값(`cpu_max=-1`), 최솟값(`cpu_min=9999`) 변수 초기화.
2. **`{ ... } (라인별 루프)`**: 
   - `[2026-08-02 20:01:14]` 형태의 타임스탬프를 자르고, `CPU:10.2%`, `MEM:3.2%` 숫자만 파싱.
   - `cpu_sum += cpu_val` 로 누적 합산을 구함.
   - `if (cpu_val > cpu_max)` 이면 최댓값과 그 시각을 새로 기록함.
3. **`END { ... }`**: 
   - `cpu_avg = cpu_sum / count` 로 평균 계산.
   - `printf "Average : %.1f%%\n", cpu_avg` 로 소수점 1자리 통계 리포트 콘솔 출력.

---

### 6.2 `log_rotate_archive.sh`: 7일 압축 및 30일 아카이브 삭제 보존 정책
[`bin/log_rotate_archive.sh`](file:///Users/gdone/dev/codyssey/linux-system-monitor/bin/log_rotate_archive.sh)는 오래된 데이터를 관리합니다.

1. `find $LOG_DIR -mtime +7`: 수정된 지 7일(168시간) 초과된 구버전 로그 파일 검색.
2. `gzip -f [파일명]`: `monitor.log.1` (10MB) ➡️ `monitor.log.1.gz` (1~2MB)로 약 80% 이상 용량을 압축하여 아카이브 폴더로 이동.
3. `find $ARCHIVE_DIR -name "*.gz" -mtime +30`: 압축 보존 기간 30일이 지난 파일은 `rm -f`로 삭제하여 디스크 무한 방치 방지.

---

## Part 7. 무인 자동화(Cron) 및 자동 검증 수트 (`run_tests.sh`)

### 7.1 Crontab 5개 필드 표현식 (`* * * * *`) 해설
```text
 *       *       *       *       *       명령어
 │       │       │       │       │
 │       │       │       │       └───── 요일 (0-7, 0/7:일요일)
 │       │       │       └─────────── 월 (1-12)
 │       │       └────────────────일 (1-31)
 │       └───────────────────── 시 (0-23)
 └────────────────────────── 분 (0-59)
```
- `* * * * *` 설정은 **"매분 매시 매일"** 1분 주기로 관제 스크립트를 계속 실행하도록 지정합니다.

### 7.2 통합 자동화 검증 수트 (`tests/run_tests.sh`)
- 스크립트 문법(`bash -n`), 디렉터리 권한, 키 파일 내용, `monitor.sh`, `report.sh`, `log_rotate_archive.sh`, `04_cron_setup.sh` 7개 핵심 항목을 한 번에 자동 테스트하여 `PASS` / `FAIL`을判定합니다.

---

## Part 8. 초보자를 위한 리눅스 명령어 대백과사전 (Command Reference)

본 프로젝트 스크립트에서 사용된 모든 주요 리눅스 명령어 사전입니다:

1. **`cd` (Change Directory)**: 폴더 이동
2. **`mkdir -p`**: 디렉터리 생성 (부모 폴더까지 자동 생성)
3. **`chown -R 유저:그룹 경로`**: 파일/폴더의 소유자와 그룹 변경
4. **`chmod [권한숫자] 경로`**: 파일/폴더 권한 변경 (750, 770, 775 등)
5. **`setfacl -m g:그룹:rwx 경로`**: ACL 확장 권한 부여
6. **`sed -i 's/기존/변경/g' 파일`**: 파일 내용 검색 및 치환
7. **`grep -i "단어" 파일`**: 파일 안에서 특정 단어 포함 라인 검색
8. **`awk`**: 텍스트 데이터 추출 및 통계 연산 프로그래밍 언어
9. **`find [경로] -mtime +7`**: 7일 이상 된 파일 탐색
10. **`gzip -f 파일`**: 파일 압축 (`.gz` 생성)
11. **`crontab -l / -e`**: 무인 스케줄러 목록 조회 및 편집
12. **`ps -p PID -o 옵션=`**: 프로세스 자원 사용량 추출
13. **`df -P`**: POSIX 한 줄 포맷 디스크 사용량 조회
14. **`ss -tuln`**: 네트워크 소켓 리슨 상태 조회
15. **`pgrep -f 프로세스명`**: 프로세스 ID(PID) 조회

---

## Part 9. 실무 트러블슈팅 및 종합 FAQ

### Q1. Cron으로 등록했는데 `monitor.log`에 로그가 안 쌓여요!
- **원인**: Cron 실행 시 환경 변수(`AGENT_HOME`)가 로드되지 않아 스크립트 내부에서 경로를 찾지 못하는 현상입니다.
- **해결**: `monitor.sh` 상단에 `source ~/.bash_profile 2>/dev/null` 구문이 들어있는지 확인하세요.

### Q2. `awk: syntax error` 나 `stat` 인자 에러가 발생해요!
- **원인**: macOS(BSD 유틸리티)와 Linux(GNU 유틸리티) 간의 명령어 옵션 차이입니다.
- **해결**: 본 프로젝트는 `OSTYPE` 조건 분기 및 POSIX 표준 호환 구문이 적용되어 있어 두 환경 모두에서 에러 없이 실행됩니다.

---

이 **`manual.md` 대형 교재 설명서** 하나만으로 리눅스 인프라 기초부터 관제 자동화의 모든 원리를 완벽하게 독학하실 수 있습니다!
