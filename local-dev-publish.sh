#!/usr/bin/env bash
export MY_VERSION=$(yq eval '.spec.version' manifests/k8s-116-and-later/community-deployment/entando-k8s-operator.v6.3.x.clusterserviceversion.yaml)

REGISTRY="registry.hub.docker.com"

echo "> Found version $MY_VERSION"
[ -z "$REGISTRY_ORG" ] && REGISTRY_ORG="entandobuilduser"
[ -z "$OPM_CONTAINER_TOOL" ] && OPM_CONTAINER_TOOL="podman"

export PREVIOUS_VERSIONS=()
for V in ${PREVIOUS_VERSIONS[@]}; do
  BUNDLES="${BUNDLES}${REGISTRY}/${REGISTRY_ORG}/entando-k8s-operator-bundle:${V},"
done
BUNDLES="${BUNDLES}${REGISTRY}/${REGISTRY_ORG}/entando-k8s-operator-bundle:${MY_VERSION}"
echo "$BUNDLES"


docker build . -f "Dockerfile.community" -t "${REGISTRY}/$REGISTRY_ORG/entando-k8s-operator-bundle:${MY_VERSION}"
docker push "${REGISTRY}/$REGISTRY_ORG/entando-k8s-operator-bundle:${MY_VERSION}"

[ "$?" != 0 ] && { echo "### Error building the operator bundle image" 1>&2; exit 1; }

operator-sdk bundle validate "${REGISTRY}/${REGISTRY_ORG}/entando-k8s-operator-bundle:${MY_VERSION}"

INDEX_URL="registry.hub.docker.com/${REGISTRY_ORG}/entando-k8s-index:${MY_VERSION}"

opm index add \
  --bundles "${BUNDLES}" \
  --tag "$INDEX_URL" \
  --container-tool "$OPM_CONTAINER_TOOL"

[ "$?" != 0 ] && { echo "### Error building the operator bundle index" 1>&2; exit 1; }

RESFILE="$(mktemp)"
trap 'rm -f "$RESFILE"' EXIT

"$OPM_CONTAINER_TOOL" push "$INDEX_URL" | while read -r line; do
  if [[ "$line" == *"digest: sha256:"* ]]; then
    echo "$line" | cut -d ' ' -f 3 > "$RESFILE"
  fi
  echo "$line"
done

[ "$?" != 0 ] && { echo "### Error pushing the operator index" 1>&2; exit 1; }

# CATALOG FILE

mkdir -p tmp

echo "> Generating catalog source under ./tmp/catalog-source.yaml"

MY_STABLE_VERSION="$(echo "$MY_VERSION" | sed -E 's/([^.]*\.[^.])*\.[^-]*/\1/')"
SHA="$(cat "$RESFILE")"
INDEX_URL="${INDEX_URL/:*/@$SHA}"
NAME="$(echo "entando-catalog-${MY_STABLE_VERSION}" | sed 's/\./-/g')"

cat ./samples/catalog-source.yaml \
  | sed "s/{{NAME}}/${NAME}/" \
  | sed "s/{{DISPLAY-NAME}}/Entando Catalog ${MY_STABLE_VERSION}/" \
  | sed "s|{{IMAGE}}|${INDEX_URL}|" \
  > ./tmp/catalog-source.yaml

echo "> done"
