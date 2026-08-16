#!/bin/bash
# ==============================================================================
# 📖 [초보자를 위한 교재용 해설] 시간 기반 로그 보존 및 아카이브 스크립트 (log_rotate_archive.sh)
# ------------------------------------------------------------------------------
# 본 스크립트는 오래된 로그 파일이 서버 디렉토리에 계속 쌓이는 문제를 해결하기 위해,
# 1) 생성된 지 7일 이상 경과된 로그를 gzip으로 압축(.gz)하여 별도 아카이브 디렉토리로 이동하고,
# 2) 아카이브 보존 기한인 30일이 경과된 데이터는 용량 확보를 위해 자동 정원 삭제합니다.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. 경로 및 프로파일 로드
# ------------------------------------------------------------------------------
source ~/.bash_profile 2>/dev/null
LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
[ ! -d "$LOG_DIR" ] && LOG_DIR="$HOME/agent-app/log"
ARCHIVE_DIR="/var/log/monitor/agent-app/archive"

echo "📦 [LOG ARCHIVE] 시간 기반 로그 아카이브 및 삭제 정책 프로세스를 시작합니다..."

# ------------------------------------------------------------------------------
# 2. 아카이브 디렉토리 생성 및 권한 Fallback 처리
# ------------------------------------------------------------------------------
# [개념 설명] '/var/log/monitor' 경로는 일반 계정 권한으로 생성이 불가능할 수 있습니다.
# 따라서 권한 오류 발생 시 유저 로그 디렉토리 하위($LOG_DIR/archive)로 자동 전환하여
# 권한 부족으로 스크립트가 멈추는 현상을 안전하게 방지합니다.
if ! mkdir -p "$ARCHIVE_DIR" 2>/dev/null; then
    ARCHIVE_DIR="$LOG_DIR/archive"
    mkdir -p "$ARCHIVE_DIR" 2>/dev/null
    echo "ℹ️ [INFO] 유저 아카이브 경로로 자동 전환되었습니다 ($ARCHIVE_DIR)."
fi

# ------------------------------------------------------------------------------
# 3. 7일 이상 경과된 로그 파일 탐색 및 압축/이동
# ------------------------------------------------------------------------------
# [개념 설명] 'find [경로] -mtime +7' 은 파일의 최종 수정 시간(mtime)이 7일(7*24시간)을
# 초과한 대상만 검색합니다. '-maxdepth 1' 은 하위 폴더는 재귀 탐색하지 않고 현재 폴더만 검색합니다.
SEVEN_DAYS_FILES=$(find "$LOG_DIR" -maxdepth 1 -type f \( -name "*.log.*" -o -name "monitor.log.[0-9]*" \) -mtime +7 2>/dev/null)

if [ -z "$SEVEN_DAYS_FILES" ]; then
    echo "ℹ️ [INFO] 7일 이상 경과된 압축 대상 로그 파일이 없습니다."
else
    echo "🔄 7일 경과 로그 파일 압축 및 아카이브 이동 중..."
    echo "$SEVEN_DAYS_FILES" | while read -r file; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            # [개념 설명] 'gzip -f' 명령어로 텍스트 파일을 약 80~90% 압축된 .gz 바이너리로 변환합니다.
            gzip -f "$file"
            mv "${file}.gz" "$ARCHIVE_DIR/${filename}.gz" 2>/dev/null
            echo "  - 압축 완료 및 이동: ${filename}.gz -> $ARCHIVE_DIR/"
        fi
    done
fi

# ------------------------------------------------------------------------------
# 4. 30일 이상 경과된 아카이브(.gz) 영구 삭제 (보존 기한 만료)
# ------------------------------------------------------------------------------
# [개념 설명] 'find [아카이브경로] -name "*.gz" -mtime +30' 명령어로 30일이 넘은 고전 압축 파일을 찾아서
# 디스크 공간 확보를 위해 'rm -f'로 깔끔하게 삭제합니다.
THIRTY_DAYS_FILES=$(find "$ARCHIVE_DIR" -maxdepth 1 -type f -name "*.gz" -mtime +30 2>/dev/null)

if [ -z "$THIRTY_DAYS_FILES" ]; then
    echo "ℹ️ [INFO] 30일 이상 경과된 삭제 대상 아카이브 파일이 없습니다."
else
    echo "🧹 30일 경과 아카이브 파일 자동 삭제 중..."
    echo "$THIRTY_DAYS_FILES" | while read -r archive_file; do
        if [ -f "$archive_file" ]; then
            rm -f "$archive_file"
            echo "  - 영구 삭제 완료: $(basename "$archive_file")"
        fi
    done
fi

echo "✅ [LOG ARCHIVE] 아카이브 및 보존 정책 처리가 안전하게 완료되었습니다."
exit 0
