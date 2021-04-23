#!/usr/bin/env bash
#This script determines the latest version of the entando-k8s-operator-bundle-internal container that was created
#and builds an index image that can be deployed as a CatalogSource to an Openshift 4.6+ cluster
#This script should typically be execute once a release build of the internal release of our operator
#(Dockerfile.internal) has been rebuilt as a result of a PR being merged into master.
git fetch origin --tags
readarray -t "tags" <<< "$(git tag -l)"
latest_tag=$(echo ${tags[${#tags[@]} - 1]})
export MY_VERSION=${latest_tag//v}
echo $MY_VERSION
export PREVIOUS_VERSIONS=()
for V in ${PREVIOUS_VERSIONS[@]}; do
  BUNDLES="${BUNDLES}docker.io/entando/entando-k8s-operator-bundle-internal:${V},"
done
BUNDLES="${BUNDLES}docker.io/entando/entando-k8s-operator-bundle-internal:${MY_VERSION}"
echo $BUNDLES
operator-sdk bundle validate docker.io/entando/entando-k8s-operator-bundle-internal:${MY_VERSION} \
  && opm index add --bundles "${BUNDLES}" --tag docker.io/entando/entando-k8s-index:latest \
  && podman push docker.io/entando/entando-k8s-index:latest