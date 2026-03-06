provider "google" {
  project = "project-cb063053-ca79-4fea-9b1" # Replace with your actual Project ID
  region  = "us-central1"
}

resource "google_compute_instance" "helloworld_vm" {
  name         = "basic-hello-vm"
  machine_type = "e2-micro"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = "default"
    access_config {} 
  }

  metadata_startup_script = <<-EOF
#!/bin/bash
# 1. Update package list and install JDK 17
apt-get update
apt-get install -y openjdk-17-jdk
# 2. Ensure the guest agent is running for SSH/SCP
systemctl enable google-guest-agent
systemctl start google-guest-agent
# 3. Grant your deployment user sudo privileges
echo "deepu4learn ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
EOF
}

output "vm_ip" {
  value = google_compute_instance.helloworld_vm.network_interface[0].access_config[0].nat_ip
}
