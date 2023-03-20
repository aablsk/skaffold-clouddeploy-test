# Configuration

1. Connect repository in CloudBuild

1. Update terraform.tfvars

# How to get cluster credentials:
```
gcloud container fleet memberships get-credentials gke-membership
```


# How to test
## Run rendering test
```
skaffold test -p kustomize-simple -a artifacts.json
```

## Create deployment (to run render, apply and verify job within Cloud Deploy)
```
export RELEASE_NAME=release-006
gcloud deploy releases create $RELEASE_NAME --region us-central1 --delivery-pipeline skaffold-clouddeploy-test --build-artifacts=artifacts.json --skaffold-version=skaffold_preview --gcs-source-staging-dir=gs://delivery-artifacts-140310834357/$RELEASE_NAME/
```