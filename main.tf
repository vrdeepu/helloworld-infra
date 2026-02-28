provider "google" {
  project = "YOUR_PROJECT_ID" # Replace with your actual Project ID
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

  metadata_startup_script = "sudo apt-get update && sudo apt-get install -y default-jdk"
}

output "vm_ip" {
  value = google_compute_instance.helloworld_vm.network_interface[0].access_config[0].nat_ip
}
