# Advanced Observability Architecture Diagram Prompt

Use this prompt with an AI image generation tool (DALL·E, Midjourney, Excalidraw AI, or draw.io) to create a professional AWS cloud architecture diagram showing the complete observability stack with OpenTelemetry, Jaeger, Prometheus, Grafana, and distributed tracing.

---

## Prompt

```
Create a professional AWS cloud architecture diagram titled "Multi-Container Notes Application — Advanced Observability & Distributed Tracing"

LAYOUT: 16:9 Landscape, White Background, Clean AWS Architecture Style

═══════════════════════════════════════════════════════════════════════════════
TOP SECTION: USER & TRAFFIC FLOW
═══════════════════════════════════════════════════════════════════════════════

[👤 User/Load Generator] 
    ↓ HTTP/HTTPS
[🌐 Internet Gateway]
    ↓
[Application Load Balancer]
├─ Production Listener :80 (Blue/Green)
├─ Test Listener :8080 (Blue/Green validation)
└─ Target Groups: Blue & Green

═══════════════════════════════════════════════════════════════════════════════
CENTER-LEFT: ECS FARGATE CLUSTER (Light Blue Box)
═══════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────────┐
│  AWS ECS Fargate Cluster - notes-app-ecs-cluster                           │
│  Network Mode: awsvpc | Launch Type: FARGATE                               │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │  ECS Task (Fargate) - notes-app-service                              │ │
│  │  CPU: 512 | Memory: 1024 MB                                          │ │
│  │                                                                       │ │
│  │  ┌─────────────────┐  ┌──────────────────┐  ┌────────────────────┐  │ │
│  │  │  notes-proxy    │  │  notes-frontend  │  │  notes-backend     │  │ │
│  │  │  Nginx :80      │─▶│  Next.js :3000   │  │  NestJS :3001      │  │ │
│  │  │                 │  │                  │  │                    │  │ │
│  │  │  Routes:        │  │  SSR UI          │  │  ✅ OpenTelemetry  │  │ │
│  │  │  /     → FE     │  │                  │  │  ✅ Prometheus     │  │ │
│  │  │  /api  → BE     │  │                  │  │  ✅ Pino Logger    │  │ │
│  │  │  /metrics → BE  │  │                  │  │                    │  │ │
│  │  └─────────────────┘  └──────────────────┘  └──────────┬─────────┘  │ │
│  │                                                         │            │ │
│  │                                              ┌──────────▼─────────┐  │ │
│  │                                              │  notes-database    │  │ │
│  │                                              │  PostgreSQL :5432  │  │ │
│  │                                              │  RDS/Container     │  │ │
│  │                                              └────────────────────┘  │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
│                                                                             │
│  📊 Metrics Exposed: /metrics (Prometheus format)                          │
│  🔍 Traces Exported: OTLP HTTP → Jaeger :4318                              │
│  📝 Logs: JSON with trace_id + span_id → CloudWatch Logs                   │
└─────────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════
CENTER-RIGHT: MONITORING SERVER EC2 (Orange Box)
═══════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────────┐
│  Monitoring Server EC2 (t3.small) - Ubuntu 22.04                           │
│  Role: Observations Server | Private IP: 10.x.x.x                          │
│                                                                             │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │  Docker Compose Stack - /opt/monitoring (4 CONTAINERS)               │ │
│  │                                                                       │ │
│  │  ┌──────────────────────────────────────────────────────────────┐    │ │
│  │  │  Prometheus :9090                                            │    │ │
│  │  │  • Scrapes /metrics from ALB every 15s                       │    │ │
│  │  │  • Evaluates alert rules (error rate, latency, CPU, memory)  │    │ │
│  │  │  • Stores 15 days of time-series data                        │    │ │
│  │  │  • Sends firing alerts → Alertmanager                        │    │ │
│  │  └──────────────────────────────────────────────────────────────┘    │ │
│  │                              ↓                                        │ │
│  │  ┌──────────────────────────────────────────────────────────────┐    │ │
│  │  │  Alertmanager :9093                                          │    │ │
│  │  │  • Receives alerts from Prometheus                           │    │ │
│  │  │  • Groups, deduplicates, routes to Slack                     │    │ │
│  │  │  • Critical: repeat every 1h | Warning: repeat every 4h      │    │ │
│  │  └──────────────────────────────────────────────────────────────┘    │ │
│  │                              ↓                                        │ │
│  │  ┌──────────────────────────────────────────────────────────────┐    │ │
│  │  │  Grafana :3000                                               │    │ │
│  │  │  • Pre-provisioned Prometheus datasource                     │    │ │
│  │  │  • Notes App Dashboard (RED metrics, latency, runtime)       │    │ │
│  │  │  • Links to Jaeger traces via trace_id                       │    │ │
│  │  │  • Admin: admin / (from terraform.tfvars)                    │    │ │
│  │  └──────────────────────────────────────────────────────────────┘    │ │
│  │                                                                       │ │
│  │  ┌──────────────────────────────────────────────────────────────┐    │ │
│  │  │  Jaeger All-in-One :16686                                    │    │ │
│  │  │  • Collector: OTLP HTTP :4318, OTLP gRPC :4317               │    │ │
│  │  │  • Query UI: http://<monitoring-ip>:16686                    │    │ │
│  │  │  • Storage: In-memory (sufficient for lab workloads)         │    │ │
│  │  │  • Receives traces from notes-backend via OTLP               │    │ │
│  │  └──────────────────────────────────────────────────────────────┘    │ │
│  │                                                                       │ │
│  │  ┌──────────────────────────────────────────────────────────────┐    │ │
│  │  │  Node Exporter :9100 (host network mode)                     │    │ │
│  │  │  • Exposes OS metrics: CPU, RAM, Disk, Network               │    │ │
│  │  │  • Scraped by Prometheus for monitoring server health        │    │ │
│  │  └──────────────────────────────────────────────────────────────┘    │ │
│  └───────────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════
BOTTOM-LEFT: OBSERVABILITY DATA FLOWS (Green Tint)
═══════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────────┐
│  📊 METRICS FLOW (Prometheus Pull Model)                                   │
│                                                                             │
│  [notes-backend :3001/metrics] ◀─── Prometheus scrapes every 15s           │
│      ↓                                                                      │
│  Exposes:                                                                   │
│  • http_requests_total{method, route, status_code}                         │
│  • http_request_duration_seconds{method, route, status_code}               │
│  • notes_nodejs_heap_size_used_bytes                                       │
│  • notes_nodejs_eventloop_lag_seconds                                      │
│  • notes_process_cpu_seconds_total                                         │
│                                                                             │
│  [Prometheus] ──evaluates──▶ [Alert Rules]                                 │
│      ↓                            ↓                                         │
│  Stores TSDB              Fires if:                                         │
│  (15 days)                • Error rate >5% for 10m                          │
│                           • P95 latency >300ms for 10m                      │
│                           • CPU >80% for 5m                                 │
│                           • Memory <200MB for 2m                            │
│                                   ↓                                         │
│                          [Alertmanager] ──▶ Slack #alerts                  │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  🔍 TRACES FLOW (OpenTelemetry Push Model)                                 │
│                                                                             │
│  [notes-backend] ──OTLP HTTP──▶ [Jaeger Collector :4318]                   │
│      ↓                                    ↓                                 │
│  Auto-instrumented:                  Stores traces                          │
│  • HTTP requests (method, route)     (in-memory)                            │
│  • Database queries (SQL, duration)       ↓                                 │
│  • External HTTP calls               [Jaeger Query UI :16686]               │
│                                            ↓                                 │
│  Every span includes:                 Visualize:                            │
│  • trace_id, span_id                  • Service graph                       │
│  • operation name                     • Trace timeline                      │
│  • start time, duration               • Span details                        │
│  • tags (http.status_code, db.statement)                                    │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  📝 LOGS FLOW (Structured JSON with Trace Context)                         │
│                                                                             │
│  [notes-backend] ──Pino Logger──▶ [CloudWatch Logs]                        │
│      ↓                                    ↓                                 │
│  Every log line includes:            Query by trace_id:                     │
│  {                                   fields @timestamp, msg, trace_id       │
│    "level": 30,                      | filter trace_id = "abc123..."       │
│    "time": 1704067200000,            | sort @timestamp desc                 │
│    "msg": "GET /api/notes 200",                                             │
│    "trace_id": "abc123...",          Correlate:                             │
│    "span_id": "def456...",           Alert → Jaeger → CloudWatch Logs       │
│    "method": "GET",                                                         │
│    "route": "/api/notes",                                                   │
│    "status_code": 200                                                       │
│  }                                                                          │
└─────────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════
BOTTOM-CENTER: ALERT → TRACE → LOG CORRELATION (Purple Tint)
═══════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────────┐
│  🚨 INCIDENT RESPONSE WORKFLOW                                              │
│                                                                             │
│  1️⃣ ALERT FIRES                                                            │
│     [Prometheus] detects: Error rate >5% for 10m                            │
│          ↓                                                                  │
│     [Alertmanager] ──▶ Slack: "🔴 HighErrorRate firing"                    │
│                                                                             │
│  2️⃣ INVESTIGATE IN JAEGER                                                  │
│     Open Jaeger UI → Filter by:                                            │
│     • Service: notes-backend                                                │
│     • Time: last 10 minutes                                                 │
│     • Tag: http.status_code=500                                             │
│          ↓                                                                  │
│     Identify failing trace → Copy trace_id: "a1b2c3d4..."                  │
│                                                                             │
│  3️⃣ EXAMINE TRACE SPANS                                                    │
│     POST /api/notes (500) — 1.2s                                            │
│       ├─ DB Query: INSERT INTO notes — 1.15s ❌ ERROR                       │
│       └─ Log: Database connection timeout                                   │
│                                                                             │
│  4️⃣ CORRELATE WITH LOGS                                                    │
│     CloudWatch Logs Insights:                                               │
│     fields @timestamp, msg, error                                           │
│     | filter trace_id = "a1b2c3d4..."                                       │
│          ↓                                                                  │
│     Result: "Connection timeout after 5000ms"                               │
│                                                                             │
│  5️⃣ ROOT CAUSE IDENTIFIED                                                  │
│     Database connection pool exhausted                                      │
│     Fix: Increase max_connections in PostgreSQL                             │
│     Deploy: Blue/Green deployment via CodeDeploy                            │
│     Verify: Alert resolves automatically                                    │
└─────────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════
BOTTOM-RIGHT: CI/CD & INFRASTRUCTURE (Gray Tint)
═══════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────────┐
│  GitHub Actions CI/CD Pipeline                                             │
│                                                                             │
│  1. Checkout code                                                           │
│  2. npm install & build (backend, frontend)                                 │
│  3. npm test                                                                │
│  4. Configure AWS (OIDC - no static keys)                                   │
│  5. Docker build (backend, frontend, proxy)                                 │
│  6. Push to ECR                                                             │
│  7. Register new ECS task definition                                        │
│  8. Trigger CodeDeploy Blue/Green deployment                                │
│  9. Traffic shift: 10% per minute                                           │
│  10. Automatic rollback on CloudWatch alarm                                 │
│                                                                             │
│  Trigger: push to main                                                      │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│  Terraform Infrastructure (IaC)                                             │
│                                                                             │
│  [ECS Icon]         [ALB Icon]        [ECR Icon]        [EC2 Icon]         │
│  ECS Fargate        Application       ECR Repos         Monitoring         │
│  Cluster            Load Balancer     notes-backend     Server             │
│  Blue/Green         Blue/Green        notes-frontend    t3.small           │
│  CodeDeploy         Listeners         notes-proxy       Prometheus         │
│                                                          Grafana            │
│  [IAM Icon]         [CloudWatch]      [VPC Icon]        Jaeger             │
│  IAM Roles          Alarms            Security          Alertmanager       │
│  ECS Task           Rollback          Groups                               │
│  GitHub OIDC        Triggers          Metrics ports                        │
└─────────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════
NETWORK SECURITY & DATA FLOW ANNOTATIONS
═══════════════════════════════════════════════════════════════════════════════

Security Groups:
├─ ALB SG: Allow 80, 443 from 0.0.0.0/0
├─ ECS Tasks SG: Allow 80 from ALB SG | Allow 4318 from Monitoring SG
├─ Monitoring SG: Allow 9090, 3000, 16686, 9093 from Operator IP only
└─ Monitoring SG: Allow 9100 from self (Node Exporter)

Data Flows:
━━━━━▶ HTTP Request Flow (Blue)
═════▶ Metrics Scrape (Prometheus Pull - Green)
─ ─ ─▶ Traces Export (OTLP Push - Orange)
· · · ▶ Logs Stream (CloudWatch - Purple)
🔐 Secrets in GitHub, never in code
🔍 trace_id links metrics → traces → logs

═══════════════════════════════════════════════════════════════════════════════
LEGEND
═══════════════════════════════════════════════════════════════════════════════

┌─────────────────────────────────────────────────────────────────────────────┐
│ Observability Pillars:                                                      │
│ 📊 METRICS: Prometheus scrapes /metrics (RED: Rate, Errors, Duration)      │
│ 🔍 TRACES: OpenTelemetry → Jaeger (distributed request tracing)            │
│ 📝 LOGS: Pino → CloudWatch (structured JSON with trace_id)                 │
│                                                                             │
│ Alert Rules (Lab Requirements):                                            │
│ ✅ HighErrorRate: >5% for 10 minutes → Slack                               │
│ ✅ HighP95Latency: >300ms for 10 minutes → Slack                           │
│                                                                             │
│ Key Technologies:                                                           │
│ • OpenTelemetry SDK (auto-instrumentation)                                  │
│ • Prometheus (metrics + alerting)                                           │
│ • Jaeger (distributed tracing)                                              │
│ • Grafana (visualization)                                                   │
│ • Alertmanager (notification routing)                                       │
│ • Pino (structured logging with trace context)                              │
└─────────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════════
STYLING REQUIREMENTS
═══════════════════════════════════════════════════════════════════════════════

Colors:
- AWS Orange (#FF9900) for AWS service icons
- Dark Blue (#232F3E) for text and borders
- Light Blue (#E8F4F8) for ECS/Fargate sections
- Light Orange (#FFF3E0) for Monitoring Server section
- Light Green (#E8F5E9) for Metrics Flow section
- Light Purple (#F3E5F5) for Traces Flow section
- Light Gray (#F5F5F5) for CI/CD section

Typography:
- Clean sans-serif font (Inter, Roboto, or Open Sans)
- Bold for section headers
- Monospace for code/config snippets

Visual Elements:
- Subtle shadows on boxes (2px blur, 10% opacity)
- 2px rounded borders
- High contrast labels for accessibility
- Icons: Use official AWS service icons where applicable
- Arrows: Solid for HTTP, dashed for async/push, dotted for logs

Layout:
- 16:9 aspect ratio (1920x1080 or 1600x900)
- White background
- Clear visual hierarchy (top → center → bottom)
- Adequate whitespace between sections
- Align boxes on a grid for professional appearance
```

---

## Implementation Notes

This architecture diagram accurately represents:

1. **ECS Fargate Deployment**: 4 containers (proxy, frontend, backend, database) running on Fargate with Blue/Green deployment
2. **Dedicated Monitoring Server**: Separate EC2 instance running Prometheus, Grafana, Jaeger, and Alertmanager
3. **OpenTelemetry Instrumentation**: Backend exports traces to Jaeger via OTLP HTTP
4. **Prometheus Metrics**: Backend exposes /metrics endpoint scraped by Prometheus every 15s
5. **Structured Logging**: Pino logger injects trace_id and span_id into every log line
6. **Alert Rules**: HighErrorRate (>5% for 10m) and HighP95Latency (>300ms for 10m)
7. **Alertmanager**: Routes firing alerts to Slack with grouping and inhibition
8. **Correlation Workflow**: Alert → Jaeger trace → CloudWatch Logs query by trace_id

The diagram emphasizes the three pillars of observability (metrics, traces, logs) and shows how they correlate for incident response.
