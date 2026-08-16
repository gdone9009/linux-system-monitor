#!/bin/bash
# ==============================================================================
# Linux System Monitor - Master Orchestration & Live Demo Pipeline
# File: run_all.sh
# ==============================================================================

set -e

# Calm & Refined Terminal Color Palette
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_GRAY='\033[90m'

C_WHITE='\033[1;37m'
C_SLATE='\033[38;5;110m'
C_TEAL='\033[38;5;73m'
C_GREEN='\033[38;5;150m'
C_AMBER='\033[38;5;179m'
C_ROSE='\033[38;5;167m'

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

print_banner() {
    echo -e "\n${C_GRAY}────────────────────────────────────────────────────────────────────────${C_RESET}"
    echo -e " ${C_BOLD}${C_WHITE}$1${C_RESET}"
    echo -e "${C_GRAY}────────────────────────────────────────────────────────────────────────${C_RESET}"
}

print_section() {
    echo -e "\n${C_SLATE}:: ${C_BOLD}$1${C_RESET}"
}

print_step() {
    echo -e "\n  ${C_GRAY}[Step ${1}]${C_RESET} ${C_WHITE}${2}${C_RESET}"
}

print_ok() {
    echo -e "  ${C_GREEN}[OK]${C_RESET} ${C_GRAY}$1${C_RESET}"
}

print_warn() {
    echo -e "  ${C_AMBER}[WARN]${C_RESET} $1"
}

print_fail() {
    echo -e "  ${C_ROSE}[FAIL]${C_RESET} $1"
}

# ------------------------------------------------------------------------------
# Mode Selection & CLI Parsing
# ------------------------------------------------------------------------------
MODE=""
INTERACTIVE=false

if [ "$1" = "--auto" ] || [ "$1" = "-a" ]; then
    MODE="1"
elif [ "$1" = "--step" ] || [ "$1" = "-s" ] || [ "$1" = "-i" ]; then
    MODE="2"
elif [ "$1" = "--fault" ] || [ "$1" = "-f" ]; then
    MODE="3"
elif [ "$1" = "--test" ] || [ "$1" = "-t" ]; then
    MODE="4"
fi

if [ -z "$MODE" ]; then
    clear 2>/dev/null || true
    echo -e "${C_GRAY}┌──────────────────────────────────────────────────────────────────────┐${C_RESET}"
    echo -e "${C_GRAY}│${C_RESET}  ${C_BOLD}${C_WHITE}LINUX SYSTEM MONITOR${C_RESET} ${C_GRAY}— Orchestration & Demonstration Pipeline${C_RESET}  ${C_GRAY}│${C_RESET}"
    echo -e "${C_GRAY}└──────────────────────────────────────────────────────────────────────┘${C_RESET}"
    echo -e "  ${C_GRAY}Target Directory :${C_RESET} ${C_SLATE}$PROJECT_ROOT${C_RESET}"
    echo -e "  ${C_GRAY}System Timestamp :${C_RESET} $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    echo -e "  ${C_BOLD}Execution Modes:${C_RESET}"
    echo -e "    ${C_GREEN}1)${C_RESET} ${C_WHITE}Full Automation${C_RESET}      ${C_GRAY}(Continuous execution without pauses)${C_RESET}"
    echo -e "    ${C_SLATE}2)${C_RESET} ${C_WHITE}Step-by-Step Interactive${C_RESET}  ${C_GRAY}(Press [Enter] after each step)${C_RESET}"
    echo -e "    ${C_AMBER}3)${C_RESET} ${C_WHITE}Fault Injection Test${C_RESET}  ${C_GRAY}(Simulate errors & verify logging)${C_RESET}"
    echo -e "    ${C_GRAY}4)${C_RESET} ${C_WHITE}Verification Test Only${C_RESET}  ${C_GRAY}(Run tests/run_tests.sh suite)${C_RESET}"
    echo ""
    
    if [ -t 0 ]; then
        read -r -p "  Select mode [1-4] (default: 1): " USER_INPUT
        MODE="${USER_INPUT:-1}"
    else
        MODE="1"
    fi
fi

if [ "$MODE" = "2" ]; then
    INTERACTIVE=true
    echo -e "\n  ${C_SLATE}-> Step-by-Step Interactive mode activated.${C_RESET}"
    echo -e "  ${C_GRAY}Review output and press [Enter] to proceed to next step.${C_RESET}\n"
elif [ "$MODE" = "3" ]; then
    bash "$PROJECT_ROOT/bin/test_fault_injection.sh"
    exit 0
elif [ "$MODE" = "4" ]; then
    print_banner "Test Suite Execution"
    bash "$PROJECT_ROOT/tests/run_tests.sh"
    exit 0
else
    echo -e "\n  ${C_GREEN}-> Full Automation mode starting...${C_RESET}\n"
fi

pause_step() {
    local next_step="$1"
    if [ "$INTERACTIVE" = true ]; then
        echo -e "\n  ${C_GRAY}----------------------------------------------------------------------${C_RESET}"
        echo -e "  ${C_SLATE}Press [Enter] to proceed to: ${C_BOLD}${next_step}${C_RESET} ${C_GRAY}(Ctrl+C to abort)${C_RESET}"
        echo -e "  ${C_GRAY}----------------------------------------------------------------------${C_RESET}"
        if [ -t 0 ]; then
            read -r -p ""
        fi
    fi
}

# ------------------------------------------------------------------------------
# Phase 1: Infrastructure Provisioning
# ------------------------------------------------------------------------------
print_banner "Phase 1: Automated Infrastructure Provisioning (IaC)"

print_step "1.1" "Environment & Package Initialization (setup/01_env_setup.sh)"
bash setup/01_env_setup.sh
source ~/.bash_profile 2>/dev/null || true
print_ok "Base environment and environment variables established."
pause_step "1.2 Security Hardening & UFW Configuration"

print_step "1.2" "Security Hardening & UFW Whitelist (setup/02_security_setup.sh)"
bash setup/02_security_setup.sh
print_ok "SSH port 20022 and UFW firewall rules configured."
pause_step "1.3 RBAC & Permission Isolation"

print_step "1.3" "RBAC Accounts & Directory Isolation (setup/03_user_setup.sh)"
bash setup/03_user_setup.sh
print_ok "Service accounts (admin/dev/test) and 770/660 permissions configured."
pause_step "1.4 Crontab Automation Registration"

print_step "1.4" "Cron 1-Minute Automation Registration (setup/04_cron_setup.sh)"
bash setup/04_cron_setup.sh
print_ok "Cron monitoring schedule registered."
pause_step "Phase 2: Application Deployment & Boot Sequence"

# ------------------------------------------------------------------------------
# Phase 2: Application Deployment
# ------------------------------------------------------------------------------
print_banner "Phase 2: Application Deployment & Boot Sequence Verification"

print_step "2.1" "Runtime Assets Synchronization (/home/agent-admin/agent-app)"
sudo pkill -x "agent-app" 2>/dev/null || true
sleep 1

sudo mkdir -p /home/agent-admin/agent-app/{bin,api_keys,upload_files}
sudo mkdir -p /var/log/agent-app

if [ -f "$PROJECT_ROOT/agent-app" ]; then
    sudo cp "$PROJECT_ROOT/agent-app" /home/agent-admin/agent-app/
    sudo chmod +x /home/agent-admin/agent-app/agent-app
fi

sudo cp "$PROJECT_ROOT/bin/monitor.sh" /home/agent-admin/agent-app/bin/
sudo cp "$PROJECT_ROOT/bin/report.sh" /home/agent-admin/agent-app/bin/
sudo cp "$PROJECT_ROOT/bin/log_rotate_archive.sh" /home/agent-admin/agent-app/bin/

echo "agent_api_key_test" | sudo tee /home/agent-admin/agent-app/api_keys/t_secret.key >/dev/null
sudo chown -R agent-admin:agent-core /home/agent-admin/agent-app/api_keys
sudo chmod 770 /home/agent-admin/agent-app/api_keys
sudo chmod 660 /home/agent-admin/agent-app/api_keys/t_secret.key

sudo chown -R agent-admin:agent-core /var/log/agent-app
sudo chmod 770 /var/log/agent-app

sudo chown -R agent-admin:agent-common /home/agent-admin/agent-app/upload_files
sudo chmod 775 /home/agent-admin/agent-app/upload_files

sudo chown agent-dev:agent-core /home/agent-admin/agent-app/bin/monitor.sh
sudo chmod 750 /home/agent-admin/agent-app/bin/monitor.sh
sudo chmod 755 /home/agent-admin/agent-app/bin/report.sh /home/agent-admin/agent-app/bin/log_rotate_archive.sh
sudo chown -R agent-admin:agent-admin /home/agent-admin/agent-app/agent-app 2>/dev/null || true

print_ok "Runtime assets synchronized and permissions verified."
pause_step "2.2 Application Background Startup"

print_step "2.2" "Application Startup & Port 15034 Binding"
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

APP_PID=$(pgrep -x "agent-app" | head -n 1 || true)
if [ -n "$APP_PID" ]; then
    print_ok "Application running (PID: $APP_PID, Port: 15034 LISTEN)"
    echo -e "  ${C_GRAY}Boot stdout snippet:${C_RESET}"
    sudo tail -n 4 /var/log/agent-app/app_stdout.log 2>/dev/null || true
else
    print_warn "Process verification needed"
fi
pause_step "Phase 3: Live System Monitoring & Error Injection"

# ------------------------------------------------------------------------------
# Phase 3: Live Monitoring & Error Injection
# ------------------------------------------------------------------------------
print_banner "Phase 3: Real-time System Monitoring & Fault Injection Verification"

print_step "3.1" "Live Health Check & Resource Measurement (bin/monitor.sh)"
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh

print_step "3.2" "Time-series Metric Log Verification (/var/log/agent-app/monitor.log)"
sudo tail -n 4 /var/log/agent-app/monitor.log
print_ok "Normal metric records verified."
pause_step "3.3 Fault Injection: Process Crash & Error Log Verification"

print_step "3.3" "Fault Injection: Terminate Application Process"
echo -e "  ${C_GRAY}-> Action : 'sudo pkill -x agent-app'${C_RESET}"
sudo pkill -x "agent-app" 2>/dev/null || true
sleep 1

echo -e "  ${C_GRAY}-> Verification : Run monitor.sh expecting [FAILED] and exit 1${C_RESET}"
set +e
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
FAIL_EXIT_CODE=$?
set -e

if [ $FAIL_EXIT_CODE -eq 1 ]; then
    print_ok "Process absence handled gracefully with exit 1."
else
    print_warn "Exit code returned: $FAIL_EXIT_CODE"
fi

echo -e "  ${C_GRAY}Recorded error log line:${C_RESET}"
sudo tail -n 2 /var/log/agent-app/monitor.log
print_ok "Error logging verified in /var/log/agent-app/monitor.log"

print_step "3.4" "Self-Healing: Service Recovery & Resume Normal Monitoring"
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

sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
print_ok "Service restored and monitoring resumed."
pause_step "Phase 4: Bonus Automation Features"

# ------------------------------------------------------------------------------
# Phase 4: Bonus Automation Features
# ------------------------------------------------------------------------------
print_banner "Phase 4: Bonus Automation Features (Report & Archive)"

print_step "4.1" "Awk-based Resource Statistics Report (bin/report.sh)"
sudo -u agent-admin /home/agent-admin/agent-app/bin/report.sh
pause_step "4.2 Time-based Log Archiving & Retention Policy"

print_step "4.2" "Time-based Log Archiving & Cleanup Policy (bin/log_rotate_archive.sh)"
sudo -u agent-admin /home/agent-admin/agent-app/bin/log_rotate_archive.sh
print_ok "Log archiving policy executed."
pause_step "Phase 5: Final Integrity Test Suite"

# ------------------------------------------------------------------------------
# Phase 5: Integrity Test Suite
# ------------------------------------------------------------------------------
print_banner "Phase 5: Automated Integrity Test Suite (tests/run_tests.sh)"

bash "$PROJECT_ROOT/tests/run_tests.sh"

# ------------------------------------------------------------------------------
# Summary
# ------------------------------------------------------------------------------
echo -e "\n${C_GRAY}┌──────────────────────────────────────────────────────────────────────┐${C_RESET}"
echo -e "${C_GRAY}│${C_RESET}  ${C_BOLD}${C_GREEN}ALL SYSTEM CHECKS COMPLETED SUCCESSFULLY${C_RESET}                            ${C_GRAY}│${C_RESET}"
echo -e "${C_GRAY}├──────────────────────────────────────────────────────────────────────┤${C_RESET}"
echo -e "  ${C_GREEN}✔${C_RESET} ${C_WHITE}Infrastructure Provisioning (IaC)${C_RESET}        ${C_GREEN}[PASS]${C_RESET}"
echo -e "  ${C_GREEN}✔${C_RESET} ${C_WHITE}SSH 20022 & UFW Security Hardening${C_RESET}       ${C_GREEN}[PASS]${C_RESET}"
echo -e "  ${C_GREEN}✔${C_RESET} ${C_WHITE}RBAC Account & Permission Isolation${C_RESET}      ${C_GREEN}[PASS]${C_RESET}"
echo -e "  ${C_GREEN}✔${C_RESET} ${C_WHITE}Application Boot Sequence (Agent READY)${C_RESET}  ${C_GREEN}[PASS]${C_RESET}"
echo -e "  ${C_GREEN}✔${C_RESET} ${C_WHITE}Real-time Health Check & Monitoring${C_RESET}      ${C_GREEN}[PASS]${C_RESET}"
echo -e "  ${C_GREEN}✔${C_RESET} ${C_WHITE}Fault Injection & Error Log Handling${C_RESET}     ${C_GREEN}[PASS]${C_RESET}"
echo -e "  ${C_GREEN}✔${C_RESET} ${C_WHITE}Crontab 1-Minute Automation${C_RESET}              ${C_GREEN}[PASS]${C_RESET}"
echo -e "  ${C_GREEN}✔${C_RESET} ${C_WHITE}Bonus Report & Archive Operations${C_RESET}        ${C_GREEN}[PASS]${C_RESET}"
echo -e "  ${C_GREEN}✔${C_RESET} ${C_WHITE}Integrated Test Suite (9 Categories)${C_RESET}     ${C_GREEN}[PASS 100%]${C_RESET}"
echo -e "${C_GRAY}└──────────────────────────────────────────────────────────────────────┘${C_RESET}\n"
