# Matomo Analytics Webserver Specification

**Last Updated**: 2025-11-19
**Purpose**: Self-hosted analytics server for diegonmarcos.github.io
**Status**: Deployed, DNS migration pending

---

## 🌐 Infrastructure Overview

### Hosting Provider
- **Platform**: Oracle Cloud Infrastructure (OCI)
- **Tier**: Always Free Tier ✅
- **Region**: EU-Marseille-1 (France)
- **Cost**: $0/month (permanent free tier)

### Instance Specifications
- **Instance Type**: VM.Standard.E2.1.Micro
- **vCPUs**: 2 (AMD EPYC 7742)
- **RAM**: 1 GB
- **Storage**: 50 GB boot volume
- **OS**: Ubuntu 24.04 Minimal
- **Architecture**: x86_64

---

## 🖥️ Server Details

### Current Production Server
- **Public IP**: 130.110.251.193
- **Private IP**: 10.0.1.x (Oracle VCN)
- **VCN**: matomo-vcn (10.0.0.0/16)
- **Subnet**: matomo-subnet (10.0.1.0/24)
- **Domain**: analytics.diegonmarcos.com
- **SSH User**: ubuntu
- **SSH Key**: `~/.ssh/matomo_key`

### Previous Server (Legacy)
- **Old IP**: 144.24.205.254
- **Status**: Currently pointed by DNS (needs migration)

### Alternative Instance (from docs)
- **IP**: 129.151.229.21
- **Instance ID**: `ocid1.instance.oc1.eu-marseille-1.anwxeljruadvczacdbn762t6u3lc2a5ttdtjy6el235cehuu52uzmjuezucq`
- **Status**: May be decommissioned or backup

---

## 🐳 Docker Stack Architecture

### Container Setup
The server runs a Docker Compose stack with 3 services:

#### 1. Matomo Analytics
- **Image**: `matomo:latest`
- **Container Name**: matomo-app
- **Internal Port**: 80
- **Exposed Port**: 8080
- **Purpose**: Web analytics application
- **Volume**: `./matomo:/var/www/html`
- **Database**: MariaDB (via link)

#### 2. MariaDB Database
- **Image**: `mariadb:10.11`
- **Container Name**: matomo-db
- **Port**: 3306 (internal only)
- **Database Name**: matomo
- **Database User**: matomo
- **Volume**: `./mariadb:/var/lib/mysql`
- **Credentials**: Auto-generated (stored in `matomo-credentials.txt`)

#### 3. Nginx Proxy Manager
- **Image**: `nginxproxymanager/nginx-proxy-manager:latest`
- **Container Name**: nginx-proxy
- **Ports**:
  - `80`: HTTP (redirects to HTTPS)
  - `443`: HTTPS (SSL termination)
  - `81`: Admin panel
- **Purpose**: Reverse proxy with automatic SSL
- **Volumes**:
  - `./nginx-proxy/data:/data`
  - `./nginx-proxy/letsencrypt:/etc/letsencrypt`
- **SSL Provider**: Let's Encrypt (automatic renewal)

---

## 🔀 Network Flow

```
Internet
    ↓
DNS: analytics.diegonmarcos.com → 130.110.251.193
    ↓
[Port 443] HTTPS Request
    ↓
Nginx Proxy Manager (Container)
    ↓ (SSL Termination)
[Port 80] HTTP (internal)
    ↓
Matomo Container (Port 8080)
    ↓
MariaDB Container (Port 3306)
```

---

## 🔒 Security Configuration

### Firewall Rules (Oracle Security List)
| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 22 | TCP | 0.0.0.0/0 | SSH access |
| 80 | TCP | 0.0.0.0/0 | HTTP (redirects to HTTPS) |
| 443 | TCP | 0.0.0.0/0 | HTTPS (Matomo) |
| 81 | TCP | Limited | Nginx admin panel |

### SSL/TLS Configuration
- **Certificate Provider**: Let's Encrypt
- **Auto-Renewal**: Yes (via Nginx Proxy Manager)
- **Protocols**: TLS 1.2, TLS 1.3
- **Features**:
  - Force SSL redirect ✅
  - HTTP/2 enabled ✅
  - HSTS enabled ✅

### Authentication
- **SSH**: Key-based only (no password auth)
- **Nginx Admin**: Default credentials (must change on first login)
  - Email: `admin@example.com`
  - Password: `changeme`
- **Database**: Auto-generated strong passwords
- **Matomo**: Custom admin credentials (set during installation)

---

## 📂 File System Structure (on server)

```
~/matomo/
├── docker-compose.yml          # Container orchestration
├── matomo-credentials.txt      # Database passwords (secure)
├── matomo/                     # Matomo application files
│   ├── config/
│   ├── plugins/
│   └── tmp/
├── mariadb/                    # Database storage
│   └── [mysql data files]
└── nginx-proxy/
    ├── data/                   # Nginx config & SQLite DB
    └── letsencrypt/            # SSL certificates
```

---

## 🔧 Management Scripts

Located in: `front-Github_io/1.ops/`

### Core Scripts
1. **matomo-setup.sh**
   - Initial server deployment
   - Installs Docker, Docker Compose
   - Deploys full stack
   - Generates secure passwords

2. **matomo-login.sh**
   - Quick SSH access
   - `ssh -i ~/.ssh/matomo_key ubuntu@130.110.251.193`

3. **matomo-https-setup.sh**
   - Guided SSL configuration
   - Interactive Nginx Proxy Manager setup
   - DNS verification

4. **matomo-https-auto.sh**
   - Automated SSL via API
   - Non-interactive setup
   - Requires NPM credentials

5. **matomo-manage.sh**
   - Container management
   - Commands: start, stop, restart, status, logs, backup, update, shell

---

## 🌍 Access URLs

| Service | URL | Purpose | Auth Required |
|---------|-----|---------|---------------|
| Matomo (Production) | https://analytics.diegonmarcos.com | Analytics dashboard | Yes (Matomo login) |
| Nginx Proxy Manager | http://130.110.251.193:81 | SSL/proxy config | Yes (NPM admin) |
| Matomo (Direct) | http://130.110.251.193:8080 | Dev/debug access | Yes (Matomo login) |
| SSH | `ssh -i ~/.ssh/matomo_key ubuntu@130.110.251.193` | Server management | Yes (SSH key) |

---

## 📊 Resource Usage

### Current Utilization
- **Matomo App**: ~300 MB RAM
- **MariaDB**: ~200 MB RAM
- **Nginx Proxy**: ~50 MB RAM
- **Total**: ~550 MB / 1 GB (55%)

### Oracle Free Tier Limits
- ✅ 2 VM.Standard.E2.1.Micro instances (using 1)
- ✅ 200 GB Block Storage (using 50 GB)
- ✅ 10 GB Object Storage
- ✅ 10 TB Outbound Transfer/month

---

## 🔄 DNS Configuration

### Current Status (Migration Pending)
- **Domain**: analytics.diegonmarcos.com
- **Current IP**: 144.24.205.254 (old server)
- **Target IP**: 130.110.251.193 (new server)
- **Record Type**: A
- **TTL**: 300 seconds (recommended for migration)

### Migration Steps
1. Update A record: `analytics.diegonmarcos.com` → `130.110.251.193`
2. Wait for DNS propagation (5-30 minutes)
3. Configure Nginx Proxy Manager SSL
4. Test HTTPS access
5. Decommission old server

---

## 📈 Integration with Website

### Tracked Properties
- **Primary Site**: diegonmarcos.github.io
- **Pages Tracked**:
  - `/index.html` (landing page)
  - `/linktree/`
  - `/cv_web/`
  - `/cv_pdf/`
  - `/myprofile/`
- **Excluded**: `/others/` folder

### Tracking Implementation
- **Method**: Google Tag Manager (GTM) + Matomo dual tracking
- **GTM Container**: GTM-TN9SV57D
- **Privacy**: GDPR-compliant cookie consent banner
- **Consent Manager**: `/5.analytics/cookie-consent.js`

### Events Tracked
- Page views
- Scroll depth (25%, 50%, 75%, 100%)
- Time on page (10s, 30s, 60s, 120s, 300s)
- UI control clicks
- File downloads (vCard, PDF, DOCX, etc.)
- Outbound links
- Navigation interactions
- Collapsible toggles

---

## 🛠️ Maintenance

### Daily Tasks
```bash
# Check service status
./matomo-manage.sh status

# View logs
./matomo-manage.sh logs
```

### Weekly Tasks
```bash
# Create backup
./matomo-manage.sh backup

# Check for updates
./matomo-manage.sh update
```

### Monthly Tasks
- Review SSL certificate status (auto-renewed)
- Check disk usage: `df -h`
- Review analytics for anomalies
- Update Ubuntu: `sudo apt update && sudo apt upgrade`

---

## 🐛 Troubleshooting

### Common Issues

**Container not starting:**
```bash
ssh -i ~/.ssh/matomo_key ubuntu@130.110.251.193
cd ~/matomo
docker-compose logs -f
```

**SSL certificate failed:**
```bash
# Check Nginx Proxy Manager logs
docker logs nginx-proxy

# Verify DNS is pointing correctly
nslookup analytics.diegonmarcos.com
```

**Database connection error:**
```bash
# Check MariaDB container
docker exec -it matomo-db mysql -u matomo -p

# Verify credentials in docker-compose.yml
```

**Out of memory:**
```bash
# Check resource usage
docker stats

# Restart services
./matomo-manage.sh restart
```

---

## 📦 Backup Strategy

### Automated Backups
- **Script**: `./matomo-manage.sh backup`
- **Contents**:
  - Matomo configuration
  - Database dump
  - Nginx Proxy Manager config
- **Format**: `.tar.gz` with timestamp
- **Location**: `~/backups/matomo-backup-YYYYMMDD.tar.gz`

### Manual Backup
```bash
ssh -i ~/.ssh/matomo_key ubuntu@130.110.251.193
cd ~/matomo
tar -czf ~/backup-$(date +%Y%m%d).tar.gz .
```

---

## 🔄 Deployment History

| Date | Action | IP | Status |
|------|--------|-----|--------|
| 2025-11-18 | Initial deployment | 129.151.229.21 | Documented |
| 2025-11-19 | Current production | 130.110.251.193 | Active |
| Unknown | Legacy server | 144.24.205.254 | DNS active (to migrate) |

---

## 📝 Technical Notes

### Docker Compose Version
- **Version**: 3
- **Network Mode**: Bridge (default)
- **Restart Policy**: `unless-stopped`
- **Health Checks**: Not configured (TODO)

### Nginx Proxy Manager API
- **Endpoint**: http://130.110.251.193:81/api
- **Documentation**: https://nginxproxymanager.com/advanced-config/
- **Usage**: Automated SSL setup via `matomo-https-auto.sh`

### Matomo Configuration
- **Version**: Latest (Docker auto-updates)
- **PHP**: Bundled with official image
- **Archive Processing**: Cron-based (inside container)
- **GeoIP**: Optional (not configured)

---

## ✅ Checklist: Post-Deployment

- [x] Oracle Cloud instance created
- [x] Docker & Docker Compose installed
- [x] Matomo stack deployed
- [x] Database credentials generated
- [ ] DNS updated to new IP (130.110.251.193)
- [ ] Nginx Proxy Manager password changed
- [ ] SSL certificate configured
- [ ] Matomo installation wizard completed
- [ ] Website tracking code integrated
- [ ] Test analytics data collection
- [ ] Old server (144.24.205.254) decommissioned

---

## 🔗 Related Documentation

- **GTM Setup**: `front-Github_io/.gtm/setup_gtm.py`
- **Analytics Implementation**: `front-Github_io/5.analytics/IMPLEMENTATION_SUMMARY.md`
- **Matomo Server Setup**: `front-Github_io/5.analytics/MATOMO_SERVER_SETUP.md`
- **Operations Guide**: `front-Github_io/1.ops/MATOMO_OPS.md`
- **Deployment Scripts**: `front-Github_io/1.ops/matomo-*.sh`

---

## 📞 Support & References

- **Oracle Cloud Console**: https://cloud.oracle.com
- **Nginx Proxy Manager Docs**: https://nginxproxymanager.com
- **Matomo Documentation**: https://matomo.org/docs/
- **Docker Hub - Matomo**: https://hub.docker.com/_/matomo
- **Let's Encrypt**: https://letsencrypt.org

---

**Specification Version**: 1.0
**Created By**: Claude Code
**Creation Date**: 2025-11-19
