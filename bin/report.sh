#!/bin/bash
# ==============================================================================
# 스크립트 명: report.sh (보너스 과제 1 - 관제 로그 통계 요약 리포트)
# 작성 목적   : monitor.log 파일을 수집 및 분석하여 CPU, Memory, Disk의 
#               평균(Average), 최대(Maximum), 최소(Minimum) 수치 및 
#               총 샘플(Data Points) 수를 계산하여 보고서를 콘솔에 출력합니다.
# 제약 사항   : 순수 Bash 및 Awk 유틸리티만 사용하여 외부 라이브러리 없이 구현.
# ==============================================================================

# 1. 로그 파일 경로 설정 (기본값: /var/log/agent-app/monitor.log)
source ~/.bash_profile 2>/dev/null
AGENT_LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
LOG_FILE="${1:-$AGENT_LOG_DIR/monitor.log}"

# 2. 로그 파일 존재 여부 확인 (예외 처리)
if [ ! -f "$LOG_FILE" ]; then
    echo "⚠️ [ERROR] 로그 파일을 찾을 수 없습니다: $LOG_FILE"
    echo "관제 스크립트(monitor.sh)가 최소 1회 이상 실행되어 로그가 수집되어야 합니다."
    exit 1
fi

echo "====== STATISTICS REPORT ======"

# 3. Awk 스크립트를 활용하여 monitor.log의 통계 데이터를 한 번의 패스로 정밀 계산
# 파싱 대상 형식: [YYYY-MM-DD HH:MM:SS] ... PID:1234 CPU:10.2% MEM:3.2% DISK_USED:23%
awk '
BEGIN {
    count = 0;
    cpu_sum = 0; cpu_max = -1; cpu_min = 9999;
    mem_sum = 0; mem_max = -1; mem_min = 9999;
    cpu_max_time = ""; cpu_min_time = "";
    mem_max_time = ""; mem_min_time = "";
}
{
    # 3.1 라인 내에서 타임스탬프, CPU, MEM 수치 추출
    # 타임스탬프 예시: [2026-02-25 14:00:05]
    if (match($0, /\[([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2})\]/, time_arr) &&
        match($0, /CPU:([0-9.]+)%/, cpu_arr) &&
        match($0, /MEM:([0-9.]+)%/, mem_arr)) {

        timestamp = time_arr[1];
        cpu = cpu_arr[1] + 0;
        mem = mem_arr[1] + 0;

        count++;
        cpu_sum += cpu;
        mem_sum += mem;

        # CPU 최대/최소값 및 시간 기록
        if (cpu > cpu_max) { cpu_max = cpu; cpu_max_time = timestamp; }
        if (cpu < cpu_min) { cpu_min = cpu; cpu_min_time = timestamp; }

        # Memory 최대/최소값 및 시간 기록
        if (mem > mem_max) { mem_max = mem; mem_max_time = timestamp; }
        if (mem < mem_min) { mem_min = mem; mem_min_time = timestamp; }
    }
}
END {
    if (count == 0) {
        print "⚠️ 분석할 수 있는 로그 데이터가 없습니다.";
        exit 0;
    }

    # 3.2 평균값 계산 (소수점 첫째 자리까지 출력)
    cpu_avg = cpu_sum / count;
    mem_avg = mem_sum / count;

    # 3.3 요구사항 PDF 양식에 부합하는 통계 결과 출력
    print "[CPU]";
    printf "Average : %.1f%%\n", cpu_avg;
    printf "Maximum : %.1f%% at %s\n", cpu_max, cpu_max_time;
    printf "Minimum : %.1f%% at %s\n", cpu_min, cpu_min_time;

    print "[Memory]";
    printf "Average : %.1f%%\n", mem_avg;
    printf "Maximum : %.1f%% at %s\n", mem_max, mem_max_time;
    printf "Minimum : %.1f%% at %s\n", mem_min, mem_min_time;

    print "[Samples]";
    printf "Data Points: %d samples\n", count;
}
' "$LOG_FILE"

echo "====== END OF REPORT ======"
