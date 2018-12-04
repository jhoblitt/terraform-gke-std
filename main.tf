provider "google" {
  version = "~> 1.13"
  alias   = "gke_std"

  project = "${var.google_project}"
  region  = "us-central1"
  zone    = "us-central1-b"
}

provider "kubernetes" {
  version = "~> 1.3"
  alias   = "gke_std"

  host                   = "${google_container_cluster.gke_std.endpoint}"
  client_certificate     = "${base64decode("${google_container_cluster.gke_std.master_auth.0.client_certificate}")}"
  client_key             = "${base64decode("${google_container_cluster.gke_std.master_auth.0.client_key}")}"
  cluster_ca_certificate = "${base64decode("${google_container_cluster.gke_std.master_auth.0.cluster_ca_certificate}")}"
}

resource "google_container_cluster" "gke_std" {
  provider = "google.gke_std"

  name               = "${var.name}"
  initial_node_count = "${var.initial_node_count}"
  min_master_version = "${var.gke_version}"
  node_version       = "${var.gke_version}"
  enable_legacy_abac = false

  monitoring_service = "none"

  addons_config {
    http_load_balancing {
      disabled = false
    }

    kubernetes_dashboard {
      disabled = true
    }

    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  maintenance_policy {
    daily_maintenance_window {
      start_time = "03:00"
    }
  }

  node_config {
    image_type   = "COS"
    machine_type = "${var.machine_type}"

    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }
}
