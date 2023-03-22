# What's the purpose of this?
This repository contains an integration test to validate new skaffold versions for use in Cloud Deploy using a more complex configuration.

## How does it work?
Cloud Deploy uses `skaffold render` to render kubernetes manifests supporting a number of renderers, `skaffold apply` to apply the rendered manifests to a cluster and `skaffold verify` to run verification tests against the deployed workloads.
This repository aims to test these skaffold commands against regressions and unexpected behavior.

## skaffold configuration
There is a top-level `skaffold.yaml` which `requires` the use-case/renderer-specific skaffold modules found in the `modules` directory.
Every `module` requires the `namespace` skaffold configuration found in the `shared/namespace` directory *(Motivation for this is to introduce a shared dependency that could be subject to a hard-to-catch regression.)*

### modules
Each `module` encapsulates the same workload consisting of a `type: LoadBalancer` kubernetes service pointing towards a hello world application using the `gcr.io/google-samples/hello-app:2.0@sha256:c4b0d869bd22cb3d1207848b385c389f7a4ab7a481184476ee7b98e7876ee594` image. The modules add small customizations like updating the service's and deployment's `name` properties to the `module`'s name using the renderers provided mechanics.

The modules only include `manifests`, `test` and `verify` configuration to keep the example as minimal as possible. A `artifacts.json` file on the repository root is provided to be used with `skaffold render` `skaffold test` and `skaffold verify`.

## Validate skaffold render
`skaffold render` supports many renderers. For each renderer a skaffold configuration and a `golden_render.yaml` file with the expected output of `skaffold render -a artifacts.json` is provided. The actual execution of rendering the manifests and comparing them with the `golden_render.yaml` is implemented using `skaffold test -a artifacts.json`. *(skaffold-ception)*

## Execute locally
Run `skaffold test -a artifacts.json` from the repository root to run rendering tests for all modules imported in the repository root `skaffold.yaml`.

Run `skaffold test -a artifacts.json -m $MODULE_NAME` from the repository root to run rendering tests for a specific module imported in the repository root `skaffold.yaml`.

## Execute remotely in Cloud Build
The repositories infrastructure contains a Cloud Build pipeline to trigger a pipeline that runs `skaffold test -a artifacts.json` within a `gcr.io/k8s-skaffold/skaffold:$_SKAFFOLD_VERSION` container followed by executing `skaffold test -a artifacts.json` in a `us-central1-docker.pkg.dev/cd-image-prod/cd-image/cd@sha256:$_CD_IMAGE_HASH` container. *`$_SKAFFOLD_VERSION` and `$_CD_IMAGE_HASH` are Cloud Build substitutions and can be injected when triggering the pipeline manually.* 

After successfully passing these tests, the pipeline creates a Cloud Deploy release.

The pipeline is triggered automatically on every push to the repository.

### Available configurations

#### `helm-local`
Render manifests using `helm` using a locally stored helm chart at `modules/helm-local/helm/Chart.yaml`

#### `helm-remote`
Render manifests using `helm` using the packaged version of the `helm-local` helm chart hosted on Github with a local `values.yaml` file.

#### `kpt` (temporarily disabled in skaffold.yaml)
Render and validate manifests using `kpt` based on the `Kptfile` and manifests in `modules/kpt/k8s/base`.

#### `kustomize`
Render and validate manifests using `kustomize` based on the `kustomization.yaml` and manifests in `modules/kustomize/k8s/base`.

#### `manifests-transform` (temporarily disabled in skaffold.yaml)
Render and validate manifests using skaffold's built-in `kpt` transform and validate capabilities based on the `skaffold.yaml` in `modules/manifests-transform` and manifests in `modules/manifests-transform/k8s/base`.

#### `raw`
Compile manifests in `modules/raw/k8s/base` into the rendering output without modifications.

## Validate `skaffold apply` & `skaffold verify`
Cloud Deploy uses `skaffold apply` with the rendered manifests to deploy manifests to GKE clusters. The IaC (`terraform directory`) in this repository contains declarative configuration to instantiate a GKE cluster and a Cloud Deploy delivery pipeline.

After passing the `skaffold render` tests in the Cloud Build pipeline, a release for the Cloud Deploy delivery pipeline is created. Cloud Deploy renders the manifests, deploys them to the cluster and runs verification tests for each module, which consist of a simple `curl` that expects a `200` status code.


# How to set it up?
## Prerequisites

Setting up the sample requires that you have a [Google Cloud Platform (GCP) project](https://cloud.google.com/resource-manager/docs/creating-managing-projects#console), connected to your billing account.

## MANUAL - Github repository setup
1. Fork the Github Repository with your user.
1. Create a GCP project and note the `PROJECT_ID`.
1. Set up repository connection in Cloud Build
    1. Open Cloud Build in Cloud Console (enable API if needed).
    1. Navigate to 'Triggers' and set Region to the region that you want to use for the deployment.
    1. Click `Manage Repositories`
    1. `CONNECT REPOSITORY` and follow the UI. Do **NOT** create a trigger.
1. [OPTIONAL] If your GCP organization has the compute.vmExternalIpAccess constraint in place reset it on project level `gcloud org-policies reset constraints/compute.vmExternalIpAccess --project=$PROJECT_ID` 


## Infrastructure
1. Replace all occurrences of `aablsk` with your repo owner (e.g. `GoogleContainerTools` for `https://github.com/GoogleContainerTools/skaffold`). Terminal command: `find . -type f -exec sed -i 's/aablsk/'"$REPO_OWNER"'/g' {} +`
1. Adapt the configuration in `terraform/terraform.tfvars`. Ensure the `region` is equal to the region you used to set up your repository in Cloud Build. Ensure the `project_id` is the project id of the project that you want to deploy to. Update the `repo_*` variables with the values for your fork.
1. In a terminal navigate to the `terraform` folder
1. Initialize terraform: `terraform init`
1. Apply the terraform configuration: `terraform apply` - Check the output and confirm with `yes`
