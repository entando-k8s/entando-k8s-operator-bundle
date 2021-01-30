export MY_VERSION=0.3.39
export PREVIOUS_VERSIONS=("0.3.36" "0.3.37" "0.3.38")
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