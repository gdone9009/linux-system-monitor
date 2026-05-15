#!/bin/bash

# ==============================================================================
# 시스템 관제 자동화 스크립트 (monitor.sh)
# 코디세이 미션 4: 시스템 관제 자동화 스크립트 개발
# ==============================================================================

# 1. 환경 변수 로드 (Cron 백그라운드 실행 시 환경 변수 누락 방지)
source ~/.bash_profile 2>/dev/null

# 환경 변수 기본값 셋팅 (설정 안 되어 있을 경우를 대비한 Fallback)
AGENT_HOME="${AGENT_HOME:-/home/agent-admin/agent-app}"
AGENT_LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
AGENT_PORT="${AGENT_PORT:-15034}"
APP_NAME="agent_app.py" 
LOG_FILE="$AGENT_LOG_DIR/monitor.log"

echo "====== SYSTEM MONITOR RESULT ======"

# ------------------------------------------------------------------------------
# [3] HEALTH CHECK (실패 시 즉시 종료)
# ------------------------------------------------------------------------------
echo "[HEALTH CHECK]"

# 프로세스 구동 확인
PID=$(pgrep -f "$APP_NAME" | head -n 1)
if [ -z "$PID" ]; then
    echo "Checking process '$APP_NAME'... [FAILED]"
    exit 1
else
    echo "Checking process '$APP_NAME'... [OK] (PID: $PID)"
fi

# 포트 리슨 상태 확인 (TCP 15034)
if ! ss -tuln | grep -q ":$AGENT_PORT "; then
    echo "Checking port $AGENT_PORT... [FAILED]"
    exit 1
else
    echo "Checking port $AGENT_PORT... [OK]"
fi

# 방화벽(UFW) 활성화 상태 점검 (비활성 시 경고만 출력하고 종료하지 않음)
FW_STATUS=$(sudo ufw status 2>/dev/null | grep -i "Status: active")
if [ -z "$FW_STATUS" ]; then
    echo "[WARNING] UFW Firewall is NOT active!"
fi

# ------------------------------------------------------------------------------
# [4] RESOURCE MONITORING & LOGGING
# ------------------------------------------------------------------------------
echo ""
echo "[RESOURCE MONITORING]"

# 리소스 사용량 수집 (ps 및 df 명령어 활용)
# (참고: CPU와 MEM은 float 형태로 출력될 수 있음)
CPU_USAGE=$(ps -p $PID -o %cpu= | tr -d ' ')
MEM_USAGE=$(ps -p $PID -o %mem= | tr -d ' ')
DISK_USED=$(df -h / | tail -1 | awk '{print $5}' | tr -d '%')

echo "CPU Usage: ${CPU_USAGE}%"
echo "MEM Usage: ${MEM_USAGE}%"
echo "DISK Used: ${DISK_USED}%"

# float 숫자 비교를 위한 awk 헬퍼 함수
check_threshold() {
    awk -v val="$1" -v limit="$2" 'BEGIN { if (val > limit) exit 0; else exit 1; }'
}

# 임계치 초과 경고 알림 [WARNING]
if check_threshold "$CPU_USAGE" "20"; then
    echo "[WARNING] CPU threshold exceeded (${CPU_USAGE}% > 20%)"
fi

if check_threshold "$MEM_USAGE" "10"; then
    echo "[WARNING] MEM threshold exceeded (${MEM_USAGE}% > 10%)"
fi

if [ "$DISK_USED" -gt 80 ]; then
    echo "[WARNING] DISK threshold exceeded (${DISK_USED}% > 80%)"
fi

# ------------------------------------------------------------------------------
# [5] LOG ROTATION (최대 10MB, 10개 파일 유지)
# ------------------------------------------------------------------------------
mkdir -p "$AGENT_LOG_DIR"

if [ -f "$LOG_FILE" ]; then
    # 파일 크기가 10MB(10485760 bytes)를 넘는지 확인
    FILE_SIZE=$(stat -c%s "$LOG_FILE" 2>/dev/null)
    if [ "$FILE_SIZE" -ge 10485760 ]; then
        # 1번부터 9번까지 밀어내기 (monitor.log.1 ~ monitor.log.10)
        for i in {9..1}; do
            if [ -f "$LOG_FILE.$i" ]; then
                mv "$LOG_FILE.$i" "$LOG_FILE.$((i+1))"
            fi
        done
        mv "$LOG_FILE" "$LOG_FILE.1"
        touch "$LOG_FILE"
    fi
fi

# ------------------------------------------------------------------------------
# [6] SAVE LOG
# ------------------------------------------------------------------------------
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOG_LINE="[$TIMESTAMP] PID:$PID CPU:${CPU_USAGE}% MEM:${MEM_USAGE}% DISK_USED:${DISK_USED}%"

echo "$LOG_LINE" >> "$LOG_FILE"
echo "[INFO] Log appended: $LOG_FILE"

# 정상 종료
exit 0