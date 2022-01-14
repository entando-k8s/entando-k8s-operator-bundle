#!/usr/bin/env bash
#This scripts take the currently used version of the entando-k8s-controller-coordinator and generates the
# four typical deployment profiles for the operator:
# 1. K8S 1.16 and later
# 1.1. Namespace scoped deployment
# 1.2. Cluster scoped deployment
# 2. K8S before 1.16 (Openshift 3.11)
# 2.1. Namespace scoped deployment
# 2.2. Cluster scoped deployment
#This script should ideally be executed when releasing the Entando Operator so that we can ensure that
#all the different deployments and quickstarts using the Operator use exactly the same combination of image versions

mkdir -p tmp

echo "> Extracting the contoller coordinator from ./values.yaml"

CONTROLLER_COORDINATOR_VERSION="$(
    grep "entando_k8s_controller_coordinator:" -A 10 values.yaml \
      | grep "version:" \
      | head -n 1 \
      | sed "s/version://" \
      | xargs
)"

if [ -z "$CONTROLLER_COORDINATOR_VERSION" ]; then
  echo "> Unable to extract the controller coordinator version"
else
  echo "> Found version: $CONTROLLER_COORDINATOR_VERSION"
fi


if [ "${CONTROLLER_COORDINATOR_VERSION:0:1}" == 'v' ]; then
  CONTROLLER_COORDINATOR_VERSION="${CONTROLLER_COORDINATOR_VERSION:1}"
fi

HELM_MAJOR_VERSION="$(helm version | sed -E 's/.*:"v+([0-9]*).*/\1/')"

case "$HELM_MAJOR_VERSION" in
  2) 
    _helm_template() {
      helm template --name "$@" || {
        echo "<!> Error detected during helm template <!>"
        exit 9
      }
    };;
  3)
    _helm_template() {
      helm template "$@" || {
        echo "<!> Error detected during during helm template <!>"
        exit 9
      }
    };;
  *)
    echo "Unrecognized helm version" 1>&2
    exit 1;;
esac

if [[ $OSTYPE == 'darwin'* ]]; then
  _sed_i() { sed -i '' "$@"; }
else
  _sed_i() { sed -i "$@"; }
fi

_sed_i "s/version: .*/version: $CONTROLLER_COORDINATOR_VERSION/" requirements.yaml

echo "> Cloning the contoller coordinator"

if [ "$CONTROLLER_COORDINATOR_VERSION" != "-" ]; then
  (
    CLONE_DIR="tmp/entando-k8s-controller-coordinator"
    rm -rf "$CLONE_DIR"
    git clone "https://github.com/entando-k8s/entando-k8s-controller-coordinator" "$CLONE_DIR" \
    && cd "$CLONE_DIR" \
    && git checkout "v$CONTROLLER_COORDINATOR_VERSION" || {
      echo "Unable to checkout the controller coordinator branch or tag \"v$CONTROLLER_COORDINATOR_VERSION\""
      exit 1
    }
    
    _set_all() {
      _sed_i "s|{{$1}}|$2|g" "./charts/preview/Chart.yaml"
      _sed_i "s|{{$1}}|$2|g" "./charts/preview/values.yaml"
      _sed_i "s|{{$1}}|$2|g" "./charts/preview/requirements.yaml"
      _sed_i "s|{{$1}}|$2|g" "./charts/entando-k8s-controller-coordinator/Chart.yaml"
      _sed_i "s|{{$1}}|$2|g" "./charts/entando-k8s-controller-coordinator/values.yaml"
    }
    
    _set_all "ENTANDO_PROJECT_VERSION" "$CONTROLLER_COORDINATOR_VERSION"
    _set_all "ENTANDO_IMAGE_TAG" "v$CONTROLLER_COORDINATOR_VERSION"
    _set_all "ENTANDO_IMAGE_REPO" "entando/entando-k8s-controller-coordinator"
    _set_all "ENTANDO_OPT_TEST_*" "null"
  )
fi

echo "> Updating the help dependencies"

helm dep update || {
  echo "<!> Error detected during helm dep update <!>"
  exit 9
}

function writeClusterResourceToFile {
  for f in ./manifests/$1/cluster-resources/*.yaml ; do
    cat $f >> $2
    echo -e "\n---" >> $2
  done
}
function writeAllResourcesForVersion {
  local k8s_version=$1
  local output_dir=./manifests/${k8s_version}/namespace-scoped-deployment
  rm $output_dir/*.yaml 2>/dev/null
  if [ $k8s_version == "k8s-before-116" ]; then
    support_openshift_311="true"
  else
    support_openshift_311="false"
  fi
  writeClusterResourceToFile ${k8s_version} ${output_dir}/cluster-resources.yaml
  _helm_template entando --set operator.supportOpenshift311=${support_openshift_311},operator.clusterScope=false,bundle.olmDisabled=true ./  >> ${output_dir}/namespace-resources.yaml
  writeClusterResourceToFile ${k8s_version} ${output_dir}/all-in-one.yaml
  _helm_template entando --set operator.supportOpenshift311=${support_openshift_311},operator.clusterScope=false,bundle.olmDisabled=true ./  >> ${output_dir}/all-in-one.yaml
  output_dir=./manifests/${k8s_version}/cluster-scoped-deployment
  rm $output_dir/*.yaml 2>/dev/null
  writeClusterResourceToFile ${k8s_version} ${output_dir}/all-in-one.yaml
  _helm_template entando --set operator.supportOpenshift311=${support_openshift_311},operator.clusterScope=true,bundle.olmDisabled=true ./  >> ${output_dir}/all-in-one.yaml
}

writeAllResourcesForVersion k8s-116-and-later
writeAllResourcesForVersion k8s-before-116
rm -rf out 2>/dev/null
mkdir out
pwd

_helm_template entando --set bundle.containerRegistry=registry.hub.docker.com,bundle.communityOnly=true,bundle.olmDisabled=false ./ --output-dir=out
mv -f ./out/entando-k8s-operator-bundle/templates/*.yaml ./manifests/k8s-116-and-later/community-deployment/
_helm_template entando --set bundle.containerRegistry=registry.hub.docker.com,bundle.communityOnly=false,bundle.olmDisabled=false ./ --output-dir=out
mv -f ./out/entando-k8s-operator-bundle/templates/*.yaml ./manifests/k8s-116-and-later/rh-cert-deployment/
