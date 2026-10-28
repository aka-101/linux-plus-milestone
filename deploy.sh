#!/bin/bash
# ============================================================
# Linux+ Milestone 2 — Server Deployment Script
#
# Student:     [Akbar Ali]
# Date:        [10-28-2026]
# Environment: Ubuntu 22.04 container (Docker)
# Scenario:    Deploy and harden a web server role
#
# HOW TO USE THIS SCRIPT:
#   1. Run ./run_container.sh to start your container environment
#   2. Inside the container, run: bash /opt/deploy/deploy.sh
#   3. Check output and fix any errors
#   4. Run ./test_deploy.sh to verify your deployment
#   5. Commit your work to GitHub with meaningful commit messages
#
# WHAT THIS SCRIPT MUST DO (each section is graded):
#   Section 1: Create a non-login service account
#   Section 2: Configure web root directory and permissions
#   Section 3: Install the web server package
#   Section 4: Enable and start the service
#   Section 5: Configure the firewall
#   Section 6: Set up log rotation via cron
#
# COMMENT REQUIREMENT:
#   Every section must have comments explaining WHAT you are doing and WHY.
#   Comments are graded. A correct command with no explanation earns partial credit.
#   A comment like "# add user" is not sufficient. Explain the security rationale.
#
# IMPORTANT NOTE ON SYSTEMCTL IN CONTAINERS:
#   systemctl may behave differently inside a Docker container than on a real server.
#   This is a known container limitation (systemd as PID 1 requires special flags).
#   You are expected to:
#     - Write the correct systemctl commands as you would on a real server
#     - Note in a comment what you observed when you ran the command
#     - Explain what you would verify on a production system
#   Full marks are awarded for correct syntax + honest documentation of container behavior.
# ============================================================

# ── LOGGING FUNCTION ─────────────────────────────────────────
# This function is provided for you. Use log "message" throughout your script
# to record what the script is doing. Required: all actions must appear in the log.
LOG_FILE="/var/log/deploy.log"

log() {
    # tee writes to both the terminal (so you can see it) and the log file
    echo "[$(date +%Y-%m-%dT%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

# Create log file directory if it doesn't exist
mkdir -p "$(dirname $LOG_FILE)"

log "============================================================"
log "Deployment script started"
log "Running as user: $(whoami)"
log "Environment: $(uname -a)"
log "============================================================"


# ── SECTION 1: Create Service Account ────────────────────────
# A service account is a user account created specifically to run a service or daemon.
# It should NOT be a regular login account.
#
# TODO: Create a user account named "webservice"
#       Requirements:
#         - No login shell (the account cannot be used to log in interactively)
#         - Home directory: /var/lib/webservice
#         - System account (use the appropriate flag)
#
# TODO: Add an explanatory comment that answers:
#         - Why should this account not have a login shell?
#         - What is the security risk if it does?
#         - Which flag sets a non-login shell and what value does it use?
#
# HINT: Look up: useradd --help or man useradd
#       Key flags: -r (system account), -s (shell), -d (home directory), -m (create home)

# YOUR CODE HERE:
# Create a non-interactive service account called webservice
# -Service accounts are used to execute background daemons and binaries and do not need human like interaction and a log in shell.
# -If a log in shell is assigned to a system account, it can open an interactive session, execute different command-line tools, 
#  explore and exploite operating system and root privileges.
# -The following command creates the webservice system account with its home directory and specifies its log in shell (nologin).       
sudo useradd -m -r -d /var/lib/webservice -s /usr/sbin/nologin webservice
log "User account webservice has been created"

log "Section 1 complete"


# ── SECTION 2: Configure Web Root Permissions ─────────────────
# The web root is where web server files are served from.
# Incorrect permissions here are a common security vulnerability.
#
# TODO: Create the directory /var/www/html if it does not already exist
#       Hint: mkdir with a flag to create parent directories silently
#
# TODO: Set the ownership of /var/www/html to the webservice account
#       The webservice user should own the files it serves.
#
# TODO: Set permissions on /var/www/html
#       The directory should be: owner=rwx, group=rx, other=rx
#       Translated to numeric: ???
#
# TODO: Create a simple placeholder index.html owned by webservice
#
# TODO: Add comments explaining:
#         - What does each part of the permission value mean? (owner/group/other)
#         - Why should "other" not have write permission on a web root?
#         - What is the numeric permission value you chose and why?

# YOUR CODE HERE:
# Create and configure a web root directory
# -Create the directory if it does not already exist, with parent directories as needed.
mkdir -p /var/www/html
log "Web root directory has been created"

# Set the ownership of /var/www/html to the webservice account
sudo chown -R webservice:webservice /var/www/html

# Set proper permissions on /var/www/html directory (owner=rwx, group=rx, other=rx) or 755. 
# Starting from left, the permission values are Owner, Group, and Other users.
# "Other" should not have any write (w) permission on the web root. A local user or
# exploited process can modify, delete a file, or add malicious files.  
sudo chmod 755 /var/www/html

# Create a placeholder file index.html as the default home page that the web server will load.
echo "<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome</title>
    <style>
        body { font-family: sans-serif; text-align: center; padding: 50px; background: #f4f4f4; }
        h1 { color: #333; }
    </style>
</head>
<body>
    <h1>This is a placeholder page for automating a web server deployment using Bash scripting</h1>
    <p>More to come!</p>
</body>
</html>" > index.html 

log "Section 2 complete"


# ── SECTION 3: Install Web Server Package ─────────────────────
# Package managers install, update, and remove software on Linux systems.
# In Ubuntu/Debian systems, the package manager is apt.
#
# TODO: Install the apache2 web server package using apt-get
#       The -y flag accepts prompts automatically (required for scripting)
#       The DEBIAN_FRONTEND=noninteractive variable is already set in the Dockerfile
#
# TODO: Verify the installation succeeded before continuing
#       Hint: check the exit code ($?) after the install command
#       If it failed, log a message and exit with a non-zero status
#
# TODO: Add comments explaining:
#         - Why apache2 and not another web server?
#         - What does the -y flag do and why is it necessary in a script?
#         - What does verifying the exit code protect against?

# YOUR CODE HERE:
# Why install apache2?:
# apache2 is a robust web server that works well with Ubuntu and other Debian-based distributions.
# It is very flexible, part of Ubuntu echo system, and works well with the apt package management system.    
# Install the apache2 web server with the -y flag. 
# For package managers such as apt, the installation process is interactive where 
# a human answers the prompts Yes(y) or No(n).
# The -y flag automatically accepts the prompts which ie required in scripting.  
sudo apt-get update
sudo apt-get install apache2 -y

# Verify if the apache2 installation succeeded by capturing the exit status code in the $? variable.
# The $? variable holds the value of most recent executed script, command, or a function. 
# The 0 value means it succeded, non-0 value means it failed.
# Check if the exit_status not equal to 0. If it is, then the apche2 installation has failed.
# Print an error message with a non-zero status code.
# Verifying the exit code protects against hidden silent failures, data loss and corruption.
# If the commands are dependent on each other and some commands executions fail, there will be a cascading effect.

# Save the exit status code to a local variable. It's good practice.
exit_status=$?
if [ $exit_status -ne 0 ]; then
    echo "Automation step failed with exit code : $exit_status"
    exit
fi
log "apache2 installation complete"
log "Section 3 complete"


# ── SECTION 4: Enable and Start the Service ───────────────────
# systemd manages services on modern Linux systems.
# Two separate steps: enable (start at boot) and start (start now).
#
# TODO: Enable the apache2 service to start automatically at boot
#       Command: systemctl enable apache2
#
# TODO: Start the apache2 service
#       Command: systemctl start apache2
#
# TODO: IMPORTANT — Document your container observations:
#       Run these commands and note what happens.
#       In a standard Docker container, systemctl may print an error or behave
#       differently than on a real server. This is expected.
#
# TODO: Add comments explaining:
#         - What is the difference between systemctl enable and systemctl start?
#         - What would you run on a real server to verify the service is running?
#         - What did you observe when you ran systemctl in this container?
#           (Document the actual output or error you saw)
#         - Why does systemctl behave differently in a container vs. a real server?

# YOUR CODE HERE:
# systemctl enable starts apache2 automatically when the machine boots
# systemctl start starts the service immediately
# On a real server, to check if the service is running: systemctl status apache2
# systemctl behaves differently in containers because of the absence of systemd service manager running init.
# In real servers and virtual machines, systemd runs as Process ID 1 and manages system services, processes, hardware events, and logging.  
systemctl enable apache2
systemctl start apache2
log "Section 4 complete"

# Observation when I ran sytemctl enable apache2 and sytemctl start apache2 in the container: 
# Upon running systemctl enable apache2 directly, I received the following output: 
# Synchronizing state of apache2.service with Sysv service script with /lib/systemd/systemd-sysv-install.
# Executing: /lib/systemd/systemd-sysv-install enable apache2
# root@dbbf1ee841fd:/opt/deploy# systemctl start apache2
# System has not been booted with systemd as init system (PID 1). Can't operate.
# Failed to connect to bus: Host is down

# ── SECTION 5: Configure Firewall ────────────────────────────
# A firewall controls which network traffic is allowed in and out.
# ufw (Uncomplicated Firewall) provides a simplified interface to iptables.
#
# TODO: Allow inbound HTTP traffic (port 80/tcp)
# TODO: Allow inbound HTTPS traffic (port 443/tcp)
# TODO: Enable the firewall
#       Use --force flag to avoid interactive "y/n" prompt in a script
#
# TODO: Add comments explaining:
#         - Why do we need both port 80 and port 443?
#         - What is the default ufw policy for inbound traffic before you run these commands?
#         - What container-specific behavior did you observe with ufw?
#           (ufw may print warnings in a container — document what you saw)
#
# HINT: ufw --help or man ufw
#       ufw allow PORT/PROTOCOL, then ufw --force enable

# YOUR CODE HERE:
# Why need port 80 and 443?: 
# port 80 is used for the old unencrypted http protocol traffic. It is mainly used for backward compatibility or redirection to port 443.
# port 443 is the encrypted https protocol for secure transfer. 
# The default ufw policy for inbound deny.
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Container-specific behavior I noticed in the container:
# sysctl: setting key "net.ipv4.conf.all.accept_redirects", ignoring: Read-only file system
# sysctl: setting key "net.ipv4.conf.default.accept_redirects", ignoring: Read-only file system
# sysctl: setting key "net.ipv6.conf.all.accept_redirects", ignoring: Read-only file system
# sysctl: setting key "net.ipv6.conf.default.accept_redirects", ignoring: Read-only file system
# sysctl: setting key "net.ipv4.icmp_echo_ignore_broadcasts", ignoring: Read-only file system
# sysctl: setting key "net.ipv4.icmp_ignore_bogus_error_responses", ignoring: Read-only file system
# sysctl: setting key "net.ipv4.icmp_echo_ignore_all", ignoring: Read-only file system
# sysctl: setting key "net.ipv4.conf.all.log_martians", ignoring: Read-only file system
# sysctl: setting key "net.ipv4.conf.default.log_martians", ignoring: Read-only file system

# Problem loading ipv6 (skipping)
# Problem running '/etc/ufw/before.rules'
# Problem running '/etc/ufw/after.rules'
# Problem running '/etc/ufw/user.rules'

log "Section 5 complete"


# ── SECTION 6: Log Rotation Cron Job ─────────────────────────
# Log files grow indefinitely without rotation. Log rotation compresses
# old logs and removes files beyond a retention limit.
# A cron job schedules this task to run automatically.
#
# TODO: Add a cron job that runs logrotate weekly
#       The cron job should run as root (add to root's crontab)
#       Cron syntax: minute hour day month weekday command
#       For weekly: 0 2 * * 0 (2am every Sunday)
#       Command: /usr/sbin/logrotate /etc/logrotate.conf
#
# TODO: Log a confirmation that the cron entry was added
#
# TODO: Add comments explaining:
#         - What happens if log rotation is never configured?
#         - What does each field in the cron expression mean?
#         - What is /etc/logrotate.conf and what does it control?
#
# HINT: To add a cron job from a script without overwriting existing crontab:
#       (crontab -l 2>/dev/null; echo "0 2 * * 0 /usr/sbin/logrotate /etc/logrotate.conf") | crontab -

# YOUR CODE HERE:
# Add a logrotate cron job that runs weekly
# If log rotation is not configured may become full. Applications may start crashing when the disk space runs out of capacity.
# Cron expression fields represent the day of the week(0-6), month(1-12), day of the month(1-31), hour(0-23), minute(0-59) 
# /etc/logrotate.conf is the configuration file for logrotate. It automates the routine rotation, compression, archiving, 
# and removal of application and system logs to save didk space. 
 (sudo crontab -l 2>/dev/null; echo "0 2 * * 0 /usr/sbin/logrotate /etc/logrotate.conf") | sudo crontab -
 log "logrotate cron job has been added"

log "Section 6 complete"
log "============================================================"
log "Deployment script completed"
log "Run test_deploy.sh to verify your deployment"
log "============================================================"