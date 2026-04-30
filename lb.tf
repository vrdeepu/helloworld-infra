# 1. Reserve a Global Static IP Address
resource "google_compute_global_address" "lb_static_ip" {
  name = "helloworld-lb-ip"
}

# 2. Backend Service (Connects the LB to your Instance Group)
resource "google_compute_backend_service" "helloworld_backend" {
  name                  = "helloworld-backend-service"
  protocol              = "HTTP"
  port_name             = "http-web" # This MUST match the named_port in your MIG
  load_balancing_scheme = "EXTERNAL_MANAGED"
  timeout_sec           = 30
  health_checks         = [google_compute_region_health_check.java_app_health_check.id]

  backend {
    group           = google_compute_region_instance_group_manager.helloworld_mig.instance_group
    balancing_mode  = "UTILIZATION"
    capacity_scaler = 1.0
  }
}

# 3. URL Map (The "Routing Table" for the LB)
resource "google_compute_url_map" "helloworld_url_map" {
  name            = "helloworld-url-map"
  default_service = google_compute_backend_service.helloworld_backend.id
}

# 4. Target HTTP Proxy (The component that receives the request)
resource "google_compute_target_http_proxy" "helloworld_http_proxy" {
  name    = "helloworld-http-proxy"
  url_map = google_compute_url_map.helloworld_url_map.id
}

# 5. Global Forwarding Rule (The actual "Front Door" listener)
resource "google_compute_global_forwarding_rule" "helloworld_forwarding_rule" {
  name                  = "helloworld-forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.helloworld_http_proxy.id
  ip_address            = google_compute_global_address.lb_static_ip.id
}

# 6. Firewall Rule (Allowing Google's LB to talk to your VMs)
resource "google_compute_firewall" "allow_lb_to_vms" {
  name          = "allow-lb-to-vms"
  direction     = "INGRESS"
  network       = "default" # Ensure this matches your VPC name
  source_ranges = ["130.211.0.0/22", "35.191.0.0/16"]
  allow {
    protocol = "tcp"
    ports    = ["8081"]
  }
  target_tags = ["allow-http"]
}