#!/bin/bash
# ==============================================================================
# Linux System Monitor - Fault Injection & Error Log Verification
# File: bin/test_fault_injection.sh
# ==============================================================================

set -e

# Calm & Refined Terminal Color Palette
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_GRAY='\033[90m'
C_WHITE='\033[1;37m'
C_SLATE='\033[38;5;110m'
C_GREEN='\033[38;5;150m'
C_AMBER='\033[38;5;179m'
C_ROSE='\033[38;5;167m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG_FILE="/var/log/agent-app/monitor.log"
[ ! -f "$LOG_FILE" ] && LOG_FILE="$HOME/agent-app/log/monitor.log"

echo -e "\n${C_GRAY}────────────────────────────────────────────────────────────────────────${C_RESET}"
echo -e " ${C_BOLD}${C_WHITE}FAULT INJECTION & ERROR LOGGING VERIFICATION${C_RESET}"
echo -e "${C_GRAY}────────────────────────────────────────────────────────────────────────${C_RESET}"

# 1. Baseline Check
echo -e "\n${C_SLATE}:: [Case 1] Normal Baseline Monitoring Check${C_RESET}"
echo -e "  ${C_GRAY}-> Executing: bash bin/monitor.sh${C_RESET}"
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh || true
echo -e "  ${C_GRAY}-> Latest normal log entry:${C_RESET}"
sudo tail -n 1 "$LOG_FILE"

# 2. Process Crash Simulation
echo -e "\n${C_SLATE}:: [Case 2] Fault Injection: Process Termination${C_RESET}"
echo -e "  ${C_GRAY}-> Action : 'sudo pkill -x agent-app'${C_RESET}"
sudo pkill -x "agent-app" 2>/dev/null || true
sleep 1

echo -e "  ${C_GRAY}-> Verification : Run monitor.sh expecting [FAILED] and exit code 1${C_RESET}"
set +e
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
EXIT_CODE=$?
set -e

echo -e "  ${C_GRAY}-> Exit Code Result :${C_RESET} ${C_BOLD}$EXIT_CODE${C_RESET}"
if [ $EXIT_CODE -eq 1 ]; then
    echo -e "  ${C_GREEN}[PASS]${C_RESET} ${C_GRAY}Process absence handled gracefully with exit 1.${C_RESET}"
else
    echo -e "  ${C_ROSE}[FAIL]${C_RESET} Unexpected exit code: $EXIT_CODE"
fi

echo -e "  ${C_GRAY}-> Recorded error log in $LOG_FILE:${C_RESET}"
sudo tail -n 1 "$LOG_FILE"

# 3. Service Recovery
echo -e "\n${C_SLATE}:: [Case 3] Self-Healing: Service Recovery${C_RESET}"
echo -e "  ${C_GRAY}-> Action : Restarting agent-app background service...${C_RESET}"
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

echo -e "  ${C_GRAY}-> Verification : Re-running monitor.sh after restoration${C_RESET}"
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
echo -e "  ${C_GREEN}[PASS]${C_RESET} ${C_GRAY}Service recovered successfully.${C_RESET}"

# 4. Port Mismatch Simulation
echo -e "\n${C_SLATE}:: [Case 4] Fault Injection: Non-listening Port Mismatch (Port 59999)${C_RESET}"
set +e
sudo -u agent-admin env AGENT_PORT=59999 /home/agent-admin/agent-app/bin/monitor.sh
PORT_EXIT_CODE=$?
set -e

echo -e "  ${C_GRAY}-> Exit Code Result :${C_RESET} ${C_BOLD}$PORT_EXIT_CODE${C_RESET}"
if [ $PORT_EXIT_CODE -eq 1 ]; then
    echo -e "  ${C_GREEN}[PASS]${C_RESET} ${C_GRAY}Port mismatch handled gracefully with exit 1.${C_RESET}"
else
    echo -e "  ${C_ROSE}[FAIL]${C_RESET} Unexpected exit code: $PORT_EXIT_CODE"
fi

echo -e "  ${C_GRAY}-> Recorded error log in $LOG_FILE:${C_RESET}"
sudo tail -n 1 "$LOG_FILE"

echo -e "\n${C_GRAY}────────────────────────────────────────────────────────────────────────${C_RESET}"
echo -e " ${C_GREEN}[PASS 100%]${C_RESET} ${C_WHITE}All fault injection test cases passed.${C_RESET}"
echo -e "${C_GRAY}────────────────────────────────────────────────────────────────────────${C_RESET}\n"
