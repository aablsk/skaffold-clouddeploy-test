# Cloud Build SA
resource "google_service_account" "cloud_build" {
  account_id = "cloud-build"
}

# Cloud Build trigger configuration
resource "google_cloudbuild_trigger" "skaffold_cd_test" {
  name     = "render-test-deploy"
  project  = var.project_id
  location = var.region

  github {
    owner = var.repo_owner
    name  = var.repo_name

    push {
      branch = "^${var.repo_branch}$"
    }
  }

  included_files = ["modules/**", "cloudbuild.yaml", "artifacts.json", "skaffold.yaml"]
  filename       = "cloudbuild.yaml"
  substitutions = {
    _PROFILES              = "kustomize-simple"
    _SKAFFOLD_VERSION      = "v2.2.0"
  }
  service_account = google_service_account.cloud_build.id
}

resource "google_service_account_iam_member" "cloud_build_impersonate_cloud_deploy" {
  service_account_id = google_service_account.cloud_deploy.id
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cloud_build.email}"
}
