export MY_VERSION=$(yq eval '.spec.version' manifests/entando-k8s-operator.v0.3.x.clusterserviceversion.yaml)
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