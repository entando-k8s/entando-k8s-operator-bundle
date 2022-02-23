#!/usr/bin/env bash
#!/usr/bin/env bash
export MY_VERSION=$(yq eval '.spec.version' manifests/k8s-116-and-later/community-deployment/entando-k8s-operator.v6.3.x.clusterserviceversion.yaml)

echo "> Found version $MY_VERSION"
[ -z "$REGISTRY_ORG" ] && REGISTRY_ORG="entandobuilduser"
[ -z "$OPM_CONTAINER_TOOL" ] && OPM_CONTAINER_TOOL="podman"

export PREVIOUS_VERSIONS=()
for V in ${PREVIOUS_VERSIONS[@]}; do
  BUNDLES="${BUNDLES}docker.io/${REGISTRY_ORG}/entando-k8s-operator-bundle:${V},"
done
BUNDLES="${BUNDLES}docker.io/${REGISTRY_ORG}/entando-k8s-operator-bundle:${MY_VERSION}"
echo $BUNDLES


docker build . -f "Dockerfile.community" -t "$REGISTRY_ORG/entando-k8s-operator-bundle:${MY_VERSION}"
docker push "$REGISTRY_ORG/entando-k8s-operator-bundle:${MY_VERSION}"

[ "$?" != 0 ] && { echo "### Error building the operator bundle image" 1>&2; exit 1; }

operator-sdk bundle validate "docker.io/${REGISTRY_ORG}/entando-k8s-operator-bundle:${MY_VERSION}"

echo opm index add \
  --bundles "${BUNDLES}" \
  --tag "docker.io/${REGISTRY_ORG}/entando-k8s-index:${MY_VERSION}" \
  --container-tool "$OPM_CONTAINER_TOOL"

[ "$?" != 0 ] && { echo "### Error building the operator bundle index" 1>&2; exit 1; }

"$OPM_CONTAINER_TOOL" push "docker.io/${REGISTRY_ORG}/entando-k8s-index:${MY_VERSION}"

[ "$?" != 0 ] && { echo "### Error pushing the operator index" 1>&2; exit 1; }

echo "> done"
