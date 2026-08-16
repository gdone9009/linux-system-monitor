#!/bin/bash
# =================================================================
# Script Name: 03_user_setup.sh
# Description: RBAC(역할 기반 접근 제어) 계정 생성 및 디렉토리 권한(ACL) 설정
# =================================================================

# [사전 준비] 환경 변수 로드 확인 및 동적 경로 설정
source ~/.bash_profile 2>/dev/null
AGENT_HOME="${AGENT_HOME:-$HOME/agent-app}"

echo "👤 알림: 계정 설계 및 RBAC 권한 체계 구축을 시작합니다..."

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

# 3. 그룹 바인딩 (계정별 역할 부여 - PDF 요구사항 준수)
# - agent-common 그룹: admin, dev, test 모두 포함 (공용 액세스)
# - agent-core 그룹: admin, dev 포함 (핵심 보안 자산 접근)
sudo usermod -aG agent-common agent-admin
sudo usermod -aG agent-common agent-dev
sudo usermod -aG agent-common agent-test
sudo usermod -aG agent-core agent-admin
sudo usermod -aG agent-core agent-dev

# 4. 필수 키 파일 생성 ($AGENT_HOME/api_keys/t_secret.key)
mkdir -p "$AGENT_HOME/api_keys"
echo "agent_api_key_test" | sudo tee "$AGENT_HOME/api_keys/t_secret.key" >/dev/null

# 5. 디렉토리 소유권 및 권한 격리 적용 (PDF 요구사항 준수)
echo "단계 4: 디렉토리 소유권 및 그룹 기반 권한 격리 적용 중..."

# 핵심 자산(api_keys, log): agent-core 그룹만 접근 가능 (770)
sudo chown -R agent-admin:agent-core "$AGENT_HOME/api_keys"
sudo chmod 770 "$AGENT_HOME/api_keys"
sudo chmod 660 "$AGENT_HOME/api_keys/t_secret.key"

sudo mkdir -p /var/log/agent-app
sudo chown -R agent-admin:agent-core /var/log/agent-app
sudo chmod 770 /var/log/agent-app

# 공용 데이터(upload_files): agent-common 그룹 R/W 가능 (775)
mkdir -p "$AGENT_HOME/upload_files"
sudo chown -R agent-admin:agent-common "$AGENT_HOME/upload_files"
sudo chmod 775 "$AGENT_HOME/upload_files"

# 6. monitor.sh 소유자 및 권한 설정 (소유자: agent-dev, 그룹: agent-core, 권한: 750)
if [ -f "$AGENT_HOME/bin/monitor.sh" ]; then
    sudo chown agent-dev:agent-core "$AGENT_HOME/bin/monitor.sh"
    sudo chmod 750 "$AGENT_HOME/bin/monitor.sh"
fi

# 7. ACL(Access Control List) 확장 권한 적용
echo "단계 5: ACL 확장 권한 설정 중..."
if command -v setfacl &>/dev/null; then
    sudo setfacl -m g:agent-core:rwx /var/log/agent-app 2>/dev/null || true
    sudo setfacl -m g:agent-common:rwx "$AGENT_HOME/upload_files" 2>/dev/null || true
fi

echo "------------------------------------------------"
echo "🔍 [권한 검증 결과] 주요 디렉토리 권한 상태:"
ls -ld "$AGENT_HOME/api_keys" /var/log/agent-app "$AGENT_HOME/upload_files"
echo "------------------------------------------------"
echo "🎉 완료: RBAC 계정 체계 및 권한 격리가 성공적으로 구축되었습니다."