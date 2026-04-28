#!/bin/bash
# 1. Logging header (Makes it easy to find in Serial Console)
echo "------------------------------------------"
echo "STARTING DEPLOYMENT SCRIPT: $(date)"
echo "------------------------------------------"

# 2. Existing setup
apt-get update
apt-get install -y openjdk-17-jre # jre is enough to run, jdk is fine too

# 3. Ensure the guest agent is running
systemctl enable google-guest-agent
systemctl start google-guest-agent

# 4. Grant sudo privileges
echo "deepu4learn ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# 5. NEW: Pull the JAR from the bucket
echo "Fetching app.jar from Google Cloud Storage..."
/usr/bin/gsutil cp gs://helloworld-binaries-project-cb063053-ca79-4fea-9b1/app.jar /tmp/app.jar

# 6. Verify download and start the app
if [ -f "/tmp/app.jar" ]; then
    echo "Success: app.jar found. Starting application on port 8081..."
    # We use nohup so the app keeps running after the script finishes
    nohup java -jar /tmp/app.jar > /tmp/app.log 2>&1 &
    echo "Application is running in background."
else
    echo "ERROR: app.jar failed to download from GCS bucket."
fi

echo "------------------------------------------"
echo "DEPLOYMENT SCRIPT FINISHED"
echo "------------------------------------------"