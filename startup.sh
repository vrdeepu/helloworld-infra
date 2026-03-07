#!/bin/bash
apt-get update
apt-get install -y openjdk-17-jdk
#Ensure the guest agent is running for SSH/SCP
systemctl enable google-guest-agent
systemctl start google-guest-agent
#Grant your deployment user sudo privileges
echo "deepu4learn ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
