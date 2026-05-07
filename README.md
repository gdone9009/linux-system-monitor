🚀 시스템 관제 자동화 스크립트 개발 (System Monitoring Automation)
서버 장애 발생 시 원인 분석을 데이터에 기반하여 수행할 수 있도록, 리눅스 보안 설정부터 시스템 리소스 관제 자동화까지 서버 엔지니어링의 전 과정을 구현한 프로젝트입니다.

📌 프로젝트 개요
단순한 명령어 실행을 넘어, 실제 현업 엔지니어의 서버 운영 프로세스를 모델링하여 보안-권한-관제-자동화 파이프라인을 구축하는 것을 목표로 합니다.

🛠️ 주요 시스템 설계
1. 보안 및 네트워크 설정 (Security Hardening)
외부 공격을 방어하고 허가된 통로만 이용하도록 서버를 요새화합니다.

SSH 설정: 기본 포트를 22에서 20022로 변경하고, Root 원격 로그인을 엄격히 차단합니다.

방화벽(UFW) 정책: 서비스 운영에 필수적인 포트(20022/TCP, 15034/TCP)만 개방하는 화이트리스트 정책을 적용합니다.

2. 계정 및 권한 체계 (RBAC Design)
최소 권한 원칙(Principle of Least Privilege)에 따라 계정별 접근 범위를 제어합니다.

사용자 계정: agent-admin(운영), agent-dev(개발), agent-test(QA)

그룹 정책: agent-common(전체 공유), agent-core(핵심 관리) 그룹으로 분리

디렉토리 설계:

$AGENT_HOME/upload_files: agent-common 그룹 R/W 가능

$AGENT_HOME/api_keys & /var/log/agent-app: agent-core 전용 R/W 가능

🚀 시작하기 (Quick Start)
1. 환경 변수 설정
애플리케이션 실행을 위해 필요한 환경 변수를 등록합니다.
```bash
export AGENT_HOME="/home/agent-admin/agent-app"
export AGENT_PORT=15034
export AGENT_LOG_DIR="/var/log/agent-app"
```

2. 자동화 등록 (Crontab)
agent-admin 계정에서 관제 스크립트가 매분 자동 실행되도록 등록합니다.

```bash
# crontab -e
* * * * * /home/agent-admin/agent-app/bin/monitor.sh
```

📂 프로젝트 구조
```Plaintext
.
├── bin/
│   └── monitor.sh       # 시스템 관제 자동화 스크립트
├── upload_files/        # 일반 공유 디렉토리
├── api_keys/            # 보안 키 관리 디렉토리
├── README.md            # 프로젝트 가이드 문서
└── report.sh            # (Bonus) 로그 통계 분석 리포트
```

⚠️ 제약 및 준수 사항
모든 자동화 스크립트는 Bash로만 작성되었습니다.

보안을 위해 애플리케이션은 반드시 비루트(Non-Root) 계정으로 실행합니다.

로그 관리 정책에 따라 최대 10MB/10개 파일 유지를 보장합니다.
