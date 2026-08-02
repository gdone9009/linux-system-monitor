#!/bin/bash
# ==============================================================================
# 시스템 관제 자동화 스크립트 (monitor.sh)
# 코디세이 미션 4: 시스템 관제 자동화 스크립트 개발 (개선 및 완성 버전)
# ==============================================================================

# 1. 환경 변수 로드 (Cron 백그라운드 실행 시 환경 변수 누락 방지)
source ~/.bash_profile 2>/dev/null

# 2. 호스트 운영체제에 맞춤 경로 계산 및 환경 변수 기본값 설정
CURRENT_USER=$(whoami)
# macOS의 경우 /home 대신 /Users 이므로 $HOME 변수 우선 사용
AGENT_HOME="${AGENT_HOME:-$HOME/agent-app}"
AGENT_LOG_DIR="${AGENT_LOG_DIR:-$AGENT_HOME/log}"
AGENT_PORT="${AGENT_PORT:-15034}"
APP_NAME="agent_app.py" 
LOG_FILE="$AGENT_LOG_DIR/monitor.log"

# 로그 디렉토리 생성 보장
mkdir -p "$AGENT_LOG_DIR"

echo "====== SYSTEM MONITOR START ======"

# ------------------------------------------------------------------------------
# [3] HEALTH CHECK (프로세스 및 포트 검증 - 실패 시 즉시 종료)
# ------------------------------------------------------------------------------
echo "[HEALTH CHECK]"

# 3.1 프로세스 구동 확인
PID=$(pgrep -f "$APP_NAME" | head -n 1)
if [ -z "$PID" ]; then
    echo "Checking process '$APP_NAME'... [FAILED]"
    # 백그라운드에서 실행되지 않은 상태에서의 오류 로그 기록
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] [ERROR] Process '$APP_NAME' is NOT running!" >> "$LOG_FILE"
    exit 1
else
    echo "Checking process '$APP_NAME'... [OK] (PID: $PID)"
fi

# 3.2 포트 리슨 상태 확인 (TCP 15034)
# macOS와 Linux의 ss / netstat 호환성 확보를 위해 ss가 없으면 netstat 사용
if command -v ss &>/dev/null; then
    PORT_CHECK=$(ss -tuln | grep -q ":$AGENT_PORT " && echo "OK" || echo "FAILED")
else
    PORT_CHECK=$(netstat -an | grep -q "\.$AGENT_PORT " && echo "OK" || echo "FAILED")
fi

if [ "$PORT_CHECK" = "FAILED" ]; then
    echo "Checking port $AGENT_PORT... [FAILED]"
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] [ERROR] Port $AGENT_PORT is NOT listening!" >> "$LOG_FILE"
    exit 1
else
    echo "Checking port $AGENT_PORT... [OK]"
fi

# 3.3 방화벽(UFW) 활성화 상태 점검 (경고만 출력하고 스크립트는 중단하지 않음)
if command -v ufw &>/dev/null; then
    FW_STATUS=$(sudo ufw status 2>/dev/null | grep -i "Status: active")
    if [ -z "$FW_STATUS" ]; then
        echo "[WARNING] UFW Firewall is NOT active!"
    else
        echo "Checking Firewall... [OK]"
    fi
else
    echo "Checking Firewall... [SKIPPED] (ufw not installed)"
fi

# ------------------------------------------------------------------------------
# [4] RESOURCE MONITORING & LOGGING
# ------------------------------------------------------------------------------
echo ""
echo "[RESOURCE MONITORING]"

# 리소스 사용량 수집 (ps 및 df 명령어 활용)
# macOS와 Linux의 ps 옵션 차이를 감안하여 안전하게 파싱
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS ps
    CPU_USAGE=$(ps -p $PID -o %cpu= | tr -d ' ' | awk '{print $1}')
    MEM_USAGE=$(ps -p $PID -o %mem= | tr -d ' ' | awk '{print $1}')
else
    # Linux ps
    CPU_USAGE=$(ps -p $PID -o %cpu= | tr -d ' ')
    MEM_USAGE=$(ps -p $PID -o %mem= | tr -d ' ')
fi

# 디스크 사용량 수집 (df -P POSIX 포맷 활용으로 안전성 보장)
DISK_USED=$(df -P / | awk 'NR==2 {print $5}' | tr -d '%')

# float 값 빈 값 예외 처리
CPU_USAGE="${CPU_USAGE:-0.0}"
MEM_USAGE="${MEM_USAGE:-0.0}"
DISK_USED="${DISK_USED:-0}"

echo "Process CPU Usage: ${CPU_USAGE}%"
echo "Process MEM Usage: ${MEM_USAGE}%"
echo "System DISK Used: ${DISK_USED}%"

# float 숫자 비교를 위한 awk 헬퍼 함수
check_threshold() {
    awk -v val="$1" -v limit="$2" 'BEGIN { if (val > limit) exit 0; else exit 1; }'
}

STATUS="INFO"
WARNING_MSG=""

# 임계치 초과 경고 판정 (CPU > 20%, MEM > 10%, DISK > 80%)
if check_threshold "$CPU_USAGE" "20.0"; then
    STATUS="WARNING"
    WARNING_MSG="[CPU threshold exceeded (${CPU_USAGE}% > 20%)]"
    echo "$WARNING_MSG"
fi

if check_threshold "$MEM_USAGE" "10.0"; then
    STATUS="WARNING"
    WARNING_MSG="${WARNING_MSG} [MEM threshold exceeded (${MEM_USAGE}% > 10%)]"
    echo "[WARNING] MEM threshold exceeded (${MEM_USAGE}% > 10%)"
fi

if [ "$DISK_USED" -gt 80 ]; then
    STATUS="WARNING"
    WARNING_MSG="${WARNING_MSG} [DISK threshold exceeded (${DISK_USED}% > 80%)]"
    echo "[WARNING] DISK threshold exceeded (${DISK_USED}% > 80%)"
fi

# ------------------------------------------------------------------------------
# [5] LOG ROTATION (최대 10MB, 10개 파일 유지 및 10개 초과 자동 삭제 cleanup)
# ------------------------------------------------------------------------------
if [ -f "$LOG_FILE" ]; then
    # OS별 stat 명령어 옵션 호환 처리
    if stat -c%s "$LOG_FILE" >/dev/null 2>&1; then
        FILE_SIZE=$(stat -c%s "$LOG_FILE")
    else
        FILE_SIZE=$(stat -f%z "$LOG_FILE")
    fi

    # 10MB = 10,485,760 bytes
    if [ "$FILE_SIZE" -ge 10485760 ]; then
        echo "[LOG ROTATION] Log file size ($FILE_SIZE bytes) exceeds 10MB. Rotating logs..."
        # 10개 초과 파일 cleanup 삭제
        rm -f "$LOG_FILE.11"
        # 9번부터 1번까지 밀어내기 (monitor.log.9 -> monitor.log.10)
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
# [6] SAVE LOG & ALERT EVENT
# ------------------------------------------------------------------------------
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOG_LINE="[$TIMESTAMP] [$STATUS] PID:$PID CPU:${CPU_USAGE}% MEM:${MEM_USAGE}% DISK_USED:${DISK_USED}%"

if [ -n "$WARNING_MSG" ]; then
    LOG_LINE="$LOG_LINE Details: $WARNING_MSG"
    # WARNING 발생 시 이벤트 JSON 로그 추가 (옵션 확장)
    ALERT_JSON="$AGENT_LOG_DIR/alert_events.json"
    echo "{\"timestamp\":\"$TIMESTAMP\",\"status\":\"WARNING\",\"pid\":$PID,\"cpu\":\"$CPU_USAGE\",\"mem\":\"$MEM_USAGE\",\"disk\":$DISK_USED,\"details\":\"$WARNING_MSG\"}" >> "$ALERT_JSON"
fi

echo "$LOG_LINE" >> "$LOG_FILE"
echo "[INFO] Log appended: $LOG_FILE"
echo "====== SYSTEM MONITOR END ======"

# 정상 종료
exit 0