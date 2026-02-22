#!/bin/bash
set -euo pipefail

# User data script to install and configure Mountpoint for Amazon S3
# This script will:
# 1. Install mount-s3
# 2. Create mount point directory
# 3. Create systemd service for persistent mounting

LOG_FILE="/var/log/s3-mount-setup.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Starting S3 mount setup for bucket: ${bucket_name}"

# Update package cache
log "Updating package cache..."
apt-get update -y || {
    log "ERROR: Failed to update package cache"
    exit 1
}

# Install mount-s3 (Mountpoint for Amazon S3)
log "Installing mount-s3..."
cd /tmp
wget -O mount-s3.deb https://s3.amazonaws.com/mountpoint-s3-release/latest/x86_64/mount-s3.deb || {
    log "ERROR: Failed to download mount-s3"
    exit 1
}
log "Installing mount-s3 package..."
apt-get install -y /tmp/mount-s3.deb || {
    log "ERROR: Failed to install mount-s3"
    exit 1
}
rm -f /tmp/mount-s3.deb

# Verify installation
if ! command -v mount-s3 &> /dev/null; then
    log "ERROR: mount-s3 installation failed"
    exit 1
fi
log "mount-s3 installed successfully: $(mount-s3 --version)"

# Create mount point directory
log "Creating mount point: ${mount_point}"
mkdir -p "${mount_point}"

# Determine mount options based on read-only flag
if [ "${mount_options}" = "ro" ]; then
    MOUNT_S3_OPTIONS="--read-only"
else
    MOUNT_S3_OPTIONS=""
fi

# Create systemd service for S3 mount (better than .mount unit for mount-s3)
log "Creating systemd service for S3 mount..."
cat > /etc/systemd/system/s3-mount.service << EOF
[Unit]
Description=Mount S3 bucket ${bucket_name} at ${mount_point}
After=network-online.target
Wants=network-online.target

[Service]
Type=forking
ExecStartPre=/usr/bin/mkdir -p ${mount_point}
ExecStart=/usr/bin/mount-s3 --allow-other --uid 1000 --gid 1000$${MOUNT_S3_OPTIONS:+ $MOUNT_S3_OPTIONS} ${bucket_name} ${mount_point}
ExecStop=/usr/bin/umount ${mount_point}
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd
log "Reloading systemd..."
systemctl daemon-reload

# Enable and start the mount service
log "Enabling and starting S3 mount service..."
systemctl enable s3-mount.service
systemctl start s3-mount.service

# Wait a moment for mount to settle
sleep 3

# Verify mount
if mountpoint -q "${mount_point}"; then
    log "SUCCESS: S3 bucket mounted at ${mount_point}"
    df -h "${mount_point}" | tee -a "$LOG_FILE"
    ls -la "${mount_point}" | tee -a "$LOG_FILE"
else
    log "ERROR: Mount verification failed"
    systemctl status s3-mount.service | tee -a "$LOG_FILE"
    journalctl -u s3-mount.service -n 50 --no-pager | tee -a "$LOG_FILE"
    exit 1
fi

log "S3 mount setup completed successfully"
