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

variable "project_id" {
    type = string
    description = "Project ID where the resources will be deployed"
}

variable "region" {
    type = string
    description = "Region where regional resources will be deployed (e.g. europe-west1)"
}

variable "zones" {
    type = list(string)
    description = "Zones where GKE cluster will deploy nodes to"
}

variable "repo_name" {
    type = string
    description = "Short version of repository to use source for CI"
}

variable "repo_owner" {
    type = string
    description = "Github username of the github repo owner whose fork shall be used for CloudBuild triggers"
}

variable "repo_branch" {
    type = string
    description = "Branch to trigger pipelines from if pushed to."
}
