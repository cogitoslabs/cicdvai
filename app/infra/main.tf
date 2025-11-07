terraform {
  required_providers {
    google = { source = "hashicorp/google" }
    time   = { source = "hashicorp/time" }
  }
}

locals {
  config_env = {
    for line in split("\n", file("${path.module}/../../config.env")) :
    split("=", line)[0] => trimspace(replace(split("=", line)[1], "\"", ""))
    if length(line) > 0 && can(split("=", line)[1])
  }

  bootstrap_env = {
    for line in split("\n", file("${path.module}/../../bootstrap_outputs.env")) :
    split("=", line)[0] => trimspace(replace(split("=", line)[1], "\"", ""))
    if length(line) > 0 && can(split("=", line)[1])
  }

  app_project_id        = local.config_env.APP_PROJECT_ID
  billing_account_id    = local.config_env.BILLING_ACCOUNT_ID
  region                = local.bootstrap_env.REGION
  bootstrap_project_id  = local.bootstrap_env.BOOTSTRAP_PROJECT_ID
}

provider "google" {
  project = local.app_project_id
  region  = local.region
}

# 1️⃣ Create App Project (under no-org if trial)
resource "google_project" "app_project" {
  name            = "App Project"
  project_id      = local.app_project_id
  billing_account = local.billing_account_id
}

# 2️⃣ Enable Required APIs
locals {
  apis = [
    "run.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "iam.googleapis.com",
    "compute.googleapis.com",
    "cloudbilling.googleapis.com"  # Added Cloud Billing API
  ]
}

resource "google_project_service" "enabled_apis" {
  for_each = toset(local.apis)
  project  = google_project.app_project.project_id
  service  = each.key
}

# 3️⃣ Create a Service Account for Cloud Build Deployments
resource "google_service_account" "app_sa" {
  account_id   = "app-deployer"
  display_name = "App Cloud Run Deployer"
  project      = google_project.app_project.project_id
}

# 4️⃣ Grant Required Roles
resource "google_project_iam_member" "app_sa_roles" {
  for_each = toset([
    "roles/run.admin",
    "roles/storage.admin",
    "roles/artifactregistry.reader",
    "roles/iam.serviceAccountUser"
  ])

  project = google_project.app_project.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.app_sa.email}"
}

# 5️⃣ Create Artifact Registry for App Images (in bootstrap project)
resource "google_artifact_registry_repository" "app_repo" {
  project      = local.bootstrap_project_id
  location     = local.region
  repository_id = "${local.app_project_id}-repo"
  format        = "DOCKER"
}

output "app_project_id" {
  value = google_project.app_project.project_id
}
