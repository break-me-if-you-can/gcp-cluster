terraform {
  backend "gcs" {
    bucket = "breakme-terraform-state"
    prefix = "cluster-terraform.tfstate"
    //project = "breakme"
  }
}


provider "google" {
  project = "breakme"
  region = "us-west1"
}

resource "google_container_cluster" "demo_cluster" {
  name = "k8s-cluster"
  zone = "us-west1-a"
  initial_node_count = 4

  master_auth {
    username = "${var.cluster_auth_user}"
    password = "${var.cluster_auth_pwd}"
  }

  node_config {
    oauth_scopes = [
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/trace.append"
    ]
  }
}
