# 📋 웹 서버(Nginx/Apache) 모니터링 전환 체크리스트 및 구현 가이드

> **문서 목적**: 기존 관제 대상(Python `agent-app`)을 상용 웹 서버(Nginx 등)로 전환할 때 `monitor.sh`에서 변경해야 하는 핵심 4대 포인트(프로세스명, 리스닝 포트, 로그 경로/포맷, 리소스 임계치)의 명시적 전환 체크리스트 및 설정 템플릿을 제공합니다.

---

## 📌 1. 핵심 전환 매핑 체크리스트 (4대 점검 포인트)

| 점검 영역 | 기존 설정 (`agent-app`) | 웹 서버 전환 설정 (`Nginx`) | 웹 서버 전환 설정 (`Apache/httpd`) | 전환 조치 및 설정 근거 |
| :--- | :--- | :--- | :--- | :--- |
| **① 프로세스 식별<br>(Process Name)** | `APP_NAME="agent-app"`<br>(또는 `agent_app.py`) | `APP_NAME="nginx"`<br>(타깃: `nginx: master process`) | `APP_NAME="apache2"`<br>(또는 `httpd`) | 웹 서버는 Master-Worker 다중 프로세스 구조이므로, 자식 워커가 아닌 **Master 프로세스 PID**를 정확히 식별해야 함. (`pgrep -f "nginx: master process"`) |
| **② 서비스 포트<br>(Listening Port)** | `AGENT_PORT=15034` | `AGENT_PORT=80` (HTTP)<br>`AGENT_PORT=443` (HTTPS) | `AGENT_PORT=80` (HTTP)<br>`AGENT_PORT=443` (HTTPS) | 웹 표준 서비스 포트인 80(HTTP) 및 443(HTTPS)으로 변경하고, UFW 방화벽 규칙(`sudo ufw allow 80/tcp`, `sudo ufw allow 443/tcp`)을 선제 개방. |
| **③ 로그 저장소 & 소유권<br>(Log Directory & RBAC)** | `/var/log/agent-app/`<br>(소유: `agent-admin:agent-core`) | `/var/log/nginx/`<br>(소유: `www-data:adm`) | `/var/log/apache2/`<br>(소유: `root:adm`) | 웹 서버 자체의 `access.log`, `error.log`와 관제 스크립트 로그를 분리하되, 웹 데몬 실행 계정(`www-data`)과 읽기/쓰기 권한을 정합시킴. |
| **④ 리소스 임계치<br>(Resource Thresholds)** | `CPU > 20.0%`<br>`MEM > 10.0%`<br>`DISK > 80%` | `CPU > 75.0%`<br>`MEM > 60.0%`<br>`DISK > 85%` | `CPU > 80.0%`<br>`MEM > 70.0%`<br>`DISK > 85%` | 동시 다발적 웹 HTTP 요청(I/O & Worker 처리)을 고려하여 프로덕션 웹 트래픽에 적합한 실무 임계치로 상향 튜닝. |

---

## 🛠️ 2. 웹 서버 전환용 설정 템플릿 (`conf/web_server_transition.conf`)

관제 스크립트 코드 수정 없이 설정 파일 로드만으로 웹 서버 전환을 즉각 적용할 수 있는 표준 환경설정 템플릿입니다.

```bash
# ==============================================================================
# 🌐 Nginx 웹 서버 전용 관제 환경 설정 (conf/nginx_monitor.conf)
# ==============================================================================

# 1. 프로세스 및 바이너리 설정 (Master 프로세스 감시)
export APP_NAME="nginx"
export APP_PROCESS_PATTERN="nginx: master process"

# 2. 네트워크 서비스 포트 (HTTP/HTTPS)
export AGENT_PORT="80"
export AGENT_SSL_PORT="443"

# 3. 디렉토리 및 로그 경로
export AGENT_HOME="/etc/nginx"
export AGENT_LOG_DIR="/var/log/nginx"
export LOG_FILE="$AGENT_LOG_DIR/system_monitor.log"

# 4. 웹 서버 특화 임계치 (High-Traffic Web Server Profile)
export CPU_THRESHOLD="75.0"      # CPU 75% 초과 시 경고
export MEM_THRESHOLD="60.0"      # 메모리 60% 초과 시 경고
export DISK_THRESHOLD="85"       # 디스크 85% 초과 시 경고

# 5. 웹 서비스 전용 확장 메트릭 (선택 옵션)
export CHECK_ACTIVE_CONNECTIONS="yes"
export MAX_CONNECTIONS_LIMIT="10000"
```

---

## 🔍 3. 웹 서버 전환 시 단계별 실행 절차 (Step-by-Step Transition Pipeline)

```text
[Step 1: 방화벽 개방] ──> sudo ufw allow 80/tcp && sudo ufw allow 443/tcp
         │
[Step 2: 설정 파일 전환] ──> conf/nginx_monitor.conf 환경 변수 로드
         │
[Step 3: 서비스 헬스체크] ──> pgrep -f "nginx: master" && ss -tuln | grep :80
         │
[Step 4: Cron 작업 갱신] ──> crontab에 Nginx 관제 프로파일 적용 등록
```

1. **Step 1: 네트워크 방화벽(UFW) 포트 사전 개방**
   ```bash
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   sudo ufw status verbose
   ```
2. **Step 2: Master 프로세스 생존 및 포트 리스닝 검증**
   ```bash
   # Master PID 확인
   pgrep -f "nginx: master process"
   # 80/443 포트 LISTEN 상태 확인
   sudo ss -tulnp | grep -E ":80|:443"
   ```
3. **Step 3: Nginx 전환 관제 스크립트 실행 테스트**
   ```bash
   APP_NAME="nginx" AGENT_PORT=80 bash bin/monitor.sh
   ```
4. **Step 4: 전환 검증 리포트 확인 (`bin/report.sh`)**
   ```bash
   bash bin/report.sh /var/log/nginx/system_monitor.log
   ```

---

## 🚨 4. 웹 서버 전환 시 주요 장애 시나리오 및 대응 (Troubleshooting)

### Q. Nginx 프로세스는 떠 있는데 80번 포트가 안 열리는 경우
1. **원인 1**: Nginx 설정 파일 문법 오류 (`nginx -t`로 검증 필요)
2. **원인 2**: 다른 웹 데몬(Apache 등)이 이미 80 포트를 선점 (`sudo ss -tulnp | grep :80`으로 PID 확인 후 조치)
3. **원인 3**: SELinux / AppArmor 또는 바인딩 권한 부족 (비루트 사용자가 1024 이하 Well-known 포트 바인딩 시도)

### Q. 대규모 트래픽 유입으로 CPU 스파이크가 발생할 때
* 일시적 웹 트래픽 급증 시 즉각 프로세스가 중단되지 않도록 `monitor.sh`는 `[WARNING]` 로그를 남기되 모니터링을 지속하며, Nginx `worker_processes` 및 `worker_connections`를 증설 조치합니다.
