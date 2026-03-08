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

  metadata_startup_script = replace(file("${path.module}/startup.sh"), "\r\n", "\n")
}

output "vm_ip" {
  value = google_compute_instance.helloworld_vm.network_interface[0].access_config[0].nat_ip
}
