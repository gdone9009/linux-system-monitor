#!/bin/bash

# =================================================================
# Script Name: 01_env_setup.sh
# Description: 시스템 기초 환경 구축 및 필수 패키지 자동 설치
# Author: Jeong Chang-seok
# Date: 2026-05-15
# =================================================================

# 1. 환경 변수 정의 (README 5.1.2 및 5.2.2 기준)
export AGENT_HOME="/home/gdone90098008/agent-app"
export AGENT_LOG_DIR="/var/log/agent-app"

echo "알림: 인프라 구축 프로세스를 시작합니다..."

# 2. 시스템 레포지토리 업데이트 및 최신화 (README 5.1.6)
echo "단계 1: 패키지 목록 업데이트 및 시스템 업그레이드 중..."
sudo apt update && sudo apt upgrade -y

# 3. 필수 보안 및 관제 패키지 일괄 설치 (README 5.1.6)
echo "단계 2: 필수 패키지(SSH, UFW, Cron, ACL 등) 설치 중..."
sudo apt install -y openssh-server ufw cron acl procps iproute2 vim curl

# 4. 프로젝트 디렉토리 구조 생성 (README 4.1)
echo "단계 3: 프로젝트 디렉토리 구조 생성 중..."
mkdir -p $AGENT_HOME/{bin,setup,conf,api_keys,log,upload_files}

# 5. 시스템 로그 디렉토리 생성 및 권한 설정
echo "단계 4: 로그 디렉토리 생성 및 소유권 변경 중..."
sudo mkdir -p $AGENT_LOG_DIR
sudo chown $USER:$USER $AGENT_LOG_DIR

# 6. 전역 환경 변수 자산화 (README 5.2.2)
echo "단계 5: 시스템 프로파일에 환경 변수 등록 중..."
if ! grep -q "AGENT_HOME" ~/.bash_profile; then
    echo "export AGENT_HOME=\"$AGENT_HOME\"" >> ~/.bash_profile
    echo "export AGENT_PORT=15034" >> ~/.bash_profile
    echo "export AGENT_LOG_DIR=\"$AGENT_LOG_DIR\"" >> ~/.bash_profile
    echo "알림: .bash_profile에 환경 변수가 등록되었습니다."
fi

echo "완료: 인프라 기초 구축이 성공적으로 마무리되었습니다."
echo "주의: 'source ~/.bash_profile' 명령어를 실행하여 환경 변수를 적용하세요."