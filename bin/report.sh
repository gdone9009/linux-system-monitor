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
# 파싱 대상 형식: [2026-08-02 20:01:14] [INFO] PID:10312 CPU:0.0% MEM:0.0% DISK_USED:3%
awk '
BEGIN {
    count = 0;
    cpu_sum = 0; cpu_max = -1; cpu_min = 9999;
    mem_sum = 0; mem_max = -1; mem_min = 9999;
    cpu_max_time = ""; cpu_min_time = "";
    mem_max_time = ""; mem_min_time = "";
}
{
    # POSIX 호환 필드 및 정규식 추출
    if ($0 ~ /CPU:[0-9.]/ && $0 ~ /MEM:[0-9.]/) {
        # 타임스탬프 추출
        ts_start = index($0, "[");
        ts_end = index($0, "]");
        if (ts_start > 0 && ts_end > ts_start) {
            timestamp = substr($0, ts_start + 1, ts_end - ts_start - 1);
        } else {
            timestamp = "N/A";
        }

        # CPU 값 추출
        cpu_val = 0;
        for (i = 1; i <= NF; i++) {
            if ($i ~ /^CPU:/) {
                sub(/^CPU:/, "", $i);
                sub(/%$/, "", $i);
                cpu_val = $i + 0;
            }
            if ($i ~ /^MEM:/) {
                sub(/^MEM:/, "", $i);
                sub(/%$/, "", $i);
                mem_val = $i + 0;
            }
        }

        count++;
        cpu_sum += cpu_val;
        mem_sum += mem_val;

        # CPU 최대/최소값 및 시간 기록
        if (cpu_val > cpu_max) { cpu_max = cpu_val; cpu_max_time = timestamp; }
        if (cpu_val < cpu_min) { cpu_min = cpu_val; cpu_min_time = timestamp; }

        # Memory 최대/최소값 및 시간 기록
        if (mem_val > mem_max) { mem_max = mem_val; mem_max_time = timestamp; }
        if (mem_val < mem_min) { mem_min = mem_val; mem_min_time = timestamp; }
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
