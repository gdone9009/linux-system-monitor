# 📋 [시연 매뉴얼 & 기반지식] 1-1. SSH 보안 요새화 및 UFW 방화벽 구축

> **미션 항목**: 1-1. 기본 보안 및 네트워크 설정 (Hardening & Firewall)  
> **대상자**: 시연 평가를 준비하는 개발자 및 다른 사람에게 설명하는 진행자  
> **작성 목적**: 터미널 명령어를 차례대로 직접 실행하며 시연할 수 있는 절차서와, 각 기술의 엔지니어링 배경 지식을 통합 제공합니다.

---

## 🧠 1. 핵심 기반 지식 (Prerequisite Knowledge)

시연에 앞서 평가자나 타인에게 설명해야 하는 **3가지 핵심 기술 원리**입니다.

### 1.1 SSH(Secure Shell)와 포트 20022 변경의 보안적 이유
* **SSH의 역할**: 원격지에서 서버 터미널에 암호화된 터널로 접속하여 조종하는 핵심 관리 프로토콜입니다.
* **기본 22번 포트의 위험성**: 인터넷에 개방된 모든 서버의 22번 포트는 24시간 내내 해커의 무차별 대입 공격(Brute-force)과 자동 스캔 봇(Bot)의 타깃이 됩니다.
* **포트 20022 변경 효과**: 포트를 비표준 번호인 `20022`로 변경하면 노출도를 감추어 **자동 스캔 봇에 의한 무작위 침입 시도를 99% 이상 원천 차단**할 수 있습니다.

### 1.2 Root 원격 접속 차단 (`PermitRootLogin no`)의 필수성
* **Root 계정의 위협**: Root는 리눅스의 모든 파일과 설정을 지울 수 있는 절대 권한자입니다.
* **차단 이유**: 외부에서 `root` 아이디로 직접 원격 로그인이 허용되면 해커가 비밀번호 하나만 맞추면 서버 전체가 마비됩니다.
* **보안 정책**: 외부 접속은 반드시 일반 사용자 계정(`agent-admin`)으로만 받도록 하고, 관리자 권한이 필요할 때만 `sudo` 명령어로 권한을 승인받아 사용하는 것이 서버 보안의 기본 수칙입니다.

### 1.3 UFW 방화벽의 패킷 필터링과 화이트리스트(Whitelist) 원리
* **UFW(Uncomplicated Firewall)**: 리눅스 커널 수준 패킷 필터(Netfilter)를 제어하는 방화벽 유틸리티입니다.
* **기본 차단 정책 (`default deny incoming`)**: 외부에서 들어오는 모든 접속 시도를 일단 전면 차단합니다.
* **화이트리스트 개방**: `20022/tcp` (SSH 관리용)와 `15034/tcp` (앱 서비스용) 단 2개의 지정 포트만 명시적으로 허용 구멍을 뚫어 시스템 공격 표면(Attack Surface)을 최소화합니다.

---

## 🛠️ 2. 단계별 시연 매뉴얼 (Step-by-Step Live Demo Manual)

평가자 앞에서 아래 5개 단계를 순서대로 터미널에 입력하며 시연합니다.

### 📍 Step 1: 자동화 셋업 스크립트 실행
자동화된 보안 스크립트를 통해 SSH 포트 변경 및 UFW 설정을 적용합니다.

```bash
cd ~/dev/codyssey/linux-system-monitor
sudo bash setup/02_security_setup.sh
```

- **시연 멘트**: "02_security_setup.sh 스크립트를 통해 SSH 설정 파일 변경, 포트 오버라이드, UFW 방화벽 화이트리스트 적용을 일괄 실행하겠습니다."

---

### 📍 Step 2: SSH 설정 파일 변경 사항 검증
`sshd_config` 파일에 포트 20022 및 Root 차단이 올바르게 반영되었는지 확인합니다.

```bash
grep -E "^Port|^PermitRootLogin" /etc/ssh/sshd_config
```

- **예상 출력 결과**:
  ```text
  Port 20022
  PermitRootLogin no
  ```
- **시연 멘트**: "보시는 바와 같이 SSH 리스닝 포트가 20022로 변경되었으며, Root 원격 접속이 `no`로 엄격히 차단되어 있습니다."

---

### 📍 Step 3: SSH 소켓 20022 포트 LISTEN 상태 검증
실제 네트워크 레이어에서 20022번 포트가 수신 대기 중인지 감시합니다.

```bash
sudo ss -tulnp | grep 20022
```

- **예상 출력 결과**:
  ```text
  tcp   LISTEN   0   128   *:20022   *:*   users:(("sshd",pid=...,fd=...))
  ```
- **시연 멘트**: "`ss -tulnp` 명령어를 통해 SSH 데몬이 20022번 TCP 포트에서 정상적으로 LISTEN 대기 중인 것을 확인할 수 있습니다."

---

### 📍 Step 4: UFW 방화벽 정책 및 개방 포트 검증
방화벽이 활성화되어 있고 지정된 2개 포트만 개방되었는지 검증합니다.

```bash
sudo ufw status verbose
```

- **예상 출력 결과**:
  ```text
  Status: active
  Logging: on (low)
  Default: deny (incoming), allow (outgoing), disabled (routed)
  New profiles: skip

  To                         Action      From
  --                         ------      ----
  20022/tcp                  ALLOW IN    Anywhere
  15034/tcp                  ALLOW IN    Anywhere
  ```
- **시연 멘트**: "UFW 방화벽 상태가 `active`이며, 외부 패킷은 기본 차단(`deny incoming`) 상태에서 오직 `20022/tcp`와 `15034/tcp` 포트만 `ALLOW IN`으로 화이트리스트 개방되어 있습니다."

---

### 📍 Step 5: 통합 테스트 수트(`run_tests.sh`)로 1-1 검증 통과 증명
전체 시스템 테스트 수트를 실행하여 1-1 검증 항목이 PASS됨을 보입니다.

```bash
./tests/run_tests.sh
```

- **시연 멘트**: "통합 검증 스크립트를 통해 방금 구축한 보안 및 네트워크 설정이 100% PASS 판정을 받음을 증명합니다."
