# entando-k8s-operator-bundle

This project defines the Operator Lifecycle Manager compliant bundle image that is used to publish a single
version of the Entando Operator.

# Installing this operator
1. Create an Operator CatalogSource in your Openshift environment by deploying the following yaml:

```yaml
apiVersion: operators.coreos.com/v1alpha1
kind: CatalogSource
metadata:
  name: entando-catalog
  namespace: openshift-marketplace
spec:
  displayName: Entando Catalog
  image: docker.io/entandobuilduser/entando-k8s-index:latest
  sourceType: grpc
  updateStrategy:
    registryPoll:
      interval: 5m
```

2. Confirm that a Pod starting with the phrase 'entando-catalog' is running in the `openshift-marketplace` Namespace:
```
watch oc get pods -n openshift-marketplace
```

3. When the new catalog Pod is ready, go to your Openshift web console's Operator Hub and search for the keyword 'Entando'. 
The latest available version should be 7.1 Click on the 'Install' button. Use the default 'openshift-operators' namespace
   
4. Confirm that the Entando Operator pod is up and running:
```
watch oc get pods -n openshift-operators
```

5. Once the Entando Operator pod is up and running, navigate to the Operator in your Openshift web console, create
   an EntandoKeycloakServer custom resource using the defaults. 

# Building and publishing a release

The bundle and index images are built and pushed from a developer machine, not by CI. `catalog.yaml` has to
record the index image digest *before* the release is tagged, and the index image is not reproducible, so a
rebuild in CI would publish a different digest than the one shipped to customers. CI only verifies the
result — see `.github/workflows/manifests-check.yml` (on PRs) and `.github/workflows/publication.yml` (on tags).

Requires `helm` v3, `git`, `docker`, `opm`, `operator-sdk` and `yq`. Note that `local-dev-publish.sh` uses the
jq-flavoured [python-yq](https://github.com/kislyuk/yq) (`yq -r '.spec.version' file.yaml`), not mikefarah's yq.

## 1. Set the versions

Edit `values.yaml`: `bundle.version` for the operator bundle version, plus the `version` and `sha256` pair of
every image under `operator.relatedImages` that changed. `values.yaml` is the single source of truth — do not
use `generate-manifests.sh --version` to set it, since that rewrites `bundle.version` as a side effect.

## 2. Generate the manifests

```bash
./generate-manifests.sh --mainline "7.5"
```

Clones `entando-k8s-controller-coordinator` at the tag matching
`operator.relatedImages.entando_k8s_controller_coordinator.version` and re-renders everything under
`manifests/`. This is exactly what the `MANIFESTS-CHECK` workflow runs on every PR, so the result must be
committed.

`--mainline` declares which minor line currently lives on `develop`. It only affects the fallback tag names
(`v<version>+KB-<branch>`, `v<version>+BB-<branch>`) tried when the coordinator has no plain `v<version>` tag,
so it is usually invisible. Keep it aligned with `MAINLINE_VERSION` in the workflows.

## 3. Build and push the bundle and index images

```bash
docker login registry.hub.docker.com
OPM_CONTAINER_TOOL=docker ./local-dev-publish.sh
```

Reads the version from the CSV generated in step 2, pushes
`entandobuilduser/entando-k8s-operator-bundle:<version>` and `entandobuilduser/entando-k8s-index:<version>`,
and writes `./tmp/catalog-source.yaml` with the index image pinned by digest.

Override the target when testing:

```bash
REGISTRY=registry.hub.docker.com REGISTRY_ORG=myuser OPM_CONTAINER_TOOL=docker ./local-dev-publish.sh
```

## 4. Record the digest

```bash
cp tmp/catalog-source.yaml catalog.yaml
sed -nE 's/^[[:space:]]*image:[[:space:]]*(.*)$/\1/p' catalog.yaml
```

Then set the same values in the [`entando-releases`](https://github.com/entando/entando-releases) `manifest`
file, which is what actually ships the catalog to customers:

- `OPERATOR_BUNDLE_VERSION="v<version>"` — the tag created in step 5
- `OKD_CATALOG_IMAGE="<the digest-pinned image printed above>"`

## 5. Commit, merge, tag

```bash
git add values.yaml manifests/ catalog.yaml
git commit -m "<ticket> release <version>"
```

Open the PR — `MANIFESTS-CHECK` verifies that `manifests/` matches `values.yaml`. After merge:

```bash
git tag v<version> && git push origin v<version>
```

`entando-releases` clones this repository **at that tag** and copies `manifests/k8s-116-and-later/` and
`plain-templates/` straight out of the working tree, so the tagged commit must contain the manifests
generated in step 2. The `PUB` workflow re-verifies this on the tag and checks that the digest recorded in
`catalog.yaml` is pullable.

## Deploying the catalog on OpenShift

```bash
oc apply -f catalog.yaml
watch oc get pods -n openshift-marketplace
```

