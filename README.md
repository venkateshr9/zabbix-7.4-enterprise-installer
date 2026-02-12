# 🚀 Zabbix 7.4 Enterprise Auto Installer
CentOS Stream 10 | Hardened | Production Ready

![CentOS](https://img.shields.io/badge/OS-CentOS%20Stream%2010-blue)
![Zabbix](https://img.shields.io/badge/Zabbix-7.4.6-red)
![License](https://img.shields.io/badge/License-MIT-green)
![Status](https://img.shields.io/badge/Status-Production%20Ready-brightgreen)

## 📌 Overview
This project provides an enterprise-grade automated installation script...


## 📌 Overview

This project provides an **enterprise-grade automated installation script**
for deploying **Zabbix 7.4.6** on **CentOS Stream 10** with:

- ✅ SELinux Enforcing Mode
- ✅ Firewall Configuration
- ✅ MariaDB Auto Tuning
- ✅ Secure Random Database Password
- ✅ Production & Lab SSH Modes
- ✅ HTTPS (mod_ssl)
- ✅ Automatic Schema Import
- ✅ Service Health Verification
- ✅ Logging & Failure Detection

---

## 🛠 Tested Environment

| Component | Version |
|-----------|----------|
| OS | CentOS Stream 10 |
| Zabbix | 7.4.6 |
| PHP | 8.3 |
| MariaDB | 10.11 |
| SELinux | Enforcing |

---

## 📦 Features

### 🔐 Security
- SSH Secure Mode (Disable root & password login)
- SELinux enforcing with required booleans
- Firewall hardened rules
- TLS enabled web interface

### ⚙ Database
- Auto-generated strong DB password
- MariaDB buffer pool tuning (50% RAM)
- utf8mb4 character support
- Automatic schema import

### 🌐 Web
- HTTPS enabled
- PHP optimized for Zabbix
- Service verification after install

---

## ▶ Installation

### 1️⃣ Download Script

```bash
wget https://raw.githubusercontent.com/venkateshr9/zabbix-7.4-enterprise-installer/main/zabbix_install.sh
2️⃣ Make Executable
bash
Copy code
chmod +x zabbix_install.sh
3️⃣ Run as Root
bash
Copy code
sudo ./zabbix_install.sh
🔑 Default Web Login
After installation:

makefile
Copy code
URL: https://<server-ip>/zabbix
Username: Admin
Password: zabbix
⚠ Change password immediately after login.

📁 Log File
Installation log stored at:

bash
Copy code
/var/log/zabbix_7.4.6_hardened_install.log
📌 SSH Modes
During installation, you can choose:

1️⃣ Secure Mode (Production Recommended)
2️⃣ Lab Mode (Root + Password login allowed)

👨‍💻 Author
Venkatesh Ramalingam
Network & Systems Engineer
Zabbix | Linux | VMware | DevOps | Observability

⚠ Disclaimer
This script is intended for lab and production deployment.
Always test in staging before production rollout.

⭐ If This Helped You
Please ⭐ Star the repository
Subscribe to the YouTube channel @technousher


Share with your team
