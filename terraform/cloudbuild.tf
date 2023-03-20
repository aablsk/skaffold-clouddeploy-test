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

  included_files = ["**/**"]
  filename       = "cloudbuild.yaml"
  substitutions = {
    _PROFILES              = "kustomize-simple"
    _SKAFFOLD_VERSION      = "v2.2.0"
    _SOURCE_STAGING_BUCKET = "gs://${google_storage_bucket.release_source_staging.name}"
  }
  service_account = google_service_account.cloud_build.id
}

resource "google_service_account_iam_member" "cloud_build_impersonate_cloud_deploy" {
  service_account_id = google_service_account.cloud_deploy.id
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.cloud_build.email}"
}

# GCS bucket used by Cloud Build to stage sources for Cloud Deploy
resource "google_storage_bucket" "release_source_staging" {
  project                     = var.project_id
  name                        = "release-source-staging-${data.google_project.project.number}"
  uniform_bucket_level_access = true
  location                    = var.region
}

# give CloudBuild SA access to write to source staging bucket
resource "google_storage_bucket_iam_member" "release_source_staging_admin" {
  bucket  = google_storage_bucket.release_source_staging.name

  member = "serviceAccount:${google_service_account.cloud_build.email}"
  role   = "roles/storage.admin"
}
