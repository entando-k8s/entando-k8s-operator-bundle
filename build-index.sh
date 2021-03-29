#git fetch origin --tags
readarray -t "tags" <<< "$(git tag -l)"
latest_tag=$(echo ${tags[${#tags[@]} - 1]})
export MY_VERSION=${latest_tag//v}
echo $MY_VERSION
export PREVIOUS_VERSIONS=()
for V in ${PREVIOUS_VERSIONS[@]}; do
  BUNDLES="${BUNDLES}docker.io/entando/entando-k8s-operator-bundle:${V},"
done
BUNDLES="${BUNDLES}docker.io/entando/entando-k8s-operator-bundle:${MY_VERSION}"
echo $BUNDLES
operator-sdk bundle validate docker.io/entando/entando-k8s-operator-bundle:${MY_VERSION} \
  && opm index add --bundles "${BUNDLES}" --tag docker.io/ampie/entando-k8s-index:latest \
  && podman push docker.io/ampie/entando-k8s-index:latest