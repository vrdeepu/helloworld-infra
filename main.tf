provider "google" {
  project = "project-cb063053-ca79-4fea-9b1" # Replace with your actual Project ID
  region  = "us-central1"
}
resource "google_compute_instance_template" "helloworld_template" {
  name_prefix  = "hello-java-template-"
  machine_type = "e2-micro"
  region       = "us-central1"
  tags         = ["http-server"]

  disk {
    source_image = "debian-cloud/debian-11"
    auto_delete  = true
    boot         = true
  }

  network_interface {
    network = "default"
    access_config {} # Gives external IPs for now
  }

  metadata = {
    serial-port-enable = "1"
  }

  metadata_startup_script = replace(file("${path.module}/startup.sh"), "\r\n", "\n")

  service_account {
    email  = data.google_compute_default_service_account.default.email
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  lifecycle {
    create_before_destroy = true
  }
}
resource "google_compute_health_check" "http_8081" {
  name   = "java-app-health-check"
  #region = "us-central1" removing  for making the health check global

  http_health_check {
    port = 8081
  }
}
resource "google_compute_region_instance_group_manager" "helloworld_mig" {
  name               = "helloworld-mig"
  base_instance_name = "basic-hello-vm"
  region             = "us-central1"
  target_size        = 2

  version {
    instance_template = google_compute_instance_template.helloworld_template.id
  }

  # This maps the MIG to port 8081 for the Load Balancer later
  named_port {
    name = "http-web"
    port = 8081
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.http_8081.id
    initial_delay_sec = 300 # Wait 5 mins for Java to install before checking health
  }
}
output "mig_instance_group" {
  value = google_compute_region_instance_group_manager.helloworld_mig.instance_group
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
#autoscaler implemetation
resource "google_compute_region_autoscaler" "helloworld_autoscaler" {
  name   = "helloworld-autoscaler"
  region = "us-central1"
  target = google_compute_region_instance_group_manager.helloworld_mig.id

  autoscaling_policy {
    max_replicas    = 5   # Maximum number of VMs to scale up to
    min_replicas    = 1   # Minimum number of VMs to keep running
    cooldown_period = 60  # Wait 60s after scaling before making another decision

    cpu_utilization {
      target = 0.5 # Scale up when average CPU across the group hits 50%
    }
  }
}