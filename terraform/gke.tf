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

# Cloud Foundation Toolkit GKE module requires cluster-specific kubernetes provider
provider "kubernetes" {
  alias                  = "development"
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

# development autopilot cluster
module "gke" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/beta-autopilot-private-cluster"

  project_id              = var.project_id
  name                    = "development"
  regional                = true
  region                  = var.region
  network                 = local.network_name
  subnetwork              = local.network.subnetwork
  ip_range_pods           = local.network.ip_range_pods
  ip_range_services       = local.network.ip_range_services
  enable_private_nodes    = true
  enable_private_endpoint = true
  master_authorized_networks = [{
    cidr_block   = module.network.subnets["${var.region}/${local.network.master_auth_subnet_name}"].ip_cidr_range
    display_name = local.network.subnetwork
  }]
  master_ipv4_cidr_block          = "10.6.0.0/28"
  release_channel                 = "RAPID"
  enable_vertical_pod_autoscaling = true
  horizontal_pod_autoscaling      = true
  create_service_account          = false # currently not supported by terraform for autopilot clusters
  cluster_resource_labels         = { "mesh_id" : "proj-${data.google_project.project.number}" }
  datapath_provider               = "ADVANCED_DATAPATH"

  providers = {
    kubernetes = kubernetes.development
  }

  depends_on = [
    module.enabled_google_apis,
    module.network
  ]
}

# development GKE workload GSA
resource "google_service_account" "gke_workload" {
  account_id = "gke-workload-development"
}

# binding development GKE workload GSA to KSA
resource "google_service_account_iam_member" "gke_workload_identity" {
  service_account_id = google_service_account.gke_workload.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[skaffold-clouddeploy-test/default]"
  depends_on = [
    module.gke
  ]
}

# create fleet membership for GKE cluster
resource "google_gke_hub_membership" "gke" {
  provider      = google-beta
  project       = var.project_id
  membership_id = "gke-membership"
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${module.gke.cluster_id}"
    }
  }
  authority {
    issuer = "https://container.googleapis.com/v1/${module.gke.cluster_id}"
  }
}
