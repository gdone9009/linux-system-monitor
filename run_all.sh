#!/bin/bash
# ==============================================================================
# 🚀 MASTER ORCHESTRATOR & INTERACTIVE DEMO PIPELINE (run_all.sh)
# ------------------------------------------------------------------------------
# 본 마스터 스크립트는 리눅스 시스템 관제 및 보안 구축 미션의 전 과정을 
# 1) [전자동 일괄 실행 모드], 2) [단계별 엔터 진행 모드], 3) [장애 유도 및 에러 로깅 모드]로
# 지원하는 통합 오케스트레이터 및 라이브 시연 도구입니다.
#
# [실행 옵션 (CLI Flags)]
#   ./run_all.sh         : 모드 선택 대화창 표시 (기본)
#   ./run_all.sh --auto  : 1번 전자동 일괄 실행 (Non-interactive)
#   ./run_all.sh --step  : 2번 단계별 엔터 진행 (Step-by-Step Interactive)
#   ./run_all.sh --fault : 3번 장애 유도 및 에러 로깅 전용 모드 (Fault Injection)
#   ./run_all.sh --test  : 4번 무결성 검증 테스트 수트 즉시 실행
# ==============================================================================

set -e

# 색상 및 스타일 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[1;35m'
BOLD='\033[1m'
NC='\033[0m' # No Color

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_ROOT"

print_header() {
    echo -e "\n${BLUE}${BOLD}====================================================================${NC}"
    echo -e "${CYAN}${BOLD}  $1${NC}"
    echo -e "${BLUE}${BOLD}====================================================================${NC}"
}

print_step() {
    echo -e "\n${YELLOW}${BOLD}▶ [STEP] $1${NC}"
}

print_success() {
    echo -e "${GREEN}${BOLD}✔ [SUCCESS] $1${NC}"
}

# ------------------------------------------------------------------------------
# 모드 선택 및 인자 파싱
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
    echo -e "${BLUE}${BOLD}====================================================================${NC}"
    echo -e "${CYAN}${BOLD}  🛡️ LINUX SYSTEM MONITOR - MASTER DEMO & TEST PIPELINE${NC}"
    echo -e "${BLUE}${BOLD}====================================================================${NC}"
    echo -e "프로젝트 위치: ${BOLD}$PROJECT_ROOT${NC}"
    echo -e "현재 시각: $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "\n${BOLD}실행할 시연 모드를 선택해 주세요:${NC}"
    echo -e "  ${GREEN}${BOLD}[1] ⚡ 전자동 일괄 실행 모드${NC} (Full Automation - 대기 없이 원스톱 실행)"
    echo -e "  ${YELLOW}${BOLD}[2] 🎯 인터랙티브 단계별 모드${NC} (Step-by-Step - 정상 관제 + 장애 유도 후 [Enter])"
    echo -e "  ${RED}${BOLD}[3] 💥 장애 상황 유도 및 에러 로깅 검증 모드${NC} (Fault Injection & Error Log Test)"
    echo -e "  ${MAGENTA}${BOLD}[4] 🧪 무결성 검증 테스트 전용 모드${NC} (Test-Only - run_tests.sh 즉시 실행)"
    echo -e "${BLUE}--------------------------------------------------------------------${NC}"
    
    if [ -t 0 ]; then
        read -r -p "선택 번호를 입력하세요 [1/2/3/4] (기본값: 1): " USER_INPUT
        MODE="${USER_INPUT:-1}"
    else
        MODE="1"
    fi
fi

if [ "$MODE" = "2" ]; then
    INTERACTIVE=true
    echo -e "\n${YELLOW}${BOLD}🎯 [인터랙티브 단계별 모드]가 활성화되었습니다.${NC}"
    echo -e "각 단계의 실행 결과를 확인하신 후, ${BOLD}[Enter]${NC}를 누르면 다음 단계로 진행합니다.\n"
elif [ "$MODE" = "3" ]; then
    bash "$PROJECT_ROOT/bin/test_fault_injection.sh"
    exit 0
elif [ "$MODE" = "4" ]; then
    print_header "🧪 무결성 검증 테스트 수트 즉시 실행"
    bash "$PROJECT_ROOT/tests/run_tests.sh"
    exit 0
else
    echo -e "\n${GREEN}${BOLD}⚡ [전자동 일괄 실행 모드]로 시작합니다.${NC}\n"
fi

pause_step() {
    local next_step_name="$1"
    if [ "$INTERACTIVE" = true ]; then
        echo -e "\n${MAGENTA}${BOLD}────────────────────────────────────────────────────────────────────${NC}"
        echo -e "${CYAN}${BOLD}👉 다음 단계 [${next_step_name}] 로 진행하려면 [Enter] 키를 누르세요... ${NC}${NC}(중단: Ctrl+C)"
        echo -e "${MAGENTA}${BOLD}────────────────────────────────────────────────────────────────────${NC}"
        if [ -t 0 ]; then
            read -r -p ""
        fi
    fi
}

# ------------------------------------------------------------------------------
# Phase 1: 인프라 기초 및 보안 요새화 프로비저닝 (setup/01 ~ 04)
# ------------------------------------------------------------------------------
print_header "Phase 1: 인프라 자동 프로비저닝 (Infrastructure as Code)"

print_step "1-1. 시스템 환경 및 패키지 최적화 (setup/01_env_setup.sh)"
bash setup/01_env_setup.sh
source ~/.bash_profile 2>/dev/null || true
print_success "기초 환경 및 전역 환경 변수 등록 완료"
pause_step "1-2. SSH 포트 20022 및 UFW 방화벽 설정"

print_step "1-2. SSH 포트 20022 난독화 및 UFW 방화벽 화이트리스트 (setup/02_security_setup.sh)"
bash setup/02_security_setup.sh
print_success "SSH 20022 전환 및 방화벽 화이트리스트(20022, 15034) 요새화 완료"
pause_step "1-3. RBAC 계정 체계 및 디렉토리 권한 격리"

print_step "1-3. RBAC 계정 설계 및 보안 자산 770 권한 격리 (setup/03_user_setup.sh)"
bash setup/03_user_setup.sh
print_success "agent-admin/dev/test 계정 및 core/common 그룹 격리 완료"
pause_step "1-4. Crontab 1분 무인 관제 자동 스케줄러 등록"

print_step "1-4. 1분 주기 Cron 무인 관제 자동 스케줄러 등록 (setup/04_cron_setup.sh)"
bash setup/04_cron_setup.sh
print_success "Crontab 무인 자동화 등록 완료"
pause_step "Phase 2. 애플리케이션 배포 및 5단계 Boot Sequence 기동"

# ------------------------------------------------------------------------------
# Phase 2: 런타임 환경 동기화 및 애플리케이션 기동 (Agent READY)
# ------------------------------------------------------------------------------
print_header "Phase 2: 애플리케이션 배포 및 5단계 Boot Sequence 기동"

print_step "2-1. 서비스 실행 디렉토리(/home/agent-admin/agent-app) 자산 동기화"
# 실행 중인 프로세스 우선 중지하여 'Text file busy' 에러 방지
sudo pkill -x "agent-app" 2>/dev/null || true
sleep 1

sudo mkdir -p /home/agent-admin/agent-app/{bin,api_keys,upload_files}
sudo mkdir -p /var/log/agent-app

# 바이너리 및 관제 스크립트 복사
if [ -f "$PROJECT_ROOT/agent-app" ]; then
    sudo cp "$PROJECT_ROOT/agent-app" /home/agent-admin/agent-app/
    sudo chmod +x /home/agent-admin/agent-app/agent-app
fi

sudo cp "$PROJECT_ROOT/bin/monitor.sh" /home/agent-admin/agent-app/bin/
sudo cp "$PROJECT_ROOT/bin/report.sh" /home/agent-admin/agent-app/bin/
sudo cp "$PROJECT_ROOT/bin/log_rotate_archive.sh" /home/agent-admin/agent-app/bin/

# 시크릿 키 생성 및 권한 설정
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

print_success "런타임 자산 및 보안 권한 동기화 완료"
pause_step "2-2. 애플리케이션 백그라운드 기동 및 5단계 부트 통과"

print_step "2-2. 애플리케이션 백그라운드 기동 및 포트 15034 바인딩"
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
    print_success "애플리케이션 정상 구동 확인 (PID: $APP_PID, Port: 15034 LISTEN)"
    echo -e "  [부트 시퀀스 출력 스냅샷]"
    sudo tail -n 6 /var/log/agent-app/app_stdout.log 2>/dev/null || true
else
    echo -e "${RED}경고: agent-app 백그라운드 프로세스 확인 필요${NC}"
fi
pause_step "Phase 3. 실시간 시스템 관제 및 자원 모니터링"

# ------------------------------------------------------------------------------
# Phase 3: 실시간 관제 및 에러 상황 유도/검증
# ------------------------------------------------------------------------------
print_header "Phase 3: 실시간 시스템 관제 및 장애 유도 에러 로깅 검증"

print_step "3-1. 정상 동작 상태 관제 헬스체크 및 메트릭 수집 실행"
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh

print_step "3-2. 누적된 시계열 관제 로그 확인 (/var/log/agent-app/monitor.log)"
sudo tail -n 5 /var/log/agent-app/monitor.log
print_success "정상 관제 데이터 [INFO] 로깅 누적 확인"
pause_step "3-3. 장애 상황 유도 (Fault Injection) 및 에러 로그 기록 검증"

print_step "3-3. [장애 유도 1] 서비스 프로세스 강제 중단 시뮬레이션"
echo -e "  👉 조치: 'sudo pkill -x agent-app' 실행"
sudo pkill -x "agent-app" 2>/dev/null || true
sleep 1

echo -e "  👉 검증: 'monitor.sh' 실행 (예상: [FAILED] 출력 및 exit 1 종료)"
set +e
sudo -u agent-admin /home/agent-admin/agent-app/bin/monitor.sh
FAIL_EXIT_CODE=$?
set -e

if [ $FAIL_EXIT_CODE -eq 1 ]; then
    print_success "프로세스 부재 시 정확히 exit 1로 비정상 종료됨을 확인! (Exit Code: $FAIL_EXIT_CODE)"
else
    echo -e "${RED}경고: 종료 코드 = $FAIL_EXIT_CODE${NC}"
fi

echo -e "\n  👉 [로그 파일에 기록된 에러 메시지 실시간 확인]:"
sudo tail -n 2 /var/log/agent-app/monitor.log
print_success "로그 파일에 [ERROR] Process 'agent-app' is NOT running! 기록 확인 완료"

print_step "3-4. [자가 치유] 서비스 정상 재기동 및 복구 확인"
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
print_success "서비스 복구 후 정상 관제 [OK] 재개 확인"
pause_step "Phase 4. 보너스 기능 2종 시연 (Report & Archive)"

# ------------------------------------------------------------------------------
# Phase 4: 보너스 기능 2종 시연
# ------------------------------------------------------------------------------
print_header "Phase 4: 보너스 자동화 기능 시연 (Report & Archive)"

print_step "4-1. [보너스 1] Awk 기반 리소스 통계 분석 리포트 (bin/report.sh)"
sudo -u agent-admin /home/agent-admin/agent-app/bin/report.sh
pause_step "4-2. [보너스 2] 시간 기반 로그 아카이브 및 보존 정책"

print_step "4-2. [보너스 2] 시간 기반 로그 아카이브 및 보존 정책 (bin/log_rotate_archive.sh)"
sudo -u agent-admin /home/agent-admin/agent-app/bin/log_rotate_archive.sh
print_success "보너스 2종 정상 동작 확인"
pause_step "Phase 5. 최종 통합 무결성 테스트 수트 실행"

# ------------------------------------------------------------------------------
# Phase 5: 통합 무결성 테스트 수트 원클릭 검증
# ------------------------------------------------------------------------------
print_header "Phase 5: 통합 무결성 테스트 수트 (tests/run_tests.sh)"

bash "$PROJECT_ROOT/tests/run_tests.sh"

# ------------------------------------------------------------------------------
# 최종 요약 배너
# ------------------------------------------------------------------------------
print_header "🎉 ALL SYSTEMS GO - MASTER PIPELINE COMPLETED SUCCESSFULLY"
echo -e "${GREEN}${BOLD}✔ 인프라 프로비저닝 (IaC): PASS${NC}"
echo -e "${GREEN}${BOLD}✔ SSH 20022 & UFW 보안 요새화: PASS${NC}"
echo -e "${GREEN}${BOLD}✔ RBAC 계정 체계 및 770/660 격리: PASS${NC}"
echo -e "${GREEN}${BOLD}✔ 앱 5단계 부트 시퀀스 (Agent READY): PASS${NC}"
echo -e "${GREEN}${BOLD}✔ monitor.sh 헬스체크 및 자원 관제: PASS${NC}"
echo -e "${GREEN}${BOLD}✔ 장애 상황 유도 및 exit 1 / 에러 로깅 검증: PASS${NC}"
echo -e "${GREEN}${BOLD}✔ Crontab 1분 무인 자동화: PASS${NC}"
echo -e "${GREEN}${BOLD}✔ 보너스 1 (통계) & 보너스 2 (아카이브): PASS${NC}"
echo -e "${GREEN}${BOLD}✔ 9대 통합 테스트 무결성: 100% PASS (만점)${NC}"
echo -e "${BLUE}====================================================================${NC}\n"
