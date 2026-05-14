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
    * **서비스 헬스체크:** `monitor.sh` 스크립트를 통해 프로세스(PID) 생존 여부와 서비스 포트 응답 상태를 실시간 감시
    * **리소스 메트릭 수집:** CPU, Memory, Disk 사용량을 수집하고, 설정된 임계치 초과 시 경고(`[WARNING]`)를 발생시키는 관제 로직 구현
    * **로깅 전략 수립:** `2>&1` 리다이렉션을 활용하여 표준 출력과 에러를 통합하고, 데이터 누적 및 보존을 위한 로깅 정책 적용

* **무인 운영 파이프라인 구축 (Job Scheduling)**
    * **작업 스케줄링:** `Crontab`을 활용하여 1분 단위로 관제 스크립트를 자동 실행하고, 백그라운드 실행 시 환경 변수(`AGENT_HOME` 등) 누락 방지 최적화
    * **IaC(Infrastructure as Code) 지향:** 수동 설정을 배제하고 전체 구축 과정을 모듈형 쉘 스크립트(`01_env`, `02_security`, `03_user` 등)로 자산화하여 환경 재현성 확보

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
    * 애플리케이션(`agent_app`) 및 관제 스크립트(`monitor.sh`) 실행 시 루트 권한을 엄격히 배제함.
    * 특정 서비스 계정(`agent-admin`, `agent-dev`)을 활용하여 프로세스를 격리함으로써, 잠재적인 시스템 침해 사고 시 피해 범위를 해당 계정의 권한 내로 국한함.
* **환경 변수 자산화:**
    * `/etc/profile.d/agent-app.sh`를 통해 시스템 전역 환경 변수를 관리하여, 어떤 쉘 세션에서도 관제 경로(`AGENT_HOME`)와 포트 정보가 일관되게 유지되도록 설계함.

---

## 3. 수행 체크리스트 (Task Checklist)

### 3.1 단계별 마일스톤

**Step 1: 리눅스 기초 환경 구축 및 자산 초기화**
* [x] 시스템 패키지 최신화: apt update/upgrade 및 필수 도구(cron, ufw, acl, ssh) 일괄 설치
* [x] 관제 환경 변수 설계: /etc/profile.d/를 이용한 AGENT_HOME, AGENT_PORT 등 전역 변수 등록
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
* [x] 헬스체크 로직 구현: 서비스 프로세스(PID) 존재 여부 및 네트워크 포트 응답 상태 확인 기능
* [x] 리소스 임계치 경보 설계: CPU(20%), MEM(10%), Disk(80%) 초과 시 로그 내 [WARNING] 발생 로직
* [x] 로깅 전략 적용: 로그 파일 크기 제한(10MB) 및 최대 10개 파일 유지(Log Rotation 개념) 적용

---

**Step 5: 무인 자동화 및 통합 운영 환경 등록**
* [x] Crontab 스케줄링 등록: agent-admin 권한으로 1분 단위 관제 스크립트 실행 스케줄 설정
* [x] 실행 환경 보정: Cron 백그라운드 환경 변수 로드 문제 해결을 위한 source 명령 보완
* [x] 통합 제어 마스터 구축: 전체 프로세스를 한 번에 제어하고 상태를 확인하는 master.sh 구성

### 3.2 작업 증적(Evidence) 매핑 테이블
| 대분류 | 중분류 항목 | 검증 도구/방법 | 상태 |
| :--- | :--- | :--- | :---: |
| **환경구축** | 패키지 및 환경변수 | `dpkg -l`, `printenv` | ✅ |
| **보안강화** | SSH & UFW 설정 | `sshd -T`, `ufw status` | ✅ |
| **권한설계** | RBAC 및 계정 격리 | `id [User]`, `getfacl` | ✅ |
| **관제개발** | 리소스 모니터링 | `tail -f monitor.log` | ✅ |
| **자동화** | Crontab 상시 가동 | `crontab -l`, `grep CRON` | ✅ |

---

## 4. 프로젝트 아키텍처 및 구조 (Structure)

### 4.1 디렉토리 계층 구조 (Tree)

```text
.
├── master.sh                   # [Main] 전체 프로젝트 통합 관제 및 오케스트레이터
├── setup/                      # [Provisioning] 인프라 초기화 스크립트 모듈
│   ├── 01_env_setup.sh         # OS 환경 및 패키지 최적화
│   ├── 02_security_setup.sh    # SSH 하드닝 및 UFW 화이트리스트 구성
│   └── 03_user_setup.sh        # RBAC 계정 설계 및 권한 격리
├── bin/                        # [Execution] 런타임 실행 바이너리 및 스크립트
│   ├── agent_app.py            # 관제 대상 메인 애플리케이션
│   └── monitor.sh              # 핵심 관제 엔진 (Resource & Health Check)
├── conf/                       # [Configuration] 시스템 설정 및 환경 변수 관리
│   └── agent_env.conf          # 관제 임계치 및 경로 설정 파일
├── api_keys/                   # [Security] 민감 정보 격리 (agent-core 전용 / 권한: 700)
│   └── t_secret.key            # 앱 구동 인증용 마스터 보안 키
├── log/                        # [Logging] 시스템 운영 기록 (agent-core 소유)
│   ├── monitor.log             # 관제 메트릭 수집 및 경고 로그
│   └── cron.log                # 스케줄러 실행 및 에러 기록
├── upload_files/               # [Storage] 공용 업로드 데이터 저장소
└── README.md                   # 기술 문서

```

### 4.2 디렉토리 구조 설계 근거 (Design Rationale)

본 프로젝트의 디렉토리 구조는 실무 서버 운영의 안정성과 확장성을 확보하기 위해 다음 4가지 핵심 설계 원칙을 준수합니다.

---

**1) 설치 로직과 실행 로직의 분리 (Provisioning vs Execution)**
* **설계:** 초기 인프라 구축 및 보안 설정을 담당하는 스크립트를 `setup/` 디렉토리로 격리하고, 실제 상시 가동되는 관제 로직은 `bin/`에 배치함.
* **이점:** 시스템 구축 완료 후 관리자가 운영 단계에서 설정 스크립트를 실수로 재실행하여 발생할 수 있는 '환경 오염(Configuration Drift)' 및 중복 설정을 원천 방지함.

**2) 비휘발성 설정의 중앙 집중화 (Configuration Management)**
* **설계:** 스크립트 코드 내부에 하드코딩(Hard-coding)되던 관제 임계치(예: CPU 20%, Disk 80%)와 환경 변수를 `conf/` 디렉토리 내 독립된 설정 파일로 분리함.
* **이점:** 운영 환경의 변화에 따라 관제 정책을 변경해야 할 때, 실행 로직(Code)을 수정하지 않고 설정값(Data)만 변경하여 즉시 적용할 수 있는 유연성을 확보함.

**3) 데이터 성격에 따른 권한 격리 (Access Control Enforcement)**
* **설계:** 시스템의 핵심 자산인 `api_keys/`와 운영 데이터인 `log/`를 별도 디렉토리로 구성하고, `agent-core` 그룹 전용 권한을 부여하여 관리함.
* **이점:** `agent-test`와 같은 일반/테스트 계정이 시스템의 인증 키를 탈취하거나 운영 기록을 변조할 수 없도록 물리적·논리적 접근 벽(Wall)을 세워 보안성을 극대화함.

**4) 로그 관리의 표준화 (Standardized Logging)**
* **설계:** 시스템 표준 경로인 `/var/log`와 별도로, 프로젝트 루트 내에 전용 `log/` 디렉토리를 유지하거나 심볼릭 링크로 연결하여 관리함.
* **이점:** 관제 데이터를 한곳에서 집중 모니터링할 수 있어 트러블슈팅 속도가 향상되며, 향후 ELK Stack이나 Splunk와 같은 외부 로그 분석 솔루션과의 연동 확장이 용이함.

---

## 5. 실행 및 자동화 가이드 (Implementation)

### 5.1 리눅스 실습 환경 구축 및 선택 근거

관제 시스템의 안정적인 운영을 위해서는 호스트 OS와 게스트 OS 간의 리소스 간섭이 적고, 커널 수준의 보안 설정이 완벽히 지원되는 환경이 필수적입니다.

**5.1.1 실습 환경 선택 기준 (안정성, 호환성, 가용성)**
* **안정성(Stability):** 인텔 맥 환경에서 커널 패닉이나 예기치 않은 종료 없이 24/7 관제 스크립트 실행이 가능한가?
* **호환성(Compatibility):** Ubuntu 24.04 LTS의 최신 패키지(`UFW`, `ACL`) 및 시스템 콜을 완벽하게 재현하는가?
* **가용성(Availability):** 가상 머신의 스냅샷 및 복구 기능이 제공되어 환경 오염 시 즉각적인 롤백이 가능한가?

**5.1.2 macOS + OrbStack Ubuntu 구성**
* **특징:** Docker Desktop 대비 월등히 낮은 메모리 점유율과 빠른 부팅 속도 제공.
* **적용:** Ubuntu 24.04 LTS 이미지를 활용하여 관제 전용 VM(`agent-server`) 생성.

**5.1.3 Windows + WSL2 Ubuntu 구성 (대체 방안)**
윈도우 환경에서는 WSL2 기반의 인프라 구축이 가능합니다.
* **장점:** 호스트 파일 시스템과의 빠른 통합 및 가상화 오버헤드 최소화.
* **제약:** 일부 보안 설정(`UFW`) 적용 시 윈도우 자체 방화벽 정책과의 충돌 가능성이 존재하여 별도의 정밀 설정이 필요합니다.

**5.1.4 전통적 가상화(VMware/VirtualBox) 환경 검토**
과거 표준이었던 전가상화(Full Virtualization) 방식의 도구들을 검토하였으나, 본 프로젝트에서는 제외하였습니다.
* **성능적 한계:** 인텔 맥 하드웨어에서 하이퍼바이저가 커널 전체를 에뮬레이션하므로 CPU 점유율이 급증하고 발열이 심각합니다.
* **운영 편의성:** OrbStack 대비 부팅 속도가 느리고 호스트-게스트 간의 통합 설정이 까다로워 신속한 실습에 부적합합니다.

**5.1.5 클라우드(AWS/GCP) 환경 검토**
로컬 인프라의 대안으로 퍼블릭 클라우드 인스턴스 활용 가능성을 분석하였습니다.
* **장점:** 고정 퍼블릭 IP 제공으로 외부 접속이 용이하며 로컬 시스템 리소스를 전혀 점유하지 않습니다.
* **단점:** 무료 티어 종료 후 비용 발생 위험이 있으며, 네트워크 레이턴시로 인해 터미널 반응 속도가 저하될 수 있어 보조 수단으로만 설정합니다.

**5.1.6 시스템 무결성을 위한 공통 필수 패키지 설치**
OS 설치 직후, 관제와 보안 미션 수행을 위한 핵심 도구들을 준비하는 필수 단계입니다.
```bash
# 1. 패키지 목록 업데이트 및 기존 패키지 최신화
sudo apt update && sudo apt upgrade -y

# 2. 핵심 도구 일괄 설치
# - openssh-server: 보안 접속 / ufw: 네트워크 요새화 / cron: 자동화 스케줄러
# - acl: 계정별 권한 제어 / procps, iproute2: 시스템 상태 조회 유틸리티
sudo apt install -y openssh-server ufw cron acl procps iproute2 vim curl
```

**5.1.7 초기 환경 점검 및 증거(Evidence) 기록**
설치된 인프라가 미션 수행 요구사항을 완벽히 충족하는지 데이터를 통해 확증하고 기록

```bash
# [검증 1] OS 정보 및 아키텍처 확인: Ubuntu 24.04 및 x86_64(인텔) 환경인지 점검
cat /etc/os-release && uname -a

# [검증 2] 필수 서비스 가동 상태: SSH와 Cron 데몬이 'active (running)' 상태인지 확인
systemctl status ssh cron

# [검증 3] 네트워크 인터페이스 및 포트: 할당된 IP 주소와 서비스 대기(Listen) 포트 확인
ip addr | grep inet
ss -tln
```

**5.1.8 환경별 대체 방안 수립**
메인 가상 머신(VM) 가동이 불가능한 긴급 상황이나 시스템 리소스 부족 상황에 대비한 '비상 운영 전략(Plan B)'입니다.
* **대응 전략:** VM 운영이 어려울 경우 가벼운 Docker 컨테이너(Ubuntu Image)를 활용하여 즉각적으로 실습 환경을 복구합니다.
* **유연성 확보:** 어떤 환경(VM, Container, Cloud)에서도 동일한 쉘 스크립트가 작동하도록 모든 경로를 변수화하여 인프라 독립성을 구현합니다.

**5.1.9 Docker 기반 선택 실습 환경 구성**
컨테이너 환경에서 미션을 수행할 경우 발생할 수 있는 운영체제 커널 권한의 제약 사항을 사전에 관리합니다.
* **격리성 활용:** 호스트 OS에 영향을 주지 않고 관제 애플리케이션만 독립적으로 구동하여 테스트하기에 최적화된 환경입니다.
* **기술적 보완:** 컨테이너 내부에서는 `systemctl` 명령어가 제한될 수 있으므로, 서비스 실행 방식을 `service` 명령어 혹은 포그라운드(Foreground) 실행 방식으로 조정하여 대응합니다.

**5.1.10 환경 구축 명령어 실행 구조 및 자산화**
인프라 구축의 모든 과정을 체계화하여 인적 오류를 방지하고 100% 동일한 환경 재현성을 보장합니다.
* **실행 표준 순서:** 패키지 레포지토리 업데이트 → 필수 보안 패키지 설치 → 핵심 서비스(데몬) 활성화 → 전역 환경 변수 주입.
* **코드화(IaC):** 이 모든 명령어 흐름을 `setup/01_env_setup.sh` 파일에 담아 관리함으로써, 복잡한 타이핑 없이 단 한 번의 실행으로 표준 서버 환경 구축을 완료합니다.

---

## 6. 요구사항 수행 결과 및 검증 (Evidence)

### 6.1 인프라 환경 및 패키지 무결성 검증

실제 OrbStack VM에서 수행한 기초 환경 구축 결과를 데이터로 증명합니다.

```text
# [검증 1] OS 및 커널 정보 확인 (README 5.1.7 준수)
$ cat /etc/os-release | grep PRETTY_NAME
PRETTY_NAME="Ubuntu 24.04 LTS"

# [검증 2] 필수 패키지 설치 상태 확인 (README 5.1.6 준수)
$ dpkg -l | grep -E "ssh|ufw|cron|acl" | awk '{print $2, $3}'
openssh-server 1:9.6p1-3ubuntu13
ufw 0.36.2-1
cron 3.0pl1-151ubuntu1
acl 2.3.2-1build1

```

### 6.2 디렉토리 구조 및 환경 변수 활성화 검증

설계한 아키텍처와 변수가 시스템에 올바르게 주입되었는지 확인합니다.

```bash
# [검증 3] AGENT_HOME 하위 디렉토리 생성 결과 (README 4.1 준수)
$ ls -F $AGENT_HOME
api_keys/  bin/  conf/  log/  setup/  upload_files/

# [검증 4] 전역 환경 변수 로드 확인
$ env | grep AGENT
AGENT_HOME=/home/ubuntu/agent-app
AGENT_LOG_DIR=/var/log/agent-app
AGENT_PORT=15034

```

---

## 7. 트러블슈팅 (Troubleshooting)

### 7.1 `.bash_profile` 환경 변수 미반영 오류

* **문제:** 스크립트 실행 후 `echo $AGENT_HOME` 결과가 공백으로 나옴.
* **원인:** 스크립트가 파일을 수정만 했을 뿐, 현재 실행 중인 쉘 세션에는 변경 사항이 로드되지 않음.
* **해결:** `source ~/.bash_profile` 명령어를 명시적으로 실행하여 즉시 반영 완료.

### 7.2 SSH 포트 변경 후 접속 불가 우려

* **문제:** 포트 변경 후 방화벽(UFW)을 먼저 켤 경우 본인의 접속이 차단될 위험이 있음.
* **해결:** `ufw enable` 전 `ufw allow 20022/tcp`를 우선 실행하는 순서의 강제화를 통해 서비스 가용성을 유지함.

### 7.3 Cron 실행 환경의 독립성 이슈

* **문제:** 터미널에서는 정상인 스크립트가 Cron에서 실행 시 환경 변수 미인식으로 실패함.
* **해결:** 스크립트 내부에 `source ~/.bash_profile`을 명시적으로 호출하거나 절대 경로를 사용하여 실행 환경을 보정함.

---

## 8. 기술적 제언 및 향후 과제 (Insights)

### 8.1 로그 순환(Rotation) 정책 고도화

현재는 `>>`를 통해 누적하고 있으나, 장기 운영 시 디스크 풀(Full) 장애를 방지하기 위해 `logrotate` 도구를 연동한 크기 기반 순환 정책 도입을 제언함.

### 8.2 알림 시스템 연동

리소스 임계치 초과(`WARNING`) 시 로그 기록에 그치지 않고, Webhook을 활용하여 슬랙(Slack)이나 이메일로 즉시 알림을 발송하는 파이프라인 확장이 필요함.

---

## 9. 제출 및 참고 자료 (Submission)

### 9.1 최종 제출 결과물

* **스크립트:** `setup/01_env_setup.sh` (인프라 자동 구축용)
* **로그 파일:** `$AGENT_LOG_DIR/setup.log` (구축 과정 증빙 자료)
* **기술 문서:** `README.md` (본 지식 창고 문서)
