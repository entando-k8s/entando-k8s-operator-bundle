export MY_VERSION=$(yq eval '.spec.version' manifests/k8s-116-and-later/olm-deployment/entando-k8s-operator.v6.3.x.clusterserviceversion.yaml)
echo $MY_VERSION
export PREVIOUS_VERSIONS=()
for V in ${PREVIOUS_VERSIONS[@]}; do
  BUNDLES="${BUNDLES}docker.io/ampie/entando-k8s-operator-bundle:${V},"
done
BUNDLES="${BUNDLES}docker.io/ampie/entando-k8s-operator-bundle:${MY_VERSION}"
echo $BUNDLES
docker build . -t ampie/entando-k8s-operator-bundle:${MY_VERSION} \
      && docker push ampie/entando-k8s-operator-bundle:${MY_VERSION} \
      && operator-sdk bundle validate docker.io/ampie/entando-k8s-operator-bundle:${MY_VERSION} \
      && opm index add --bundles "${BUNDLES}" --tag docker.io/ampie/entando-k8s-index:latest \
      && podman push docker.io/ampie/entando-k8s-index:latest