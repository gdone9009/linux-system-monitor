#!/bin/bash
# =================================================================
# Script Name: monitor.sh
# Description: 시스템 리소스 메트릭 수집 및 서비스 헬스체크 엔진
# =================================================================

# 1. 환경 변수 우선 로드 (기존에 설정된 변수가 있다면 가져옴)
source ~/.bash_profile 2>/dev/null

# 2. [핵심] 현재 계정에 맞게 경로 강제 재설정 (덮어쓰기 방지)
CURRENT_USER=$(whoami)
AGENT_HOME="/home/$CURRENT_USER/agent-app"
LOG_FILE="$AGENT_HOME/log/monitor.log"

# 3. 로그 디렉토리 생성 보장
mkdir -p "$AGENT_HOME/log"

# --- 이하 리소스 측정 로직 동일 ---
CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
MEM_USAGE=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

TIMESTAMP=$(date "+%Y-%m-%d %H:%M:%S")
STATUS="INFO"

# bc를 이용한 소수점 비교
if (( $(echo "$CPU_USAGE > 20" | bc -l) )) || (( $(echo "$MEM_USAGE > 10" | bc -l) )) || [ "$DISK_USAGE" -gt 80 ]; then
    STATUS="WARNING"
fi

PORT_CHECK=$(ss -tln | grep -w "15034" | wc -l)
APP_STATUS=$([ "$PORT_CHECK" -eq 0 ] && echo "DOWN" || echo "UP")

# 로그 기록 (정확한 LOG_FILE 경로 사용)
echo "[$TIMESTAMP] [$STATUS] CPU: ${CPU_USAGE}%, MEM: ${MEM_USAGE}%, DISK: ${DISK_USAGE}%, APP: $APP_STATUS" >> "$LOG_FILE"