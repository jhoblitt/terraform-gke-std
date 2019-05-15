locals {
  gke_version = "${var.gke_version != "latest" ? var.gke_version : data.google_container_engine_versions.gke_std.latest_node_version}"
}

provider "google" {
  alias = "gke_std"

  project = "${var.google_project}"
  region  = "${var.google_region}"
  zone    = "${var.google_zone}"
}

provider "kubernetes" {
  version = "1.6.2"
  alias   = "gke_std"

  load_config_file = true
  config_path      = "${local.kubeconfig_filename}"
}

resource "null_resource" "k8s_ready" {
  provisioner "local-exec" {
    working_dir = "${path.module}"

    command = <<EOS
for i in `seq 1 10`; do \
kubectl --kubeconfig ${null_resource.k8s_ready.triggers.config_path} get ns && break || \
sleep 10; \
done; \
EOS

    interpreter = ["/bin/sh", "-c"]
  }

  triggers {
    config_path = "${local_file.kubeconfig.filename}"
    kubeconfig  = "${local_file.kubeconfig.content}"
  }

  depends_on = [
    "local_file.kubeconfig",
    "google_container_cluster.gke_std",
  ]
}

data "google_container_engine_versions" "gke_std" {
  provider = "google.gke_std"
}

resource "google_container_cluster" "gke_std" {
  provider = "google.gke_std"

  name               = "${var.name}"
  min_master_version = "${local.gke_version}"
  node_version       = "${local.gke_version}"
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

  node_pool {
    name               = "default-pool"
    initial_node_count = "${var.initial_node_count}"

    management {
      auto_repair  = "true"
      auto_upgrade = "true"
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

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  lifecycle {
    ignore_changes = [
      "initial_node_count",
      "node_pool.0.node_config.0.metadata",
    ]
  }
}
