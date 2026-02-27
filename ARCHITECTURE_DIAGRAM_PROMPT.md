# Architecture Diagram Prompt for AI Image Generation

Use this prompt with an AI image generation agent (e.g., DALL·E, Midjourney, or diagram tools like Excalidraw AI) to create a professional AWS cloud architecture diagram. Replace the ASCII diagram in the README with the generated image.

---

## Prompt (copy and paste)

```
Create a professional AWS cloud architecture diagram titled "Multi-Container Notes Application - AWS Architecture"

CRITICAL: The App Server EC2 runs exactly FIVE containers. All five must be clearly visible inside the EC2 box:
1. notes-proxy (Nginx)  2. notes-frontend (Next.js)  3. notes-backend (NestJS)  4. notes-database (PostgreSQL)  5. node-exporter (Prometheus Node Exporter :9100)
The database container (notes-database) is a Docker container like the others — show it INSIDE the Docker Compose stack box, NOT in the ECR section. ECR section only shows image sources.
The node-exporter container MUST be shown visibly INSIDE the EC2 box (below the Docker Compose stack). It runs in host network mode, exposes OS metrics on port 9100, and is scraped by Prometheus from the Monitoring Server. DO NOT OMIT IT.

LAYOUT (16:9 Landscape, White Background):

TOP-LEFT EXTERNAL COLUMN (Gray Box "Developer Tools"):
├── GitHub Logo → "Source Control"
├── Terraform Logo → "Infrastructure as Code"
├── GitHub Actions Logo → "CI/CD Pipeline"
└── Arrow labeled "Git Push" pointing right → "Triggers Workflow"

TOP FLOW (User Entry):
[👤 User] → "HTTP (80)" → [🌐 Internet] → [Security Group: 80, 443, 22]
                                        ↓
                              [EC2 Instance - Ubuntu 22.04]
                                        ↓
                              [Nginx Reverse Proxy :80]
                                        ↓
                    ┌───────────────────┴───────────────────┐
                    ↓                                       ↓
          [Frontend Network]                    [Frontend Network]
                    ↓                                       ↓
          [Next.js Container]                    [NestJS Container]
          notes-frontend :3000                   notes-backend :3001
          React + Next.js 13                               ↓
                                                  [Backend Network]
                                                  Isolated, Internal
                                                          ↓
                                                  [PostgreSQL 15]
                                                  notes-database :5432
                                                  ECR Public Image
                                                  public.ecr.aws/docker/library/postgres

CENTER (EC2 Instance - Light Blue Box with Docker Logo):
┌─────────────────────────────────────────────────────────────────────────┐
│  EC2 Instance (t3.small) - Ubuntu 22.04 LTS                             │
│  Bootstrap: user_data.sh (Docker, Docker Compose, AWS CLI, SSM Agent)   │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  Docker Compose Stack - /opt/notes-app (4 CONTAINERS)              │ │
│  │                                                                   │ │
│  │  ┌─────────────┐    ┌────────────────────┐    ┌────────────────┐ │ │
│  │  │ notes-proxy │───▶│ notes-frontend     │    │ notes-backend  │ │ │
│  │  │ Nginx :80   │    │ Next.js :3000      │    │ NestJS :3001   │ │ │
│  │  └─────────────┘    └────────────────────┘    └───────┬────────┘ │ │
│  │         │                      │                       │          │ │
│  │         │                      │         [Backend Network - Internal] │
│  │         │                      │                       │          │ │
│  │         │                      │              ┌────────▼────────┐  │ │
│  │         │                      │              │ notes-database  │  │ │
│  │         │                      │              │ PostgreSQL :5432│  │ │
│  │         │                      │              │ 🐳 Container    │  │ │
│  │         │                      │              └─────────────────┘  │ │
│  └─────────┴──────────────────────┴──────────────────────────────────┘ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  Node Exporter :9100 (host network mode)                          │ │
│  │  Exposes OS metrics: CPU, RAM, Disk, Network                      │ │
│  │  Scraped by Prometheus on Monitoring Server every 15s             │ │
│  └───────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘

RIGHT SIDE (CI/CD Pipeline - Green Tint):
┌─────────────────────────────────────────┐
│  GitHub Actions CI/CD                   │
│                                         │
│  1. Checkout Code                       │
│  2. npm install & build (backend,       │
│     frontend)                           │
│  3. npm test                            │
│  4. Configure AWS (OIDC - no keys)      │
│  5. Docker Build                        │
│  6. Push to ECR                         │
│  7. SSH to EC2                          │
│  8. docker compose pull & up            │
│  9. docker system prune                 │
│                                         │
│  Trigger: push to main                  │
└─────────────────────────────────────────┘

BOTTOM-LEFT (Terraform Infrastructure - Orange Tint):
┌─────────────────────────────────────────────────────────────────┐
│  Terraform Resources                                            │
│                                                                 │
│  [EC2 Icon]         [ECR Icon]        [IAM Icon]    [VPC Icon]  │
│  EC2 Instance       ECR Repos         IAM Roles     Security    │
│  Ubuntu 22.04       notes-backend     EC2 Role      Group       │
│  t3.small           notes-frontend    GitHub OIDC   Ports       │
│  Encrypted EBS      notes-proxy       Role          80, 443, 22 │
│                                                                 │
│  [TLS Icon]                                                     │
│  Key Pair (TLS Provider)                                        │
│  RSA 4096, auto-generated                                       │
└─────────────────────────────────────────────────────────────────┘

BOTTOM-CENTER (Container Registry - Purple Tint):
┌─────────────────────────────────────────────────────────────────┐
│  Amazon ECR - Image Sources (NOT runtime containers)            │
│                                                                 │
│  [ECR Icon] notes-backend:latest    ← NestJS API image          │
│  [ECR Icon] notes-frontend:latest   ← Next.js app image         │
│  [ECR Icon] notes-proxy:latest      ← Nginx image               │
│  [ECR Public] postgres:15-alpine    ← notes-database image      │
│  (All 4 containers pull from registry; database runs on EC2)    │
└─────────────────────────────────────────────────────────────────┘

BOTTOM-RIGHT (Secrets & Auth - Gray Box):
┌─────────────────────────────────────────┐
│  Secrets & Authentication               │
│                                         │
│  [GitHub Secrets Icon]                  │
│  DB_USERNAME, DB_PASSWORD, DB_NAME      │
│  AWS_ROLE_ARN, EC2_HOST                 │
│  SSH_PRIVATE_KEY (Terraform output)     │
│                                         │
│  [OIDC Icon]                            │
│  GitHub OIDC → AWS STS                  │
│  No long-lived AWS credentials          │
└─────────────────────────────────────────┘

NETWORK FLOW ANNOTATIONS:
- "Frontend Network" (bridge): proxy, frontend, backend
- "Backend Network" (internal): backend, database only — no external access
- Rate limiting: API 10 req/s, general 30 req/s (Nginx)
- Health checks: /nginx-health, /health (backend)

LEGEND (Bottom):
┌─────────────────────────────────────────────────────────┐
│ ━━━━━▶ HTTP Request Flow (Blue)                         │
│ ═════▶ Deployment Flow (Green)                          │
│ - - - ▶ Database Query (Orange)                         │
│ 🔐 Secrets in GitHub, never in code                     │
│ 🐳 4 Docker containers: proxy, frontend, backend, db    │
└─────────────────────────────────────────────────────────┘

STYLING:
- Official AWS orange (#FF9900) for AWS service icons
- Dark blue (#232F3E) for text and borders
- Section backgrounds: EC2=light blue (#E8F4F8), CI/CD=light green (#E8F5E9), Terraform=light orange (#FFF3E0)
- Clean sans-serif font
- Subtle shadows on boxes
- 2px rounded borders
- High contrast labels

IMPLEMENTATION-ACCURATE DETAILS:
- Nginx routes /api/* to backend :3001, / to frontend :3000
- Backend uses TypeORM with PostgreSQL
- Docker Compose ECR variant uses pre-built images (no build on EC2)
- Deploy script: scp .env + docker-compose.ecr.yml, then compose pull & up
- EC2 instance role: SSM + ECR read-only
- GitHub Actions role: ECR push, EC2 describe, SSM (optional)

OBSERVABILITY STACK (Second EC2 Instance — right side or below):
Show a SECOND EC2 instance labeled "Monitoring Server (t3.small) - Ubuntu 22.04" running 4 containers:

┌─────────────────────────────────────────────────────────────────┐
│  Monitoring Server EC2 (t3.small) - Ubuntu 22.04 LTS            │
│  Bootstrap: monitoring_user_data.sh                              │
│                                                                  │
│  Docker Compose Monitoring Stack (4 CONTAINERS)                  │
│                                                                  │
│  ┌──────────────────┐                                            │
│  │ Prometheus       │ ← Scrapes metrics every 15s                │
│  │ :9090            │   Evaluates 6 alert rules                  │
│  │ 15-day TSDB      │   Stores time-series data                  │
│  └────────┬─────────┘                                            │
│           │ fires alerts                                          │
│  ┌────────▼─────────┐                                            │
│  │ Alertmanager     │ → Groups, deduplicates alerts              │
│  │ :9093            │ → Routes to Slack #alerts                   │
│  └──────────────────┘   Critical: 1h, Warning: 4h repeat        │
│                                                                  │
│  ┌──────────────────┐                                            │
│  │ Grafana          │ ← Pre-configured dashboard                 │
│  │ :3000            │   Auto-provisioned datasource              │
│  └──────────────────┘                                            │
│                                                                  │
│  ┌──────────────────┐                                            │
│  │ Node Exporter    │ ← Self-monitoring (OS metrics)             │
│  │ :9100            │                                            │
│  └──────────────────┘                                            │
└─────────────────────────────────────────────────────────────────┘

ARROWS BETWEEN SERVERS:
- Monitoring Server → App Server: "Scrape /metrics :3001" (Blue arrow)
- Monitoring Server → App Server: "Scrape :9100 Node Exporter" (Blue arrow)
- Alertmanager → Slack Logo: "Notifications" (Red/Orange arrow)
- DevOps Engineer → Prometheus/Grafana/Alertmanager: "Operator IP only" (Green arrow)

MONITORING SECURITY GROUP (add to Terraform Resources or as separate box):
- :9090 (Prometheus UI) — operator IP only
- :3000 (Grafana UI) — operator IP only
- :9093 (Alertmanager UI) — operator IP only
- :9100 (Node Exporter) — self (monitoring SG)
- :22 (SSH) — operator IP only

APP SERVER SG additions:
- :3001 (metrics) — from monitoring SG only
- :9100 (Node Exporter) — from monitoring SG only

ALERT RULES (small annotation box):
🔴 BackendDown, LowMemory, DiskSpaceLow (critical)
🟡 HighErrorRate, HighP95Latency, HighCPU (warning)
```

---

## Usage

1. Copy the prompt text (everything between the triple backticks) into your AI image generator.
2. For diagram-specific tools (Excalidraw, Draw.io AI, Mermaid), you may need to simplify or adapt sections.
3. Save the output as `docs/architecture-diagram.png` or `assets/architecture.png`.
4. Update the README to reference the image:

   ```markdown
   ## Architecture Diagram

   ![Multi-Container Notes Application Architecture](docs/architecture-diagram.png)
   ```
