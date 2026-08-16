#!/bin/bash
# =================================================================
# Script Name: 04_cron_setup.sh
# Description: 1분 주기 무인 관제 자동화 Cron 등록 및 해제 스크립트
# =================================================================

source ~/.bash_profile 2>/dev/null
AGENT_HOME="${AGENT_HOME:-$HOME/agent-app}"
MONITOR_SCRIPT="$AGENT_HOME/bin/monitor.sh"

echo "⏰ 알림: Crontab 무인 관제 스케줄러 설정을 진행합니다..."

if [ ! -f "$MONITOR_SCRIPT" ]; then
    echo "⚠️ 경고: 관제 스크립트를 찾을 수 없습니다 ($MONITOR_SCRIPT)"
    echo "가상 경로 또는 현재 프로젝트 디렉토리 기반 등록을 준비합니다."
    MONITOR_SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/bin/monitor.sh"
fi

chmod +x "$MONITOR_SCRIPT" 2>/dev/null || true

# 1분 주기 Cron 작업 구문 정의
CRON_JOB="* * * * * $MONITOR_SCRIPT >/dev/null 2>&1"

# 기존 Crontab 백업 및 중복 등록 점검
CURRENT_CRON=$(crontab -l 2>/dev/null)

if echo "$CURRENT_CRON" | grep -Fq "$MONITOR_SCRIPT"; then
    echo "ℹ️ 알림: 이미 monitor.sh 스케줄이 Crontab에 등록되어 있습니다."
else
    (echo "$CURRENT_CRON"; echo "$CRON_JOB") | crontab -
    echo "✅ 성공: 1분 주기 무인 관제 스케줄이 Crontab에 정상 등록되었습니다."
fi

echo "------------------------------------------------"
echo "🔍 [현재 등록된 Crontab 스케줄]"
crontab -l | grep -F "$MONITOR_SCRIPT"
echo "------------------------------------------------"
