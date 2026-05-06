#!/bin/bash
echo "------------------------------------------"
echo "STARTING DEPLOYMENT SCRIPT: $(date)"
echo "------------------------------------------"

# 1. Update and Install
apt-get update
apt-get install -y default-jdk stress
apt-get install -y openjdk-17-jre curl

# 2. SSH & Guest Agent Force-Start
systemctl enable google-guest-agent
systemctl start google-guest-agent
systemctl enable ssh
systemctl start ssh

# NEW: Ensure SSH config allows password-less key auth (Standard for GCP)
sed -i 's/^#\?PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config
systemctl reload ssh

# 3. Grant sudo privileges
echo "deepu4learn ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 4. Wait for Network & Pull JAR
echo "Waiting for network stability..."
sleep 10
echo "Fetching app.jar from Google Cloud Storage..."
/usr/bin/gsutil cp gs://helloworld-binaries-project-cb063053-ca79-4fea-9b1/app.jar /tmp/app.jar

# 5. Verify download and start the app
if [ -f "/tmp/app.jar" ]; then
    echo "Success: app.jar found. Starting application on port 8081..."

    # Fetch hostname
    VM_NAME=$(curl -s -H "Metadata-Flavor: Google" --connect-timeout 2 http://metadata.google.internal/computeMetadata/v1/instance/name)
    echo "Identified as: $VM_NAME"

    export SERVER_NAME=$VM_NAME
    # Using 'nohup' and '&' to ensure it survives the script exit
    nohup java -Dserver.name="$VM_NAME" -jar /tmp/app.jar > /tmp/app.log 2>&1 &

    echo "Application is running in background on $VM_NAME."
else
    echo "ERROR: app.jar failed to download from GCS bucket."
fi

echo "------------------------------------------"
echo "DEPLOYMENT SCRIPT FINISHED"
echo "------------------------------------------"