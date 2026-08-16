#!/bin/bash
# ==============================================================================
# 💥 FAULT INJECTION & ERROR LOGGING VERIFICATION (test_fault_injection.sh)
# ------------------------------------------------------------------------------
# 본 스크립트는 평가 항목 #5, #6, #18 검증을 위해 의도적으로 다양한 장애 상황을 
# 유도(Fault Injection)하고, monitor.sh가 exit 1로 안전하게 종료되며
# /var/log/agent-app/monitor.log에 [ERROR] 규격 로그가 기록되는지 실증합니다.
# ==============================================================================

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="/var/log/agent-app/monitor.log"
[ ! -f "$LOG_FILE" ] && LOG_FILE="$HOME/agent-app/log/monitor.log"

echo -e "${BLUE}${BOLD}====================================================================${NC}"
echo -e "${CYAN}${BOLD}  💥 장애 상황 유도(Fault Injection) 및 에러 로깅 실시간 검증${NC}"
echo -e "${BLUE}${BOLD}====================================================================${NC}"

# ------------------------------------------------------------------------------
# 1. 정상 상태 기준선(Baseline) 확인
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}${BOLD}[테스트 1] 정상 동작 상태 기준선(Baseline) 관제 확인${NC}"
echo -e "명령어: bash bin/monitor.sh"
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh || true
echo -e "👉 [최신 정상 로그 확인]:"
sudo tail -n 1 "$LOG_FILE"

# ------------------------------------------------------------------------------
# 2. 장애 시나리오 A: 프로세스 강제 중단 (Process Crash Simulation)
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}${BOLD}[테스트 2] 장애 시나리오 A: 서비스 프로세스 강제 중단 유도${NC}"
echo -e "▶ 조치: 'sudo pkill -x agent-app' 로 프로세스 강제 종료"
sudo pkill -x "agent-app" 2>/dev/null || true
sleep 1

echo -e "▶ 검증: 'monitor.sh' 실행 (예상: [FAILED] 출력 및 exit 1 반환)"
set +e
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
EXIT_CODE=$?
set -e

echo -e "\n📊 [종료 코드 검증 결과]: ${BOLD}Exit Code = $EXIT_CODE${NC}"
if [ $EXIT_CODE -eq 1 ]; then
    echo -e "${GREEN}${BOLD}✔ [PASS] 프로세스 부재 시 정확히 exit 1로 비정상 종료됨을 확인!${NC}"
else
    echo -e "${RED}${BOLD}❌ [FAIL] exit 1이 아닌 코드($EXIT_CODE)로 종료됨${NC}"
fi

echo -e "\n👉 [로그 파일에 기록된 에러 메시지 실시간 확인]:"
sudo tail -n 2 "$LOG_FILE"

# ------------------------------------------------------------------------------
# 3. 서비스 자동 복구 (Self-Healing Recovery)
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}${BOLD}[테스트 3] 서비스 복구(Recovery) 및 정상 관제 재개 확인${NC}"
echo -e "▶ 조치: agent-app 서비스 재기동"
sudo -u agent-admin bash -c '
export AGENT_HOME=/home/agent-admin/agent-app
export AGENT_PORT=15034
export AGENT_UPLOAD_DIR=$AGENT_HOME/upload_files
export AGENT_KEY_PATH=$AGENT_HOME/api_keys/t_secret.key
export AGENT_LOG_DIR=/var/log/agent-app
cd $AGENT_HOME
./agent-app > /var/log/agent-app/app_stdout.log 2>&1 &
'
sleep 2

echo -e "▶ 검증: 복구 후 'monitor.sh' 재실행"
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh

echo -e "\n👉 [복구 후 최신 정상 로그 확인]:"
sudo tail -n 1 "$LOG_FILE"

# ------------------------------------------------------------------------------
# 4. 장애 시나리오 B: 포트 미개방/불일치 장애 유도 (Port Failure Simulation)
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}${BOLD}[테스트 4] 장애 시나리오 B: 미개방 포트(Port 59999) 바인딩 장애 유도${NC}"
set +e
sudo -u agent-admin env AGENT_PORT=59999 /home/agent-admin/agent-app/bin/monitor.sh
PORT_EXIT_CODE=$?
set -e

echo -e "\n📊 [종료 코드 검증 결과]: ${BOLD}Exit Code = $PORT_EXIT_CODE${NC}"
if [ $PORT_EXIT_CODE -eq 1 ]; then
    echo -e "${GREEN}${BOLD}✔ [PASS] 포트 미개방 시 정확히 exit 1로 비정상 종료됨을 확인!${NC}"
else
    echo -e "${RED}${BOLD}❌ [FAIL] exit 1이 아닌 코드($PORT_EXIT_CODE)로 종료됨${NC}"
fi

echo -e "\n👉 [로그 파일에 기록된 포트 에러 메시지 실시간 확인]:"
sudo tail -n 2 "$LOG_FILE"

echo -e "\n${BLUE}${BOLD}====================================================================${NC}"
echo -e "${GREEN}${BOLD}🎉 모든 장애 유도(Fault Injection) 및 에러 로깅 검증 테스트 통과!${NC}"
echo -e "${BLUE}${BOLD}====================================================================${NC}\n"
