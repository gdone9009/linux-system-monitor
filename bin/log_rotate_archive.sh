#!/bin/bash
# ==============================================================================
# 스크립트 명: log_rotate_archive.sh (보너스 과제 2 - 시간 기반 로그 보존 정책)
# 작성 목적   : 7일 이상 경과한 로그 파일을 압축(.gz)하여 아카이브 디렉토리로 이동하고,
#               30일이 경과한 아카이브 파일을 자동으로 안전하게 삭제 관리합니다.
# 안전 예외 처리: 디렉토리 미존재, 권한 부족, 대상 파일 0개 시 경고 후 안전 종료.
# ==============================================================================

# 1. 경로 및 설정값 정의
source ~/.bash_profile 2>/dev/null
LOG_DIR="${AGENT_LOG_DIR:-/var/log/agent-app}"
ARCHIVE_DIR="/var/log/monitor/agent-app/archive"

echo "📦 [LOG ARCHIVE] 시간 기반 로그 아카이브 및 삭제 정책 프로세스를 시작합니다..."

# 2. 아카이브 디렉토리 생성 보장
if ! mkdir -p "$ARCHIVE_DIR" 2>/dev/null; then
    echo "⚠️ [WARNING] 아카이브 디렉토리를 생성할 권한이 없습니다 ($ARCHIVE_DIR)."
    echo "sudo 권한으로 실행하거나 소유권을 확인하세요."
    exit 0
fi

# 3. 7일 경과 로그 파일 압축 및 아카이브 이동
# find 유틸리티의 -mtime +7 옵션으로 7일 초과 파일 검색
SEVEN_DAYS_FILES=$(find "$LOG_DIR" -maxdepth 1 -type f \( -name "*.log.*" -o -name "monitor.log.[0-9]*" \) -mtime +7 2>/dev/null)

if [ -z "$SEVEN_DAYS_FILES" ]; then
    echo "ℹ️ [INFO] 7일 이상 경과된 압축 대상 로그 파일이 없습니다."
else
    echo "🔄 7일 경과 로그 파일 압축 및 아카이브 이동 중..."
    echo "$SEVEN_DAYS_FILES" | while read -r file; do
        if [ -f "$file" ]; then
            filename=$(basename "$file")
            # gzip 압축 수행 후 아카이브 디렉토리로 이동
            gzip -f "$file"
            mv "${file}.gz" "$ARCHIVE_DIR/${filename}.gz" 2>/dev/null
            echo "  - 압축 완료 및 이동: ${filename}.gz -> $ARCHIVE_DIR/"
        fi
    done
fi

# 4. 30일 경과 아카이브 (.gz) 파일 자동 삭제
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
