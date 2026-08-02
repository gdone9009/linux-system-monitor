#!/bin/bash
# ==============================================================================
# 📖 [초보자를 위한 교재용 해설] 관제 로그 통계 리포터 스크립트 (report.sh)
# ------------------------------------------------------------------------------
# 본 스크립트는 monitor.sh가 매분 쌓아둔 monitor.log 파일의 전체 텍스트를 읽어서,
# CPU 사용률, 메모리 사용률의 평균값(Average), 최대값(Maximum), 최소값(Minimum) 및
# 발생 시각과 총 수집 샘플(Data Points) 개수를 자동으로 분석/계산해 주는 리포트 도구입니다.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. 로그 파일 경로 설정 및 예외 처리
# ------------------------------------------------------------------------------
# [개념 설명] '$1'은 스크립트를 실행할 때 사용자가 전달하는 첫 번째 인자(Argument)입니다.
# 예: ./report.sh /path/to/custom.log
# 인자를 전달하지 않았다면 기본값으로 '$AGENT_LOG_DIR/monitor.log'를 사용합니다.
source ~/.bash_profile 2>/dev/null
AGENT_LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
LOG_FILE="${1:-$AGENT_LOG_DIR/monitor.log}"

# [예외 처리] 분석할 로그 파일이 존재하지 않는 경우 에러 메시지를 출력하고 종료합니다.
if [ ! -f "$LOG_FILE" ]; then
    echo "⚠️ [ERROR] 로그 파일을 찾을 수 없습니다: $LOG_FILE"
    echo "관제 스크립트(monitor.sh)가 최소 1회 이상 실행되어 로그가 수집되어야 합니다."
    exit 1
fi

echo "====== STATISTICS REPORT ======"

# ------------------------------------------------------------------------------
# 2. Awk 유틸리티를 활용한 고성능 텍스트 분석 및 통계 계산 Engine
# ------------------------------------------------------------------------------
# [개념 설명] Awk는 대용량 텍스트 및 로그 파일을 파싱하는 데 특화된 텍스트 처리 언어입니다.
# - BEGIN { ... }: 파일 파싱이 시작되기 직전 변수(합계, 최댓값, 최솟값)를 초기화하는 블록
# - { ... }: 로그 파일의 매 라인(Line)을 읽을 때마다 반복 실행되는 블록
# - END { ... }: 파일 전체를 다 읽은 후 최종 통계 결과를 계산하고 출력하는 블록
awk '
BEGIN {
    count = 0;
    cpu_sum = 0; cpu_max = -1; cpu_min = 9999;
    mem_sum = 0; mem_max = -1; mem_min = 9999;
    cpu_max_time = ""; cpu_min_time = "";
    mem_max_time = ""; mem_min_time = "";
}
{
    # 2.1 라인 검증: CPU 및 MEM 수치가 포함된 로그 라인만 골라냅니다.
    if ($0 ~ /CPU:[0-9.]/ && $0 ~ /MEM:[0-9.]/) {

        # 2.2 타임스탬프 추출: 대괄호([ ]) 사이의 시각 정보(예: 2026-08-02 20:01:14)를 자릅니다.
        ts_start = index($0, "[");
        ts_end = index($0, "]");
        if (ts_start > 0 && ts_end > ts_start) {
            timestamp = substr($0, ts_start + 1, ts_end - ts_start - 1);
        } else {
            timestamp = "N/A";
        }

        # 2.3 라인 내부의 단어(필드)를 순회하며 CPU: 수치와 MEM: 수치를 숫자로 변환합니다.
        cpu_val = 0;
        mem_val = 0;
        for (i = 1; i <= NF; i++) {
            if ($i ~ /^CPU:/) {
                sub(/^CPU:/, "", $i);
                sub(/%$/, "", $i);
                cpu_val = $i + 0; # 문자열을 숫자로 변환
            }
            if ($i ~ /^MEM:/) {
                sub(/^MEM:/, "", $i);
                sub(/%$/, "", $i);
                mem_val = $i + 0; # 문자열을 숫자로 변환
            }
        }

        # 2.4 누적 카운트 및 합계 추가
        count++;
        cpu_sum += cpu_val;
        mem_sum += mem_val;

        # 2.5 CPU 최댓값 / 최솟값 업데이트 알고리즘
        if (cpu_val > cpu_max) { cpu_max = cpu_val; cpu_max_time = timestamp; }
        if (cpu_val < cpu_min) { cpu_min = cpu_val; cpu_min_time = timestamp; }

        # 2.6 Memory 최댓값 / 최솟값 업데이트 알고리즘
        if (mem_val > mem_max) { mem_max = mem_val; mem_max_time = timestamp; }
        if (mem_val < mem_min) { mem_min = mem_val; mem_min_time = timestamp; }
    }
}
END {
    # 2.7 분석 데이터가 없을 경우 처리
    if (count == 0) {
        print "⚠️ 분석할 수 있는 로그 데이터가 없습니다.";
        exit 0;
    }

    # 2.8 평균 수치 계산
    cpu_avg = cpu_sum / count;
    mem_avg = mem_sum / count;

    # 2.9 미션 PDF 규격 양식에 맞춘 콘솔 출력 (printf: 소수점 1자리 지정 %.1f)
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
