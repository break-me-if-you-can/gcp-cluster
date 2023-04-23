terraform {
  backend "gcs" {
    bucket = "breakme-terraform-state"
    prefix = "cluster-terraform.tfstate"
  }
}

provider "google" {
  project = "${var.gcp_project}"
  region = "europe-west3"
  zone = "europe-west3-a"
}

resource "google_service_account" "default" {
  account_id   = "default-service-account-id"
  display_name = "Default Service Account"
}

resource "google_project_service" "container_service" {
  project = "${var.gcp_project}"
  service = "container.googleapis.com"
}

resource "google_container_cluster" "demo_cluster" {
  name     = "k8s-cluster"
  location = "europe-west3-a"

  # We can't create a cluster with no node pool defined, but we want to only use
  # separately managed node pools. So we create the smallest possible default
  # node pool and immediately delete it.
  remove_default_node_pool = true
  initial_node_count       = 1
}


resource "google_container_node_pool" "demo_primary_pool" {
  name       = "k8s-cluster"
  location   = "europe-west3-a"
  cluster    = google_container_cluster.demo_cluster.name
  node_count = 4

  node_config {
    preemptible  = true
    machine_type = "e2-standard-2"

    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    service_account = google_service_account.default.email
    oauth_scopes    = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/compute",
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/trace.append",
      "https://www.googleapis.com/auth/devstorage.read_only"
    ]
  }
}

resource "google_project_iam_member" "allow_image_pull" {
  project = "${var.gcp_project}"
  role   = "roles/storage.objectViewer"
  member = "serviceAccount:default-service-account-id@${var.gcp_project}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "allow_stackdriver" {
  project = "${var.gcp_project}"
  role   = "roles/monitoring.metricWriter"
  member = "serviceAccount:default-service-account-id@${var.gcp_project}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "allow_trace" {
  project = "${var.gcp_project}"
  role   = "roles/cloudtrace.agent"
  member = "serviceAccount:default-service-account-id@${var.gcp_project}.iam.gserviceaccount.com"
}
