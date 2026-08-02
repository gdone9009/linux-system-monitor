#!/bin/bash
# ==============================================================================
# 📖 [초보자를 위한 교재용 해설] 시스템 관제 자동화 스크립트 (monitor.sh)
# ------------------------------------------------------------------------------
# 본 스크립트는 실제 리눅스 서버 환경에서 24시간 365일 무인으로 구동되며,
# 핵심 애플리케이션 서비스(PID, TCP 포트)의 생존 여부를 주기적으로 점검(Health Check)하고,
# CPU, Memory, Disk 리소스 사용량을 계측하여 로그 파일에 기록하는 엔지니어링 관제 스크립트입니다.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. 환경 변수 로드 (Cron 무인 실행 시 필수 처리)
# ------------------------------------------------------------------------------
# [개념 설명] Cron 스케줄러는 리눅스가 무인으로 백그라운드에서 명령어를 실행해 주는 유틸리티입니다.
# 그러나 Cron은 사용자의 로그인 쉘 환경(PATH 등)을 로드하지 않고 최소한의 환경에서만 동작합니다.
# 따라서 아래 'source' 명령어를 사용하여 환경 변수가 설정된 프로파일을 수동으로 끌어와 적용합니다.
source ~/.bash_profile 2>/dev/null

# ------------------------------------------------------------------------------
# 2. 경로 계산 및 기본 변수 선언 (동적 가용성 보장)
# ------------------------------------------------------------------------------
# [개념 설명] '${변수:-기본값}' 은 Bash 고유 문법으로, 변수가 설정되어 있지 않을 때만
# 우측의 기본값($HOME/agent-app)을 사용합니다. 이를 통해 하드코딩 오류를 완벽히 방지합니다.
CURRENT_USER=$(whoami)
AGENT_HOME="${AGENT_HOME:-$HOME/agent-app}"
AGENT_LOG_DIR="${AGENT_LOG_DIR:-$AGENT_HOME/log}"
AGENT_PORT="${AGENT_PORT:-15034}"
APP_NAME="${APP_NAME:-agent_app.py}" 
LOG_FILE="$AGENT_LOG_DIR/monitor.log"

# 로그를 저장할 디렉토리가 없으면 'mkdir -p' 옵션을 통해 부모 디렉토리까지 안전하게 만듭니다.
mkdir -p "$AGENT_LOG_DIR"

echo "====== SYSTEM MONITOR START ======"

# ------------------------------------------------------------------------------
# [3] HEALTH CHECK (서비스 프로세스 및 네트워크 포트 검증 - 실패 시 즉시 종료)
# ------------------------------------------------------------------------------
# [엔지니어링 원칙] 서비스가 죽어있다면 리소스 모니터링은 의미가 없으므로,
# 헬스체크 실패 시 에러 로그를 남기고 스크립트를 비정상 종료(exit 1)하여 빠른 원인 파악을 유도합니다.
echo "[HEALTH CHECK]"

# 3.1 프로세스 생존 검증
# [개념 설명] 'pgrep -f [프로세스명]'은 실행 중인 프로세스의 명령어 라인 전체에서 프로세스 ID(PID)를 찾습니다.
# 'head -n 1'은 여러 개의 프로세스가 탐색될 경우 가장 첫 번째 메인 프로세스 PID만 선택합니다.
PID=$(pgrep -f "$APP_NAME" | head -n 1)

if [ -z "$PID" ]; then
    # [조건문] PID 변수가 빈 문자열(-z)이라면 프로세스가 실행되지 않은 비정상 상태입니다.
    echo "Checking process '$APP_NAME'... [FAILED]"
    TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
    echo "[$TIMESTAMP] [ERROR] Process '$APP_NAME' is NOT running!" >> "$LOG_FILE"
    exit 1
else
    echo "Checking process '$APP_NAME'... [OK] (PID: $PID)"
fi

# 3.2 TCP 네트워크 포트 응답 검증
# [개념 설명] 서비스가 실행 중이라도 15034번 포트로 패킷을 받을 준비(LISTEN)가 안 되어 있으면 장애 상태입니다.
# 'ss -tuln' 옵션: t(TCP), u(UDP), l(Listening 상태만), n(포트 번호를 숫자로 표기)
# macOS 및 다양한 리눅스 환경의 호환성을 위해 'ss' 명령어가 없으면 'netstat' 유틸리티로 자동 전환됩니다.
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

# 3.3 방화벽(UFW) 활성화 상태 점검
# [개념 설명] UFW(Uncomplicated Firewall)는 리눅스 방화벽 관리 도구입니다.
# 방화벽은 꺼져 있더라도 서비스 자체는 구동되므로, 경고만 출력하고 스크립트를 중단하지는 않습니다.
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
# [4] RESOURCE MONITORING (시스템 및 프로세스 자원 수집)
# ------------------------------------------------------------------------------
echo ""
echo "[RESOURCE MONITORING]"

# [개념 설명] 'ps -p [PID] -o %cpu=' 옵션을 사용하면 해당 프로세스가 사용 중인 CPU % 수치만 깔끔하게 가져옵니다.
# macOS(darwin)와 Linux 간 ps 출력 형식 차이를 고려하여 tr 및 awk로 공백을 정제합니다.
if [[ "$OSTYPE" == "darwin"* ]]; then
    CPU_USAGE=$(ps -p $PID -o %cpu= | tr -d ' ' | awk '{print $1}')
    MEM_USAGE=$(ps -p $PID -o %mem= | tr -d ' ' | awk '{print $1}')
else
    CPU_USAGE=$(ps -p $PID -o %cpu= | tr -d ' ')
    MEM_USAGE=$(ps -p $PID -o %mem= | tr -d ' ')
fi

# [개념 설명] 'df -P /' 옵션에서 -P는 POSIX 표준 출력 포맷으로, 파일시스템 경로가 길더라도
# 줄바꿈 없이 무조건 한 줄로 출력하도록 보장하여 파싱 오탐을 방지합니다.
# 'awk NR==2 {print $5}'는 2번째 줄(헤더 제외 실제 데이터)의 5번째 열(사용률 %)을 가져옵니다.
DISK_USED=$(df -P / | awk 'NR==2 {print $5}' | tr -d '%')

# 변수 값이 비어있을 경우 발생할 수 있는 오류 방지 (기본값 설정)
CPU_USAGE="${CPU_USAGE:-0.0}"
MEM_USAGE="${MEM_USAGE:-0.0}"
DISK_USED="${DISK_USED:-0}"

echo "Process CPU Usage: ${CPU_USAGE}%"
echo "Process MEM Usage: ${MEM_USAGE}%"
echo "System DISK Used: ${DISK_USED}%"

# [개념 설명] Bash 쉘은 정수(Integer) 연산만 지원하고 실수(Float, 예: 25.3) 비교가 불가능합니다.
# 따라서 쉘 스크립트 내부에서 Awk 유틸리티를 호출하여 실수 비교를 수행합니다.
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
# [5] LOG ROTATION (로그 용량 관리: 최대 10MB, 10개 보존 한도 관리)
# ------------------------------------------------------------------------------
# [개념 설명] 서버가 오랫동안 작동하면 로그 파일이 수십 기가바이트(GB)로 커져 디스크가 가득 찰 수 있습니다.
# 이를 방지하기 위해 파일 크기가 10MB(10,485,760 bytes)에 도달하면 기존 로그를 이전 번호로 밀어내고
# 10개가 넘는 옛날 로그는 자동으로 삭제(cleanup)하는 로테이션 로직을 실행합니다.
if [ -f "$LOG_FILE" ]; then
    # OS별 stat 명령어 옵션 호환 처리 (Linux: stat -c%s / macOS: stat -f%z)
    if stat -c%s "$LOG_FILE" >/dev/null 2>&1; then
        FILE_SIZE=$(stat -c%s "$LOG_FILE")
    else
        FILE_SIZE=$(stat -f%z "$LOG_FILE")
    fi

    if [ "$FILE_SIZE" -ge 10485760 ]; then
        echo "[LOG ROTATION] Log file size ($FILE_SIZE bytes) exceeds 10MB. Rotating logs..."
        # 10개 한도 초과 파일(monitor.log.11 이상) 삭제
        rm -f "$LOG_FILE.11"
        # 9번 파일부터 1번 파일까지 숫자를 하나씩 올리며 밀어내기 (monitor.log.9 -> monitor.log.10)
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
# 최종 결과를 PDF 명세서 표준 포맷에 맞게 규격화하여 파일 끝에 추가(>> append)합니다.
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
LOG_LINE="[$TIMESTAMP] [$STATUS] PID:$PID CPU:${CPU_USAGE}% MEM:${MEM_USAGE}% DISK_USED:${DISK_USED}%"

if [ -n "$WARNING_MSG" ]; then
    LOG_LINE="$LOG_LINE Details: $WARNING_MSG"
    # 경보(WARNING) 발생 시 외부 관제 시스템 연동을 위한 이벤트 JSON 생성
    ALERT_JSON="$AGENT_LOG_DIR/alert_events.json"
    echo "{\"timestamp\":\"$TIMESTAMP\",\"status\":\"WARNING\",\"pid\":$PID,\"cpu\":\"$CPU_USAGE\",\"mem\":\"$MEM_USAGE\",\"disk\":$DISK_USED,\"details\":\"$WARNING_MSG\"}" >> "$ALERT_JSON"
fi

echo "$LOG_LINE" >> "$LOG_FILE"
echo "[INFO] Log appended: $LOG_FILE"
echo "====== SYSTEM MONITOR END ======"

# 정상 종료 (exit 0: 성공)
exit 0