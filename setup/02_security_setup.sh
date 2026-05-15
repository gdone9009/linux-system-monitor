#!/bin/bash
# =================================================================
# Script Name: 02_security_setup.sh
# Description: SSH 소켓 기반 포트 변경(20022) 및 UFW 요새화 (Ubuntu 24.04 대응)
# Author: Jeong Chang-seok
# =================================================================

echo "🛡️ 알림: 시스템 보안 요새화 및 SSH 소켓 오버라이드를 시작합니다..."

# 1. SSH 설정 파일 백업 및 수정
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak
sudo sed -i 's/^#*Port 22/Port 20022/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
echo "✅ 단계 1: sshd_config 포트(20022) 및 Root 접속 차단 설정 완료."

# 2. Systemd SSH 소켓 오버라이드 (핵심 이슈 해결)
# 최신 Ubuntu의 포트 22번 선점 문제를 해결하기 위해 소켓 설정을 강제 변경합니다.
sudo mkdir -p /etc/systemd/system/ssh.socket.d
sudo bash -c "cat <<EOF > /etc/systemd/system/ssh.socket.d/listen.conf
[Socket]
ListenStream=
ListenStream=20022
EOF"
echo "✅ 단계 2: SSH 소켓 오버라이드(Port 22 해제 및 20022 등록) 완료."

# 3. 시스템 엔진 리로드 및 서비스 재시작
sudo systemctl daemon-reload
sudo systemctl restart ssh.socket
sudo systemctl restart ssh
echo "✅ 단계 3: Systemd 데몬 리로드 및 SSH 서비스 재시작 완료."

# 4. UFW 방화벽 화이트리스트 구성
echo "단계 4: 방화벽 설정 중..."
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 20022/tcp
sudo ufw allow 15034/tcp
echo "y" | sudo ufw enable
echo "✅ 단계 4: UFW 활성화 및 보안 포트(20022, 15034) 개방 완료."

# 5. 최종 보안 무결성 검증
echo "------------------------------------------------"
echo "🔍 [보안 검증 결과] 리스닝 포트 현황:"
sudo ss -tlnp | grep 20022
echo "------------------------------------------------"
echo "🎉 완료: 모든 보안 하드닝 설정이 성공적으로 적용되었습니다."