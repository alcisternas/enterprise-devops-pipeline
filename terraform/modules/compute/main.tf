resource "google_compute_instance" "vm" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  project      = var.project_id

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size_gb
    }
  }

  network_interface {
    network    = var.network
    subnetwork = var.subnetwork

    access_config {
      // Ephemeral public IP
    }
  }

  metadata = {
    startup-script = var.startup_script
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }

  tags = var.network_tags

  allow_stopping_for_update = true
}

resource "google_compute_firewall" "allow_jenkins" {
  count   = var.create_firewall ? 1 : 0
  name    = "${var.instance_name}-allow-jenkins"
  network = var.network
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["8080", "22"]
  }

  source_ranges = var.allowed_source_ranges
  target_tags   = var.network_tags
}