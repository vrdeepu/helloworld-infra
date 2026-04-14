provider "google" {
  project = "project-cb063053-ca79-4fea-9b1" # Replace with your actual Project ID
  region  = "us-central1"
}

resource "google_compute_instance" "helloworld_vm" {
  count = 2 #create two vms
  name         = "basic-hello-vm-${count.index +1 }"
  machine_type = "e2-micro"
  zone         = "us-central1-a"
  tags = ["http-server"]

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
  value = google_compute_instance.helloworld_vm[*].network_interface[0].access_config[0].nat_ip
}
# Create the Storage Bucket for our JAR files
resource "google_storage_bucket" "app_binaries" {
  name          = "helloworld-binaries-project-cb063053-ca79-4fea-9b1" # Must be unique
  location      = "US" # Multi-region for high availability
  force_destroy = true # Allows Terraform to delete the bucket even if it has files in it
  uniform_bucket_level_access = true
  public_access_prevention = "enforced"
}

# Output the bucket name so we can use it in Jenkins
output "bucket_name" {
  value = google_storage_bucket.app_binaries.name
}
data "google_compute_default_service_account" "default" {
}

resource "google_storage_bucket_iam_member" "viewer" {
  bucket = google_storage_bucket.app_binaries.name
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}