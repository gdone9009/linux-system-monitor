#!/bin/bash
# =================================================================
# Script Name: 03_user_setup.sh
# Description: RBAC(역할 기반 접근 제어) 계정 생성 및 디렉토리 권한(ACL) 설정
# Author: Jeong Chang-seok
# =================================================================

# 직접 경로를 입력 (가장 확실한 방법)
AGENT_HOME="/home/gdone90098008/agent-app"

echo "👤 알림: 계정 설계 및 RBAC 권한 체계 구축을 시작합니다..."

# [사전 준비] 환경 변수 로드 확인 (README 2.3 및 7.3 준수)
# sudo 실행 시 환경 변수가 누락되는 것을 방지하기 위해 프로파일을 강제로 로드합니다.
if [ -z "$AGENT_HOME" ]; then
    source ~/.bash_profile 2>/dev/null
    # 여전히 비어있다면 기본 경로 할당
    AGENT_HOME=${AGENT_HOME:-"/home/ubuntu/agent-app"}
fi

# 1. 시스템 그룹 생성
# -f 옵션을 사용하여 그룹이 이미 존재해도 에러를 발생시키지 않습니다. (멱등성 확보)
sudo groupadd -f agent-core
sudo groupadd -f agent-common

# 2. 용도별 사용자 생성 (비밀번호는 codyssey12!로 통일)
# 운영(admin), 개발(dev), 테스트(test) 계정을 각각의 목적에 맞게 생성합니다.
users=("agent-admin" "agent-dev" "agent-test")
for user in "${users[@]}"; do
    if ! id "$user" &>/dev/null; then
        sudo useradd -m -s /bin/bash "$user"
        echo "$user:codyssey12!" | sudo chpasswd
        echo "✅ 사용자 생성 완료: $user"
    else
        echo "ℹ️ 알림: $user 사용자가 이미 존재하므로 건너뜁니다."
    fi
done

# 3. 그룹 바인딩 (계정별 역할 부여)
# admin과 dev는 핵심 자산에 접근하는 core 그룹에, test는 공용 그룹에 배치합니다.
sudo usermod -aG agent-core agent-admin
sudo usermod -aG agent-core agent-dev
sudo usermod -aG agent-common agent-test

# 4. 디렉토리 소유권 및 표준 권한 설정 (README 4.2 준수)
echo "단계 4: 디렉토리 소유권 및 그룹 기반 권한 격리 적용 중..."

# 핵심 자산(api_keys, log): agent-core 그룹원만 접근 가능 (770)
sudo chown -R agent-admin:agent-core $AGENT_HOME/api_keys
sudo chown -R agent-admin:agent-core $AGENT_HOME/log
sudo chmod 770 $AGENT_HOME/api_keys
sudo chmod 770 $AGENT_HOME/log

# 공용 데이터(upload_files): 모든 그룹이 협업을 위해 접근 가능 (775)
sudo chown -R agent-admin:agent-common $AGENT_HOME/upload_files
sudo chmod 775 $AGENT_HOME/upload_files

# 5. ACL(Access Control List)을 통한 정밀 권한 주입
# 리눅스 기본 권한을 넘어, 특정 그룹에 대해 세밀한 접근 제어를 추가합니다.
echo "단계 5: ACL 확장 권한 설정 중..."
# log 디렉토리에 대해 agent-core 그룹에 명시적인 R-W-X 권한 부여
sudo setfacl -m g:agent-core:rwx $AGENT_HOME/log
# upload_files 디렉토리에 대해 agent-common 그룹에 읽기/실행 권한 부여
sudo setfacl -m g:agent-common:rx $AGENT_HOME/upload_files

echo "------------------------------------------------"
echo "🔍 [권한 검증 결과] 주요 디렉토리 권한 상태:"
ls -ld $AGENT_HOME/api_keys $AGENT_HOME/log $AGENT_HOME/upload_files
echo "------------------------------------------------"
echo "🎉 완료: RBAC 계정 체계 및 권한 격리가 성공적으로 구축되었습니다."