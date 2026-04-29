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

    # Fetch the unique hostname (with a 2-second connect timeout for stability)
    VM_NAME=$(curl -s -H "Metadata-Flavor: Google" --connect-timeout 2 http://metadata.google.internal/computeMetadata/v1/instance/name)
    echo "Identified as: $VM_NAME"

    # Pass it to Java.
    # Tip: 'export' makes it an Environment Variable,
    # '-D' makes it a Java System Property. Doing both covers all bases!
    export SERVER_NAME=$VM_NAME
    nohup java -Dserver.name="$VM_NAME" -jar /tmp/app.jar > /tmp/app.log 2>&1 &

    echo "Application is running in background on $VM_NAME."
else
    echo "ERROR: app.jar failed to download from GCS bucket."
fi

echo "------------------------------------------"
echo "DEPLOYMENT SCRIPT FINISHED"
echo "------------------------------------------"