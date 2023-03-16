# Copyright 2022 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Service Account for Cloud Deploy
resource "google_service_account" "cloud_deploy" {
  account_id = "cloud-deploy"
}

# GCS bucket used by Cloud Deploy for delivery artifact storage
resource "google_storage_bucket" "delivery_artifacts" {
  project                     = var.project_id
  name                        = "delivery-artifacts-${data.google_project.project.number}"
  uniform_bucket_level_access = true
  location                    = var.region
}

# Give Cloud Deploy SA access to administrate delivery artifacts bucket
resource "google_storage_bucket_iam_member" "delivery_artifacts" {
  bucket  = google_storage_bucket.delivery_artifacts.name

  member = "serviceAccount:${google_service_account.cloud_deploy.email}"
  role   = "roles/storage.admin"
}

# Cloud Deploy target
resource "google_clouddeploy_target" "gke" {
  # one Cloud Deploy target per target defined in vars
  project  = var.project_id
  name     = local.application_name
  location = var.region

  anthos_cluster {
    membership = google_gke_hub_membership.gke.id
  }

  execution_configs {
    artifact_storage = "gs://${google_storage_bucket.delivery_artifacts.name}"
    service_account  = google_service_account.cloud_deploy.email
    usages = [
      "RENDER",
      "DEPLOY",
      "VERIFY"
    ]
  }
}

# create delivery pipeline for service including all targets
resource "google_clouddeploy_delivery_pipeline" "delivery-pipeline" {
  project  = var.project_id
  location = var.region
  name     = local.application_name
  serial_pipeline {
    stages {
      profiles = ["kustomize-simple"]
      target_id = google_clouddeploy_target.gke.name
      strategy {
        standard {
          verify = true
        }
      }
    }
  }
  provider = google-beta
}

