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


_encode-branch() {
  local tmp="${1//+/++}"
  echo "${tmp//\//+2F+}"
}

_git_ref_exists() {
  git rev-parse "$1" 1>/dev/null 2>&1
}

_lower() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

BASE_BRANCH_OVERRIDE=""
MAINLINE_VERSION="develop"

while [ "$#" -gt 0 ]; do
  case "$1" in
    "--version") BUNDLE_VERSION_OVERRIDE="$2";shift;;
    "--mainline") MAINLINE_VERSION="$2";shift;;
    "--controller-coordinator-branch") BASE_BRANCH_OVERRIDE="$2";shift;;
    "--"*) echo "Undefined argument \"$1\"" 1>&2;exit 3;;
  esac
  shift
done

ACTUAL_BUNDLE_VERSION_OVERRIDE="$(_lower "$BUNDLE_VERSION_OVERRIDE")"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
if [ "$ACTUAL_BUNDLE_VERSION_OVERRIDE" != "$BUNDLE_VERSION_OVERRIDE" ]; then
  echo "> BUNDLE_VERSION_OVERRIDE: $ACTUAL_BUNDLE_VERSION_OVERRIDE ($BUNDLE_VERSION_OVERRIDE)"
else
  echo "> BUNDLE_VERSION_OVERRIDE: $ACTUAL_BUNDLE_VERSION_OVERRIDE"
fi
echo "> BASE_BRANCH_OVERRIDE:    $BASE_BRANCH_OVERRIDE"
echo "> MAINLINE_VERSION:        $MAINLINE_VERSION"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
BUNDLE_VERSION_OVERRIDE="$ACTUAL_BUNDLE_VERSION_OVERRIDE"

CONTROLLER_COORDINATOR_VERSION="$(
    grep "entando_k8s_controller_coordinator:" -A 10 values.yaml \
      | grep "version:" \
      | head -n 1 \
      | sed "s/version://" \
      | xargs
)"

if [ -z "$BASE_BRANCH_OVERRIDE" ]; then
  if [[ "$CONTROLLER_COORDINATOR_VERSION" = "${MAINLINE_VERSION}."* ]]; then
    BASE_BRANCH="develop"
  else
    MAJ_MIN=$(sed -E 's/^([0-9]*\.[0-9]*)\..*$/\1/' <<<"$CONTROLLER_COORDINATOR_VERSION")
    BASE_BRANCH="release/$MAJ_MIN"
  fi

  echo "> Determined base branch \"$BASE_BRANCH\""
else
  BASE_BRANCH="${BASE_BRANCH_OVERRIDE:-develop}"
  echo "> Base branch overridden with: \"$BASE_BRANCH\""
fi

BASE_BRANCH="$(_encode-branch "$BASE_BRANCH")"

if [ -z "$CONTROLLER_COORDINATOR_VERSION" ]; then
  echo "> Unable to extract the controller coordinator version"
else
  echo "> Found version: $CONTROLLER_COORDINATOR_VERSION"
fi

if [ "${CONTROLLER_COORDINATOR_VERSION:0:1}" == 'v' ]; then
  CONTROLLER_COORDINATOR_VERSION="${CONTROLLER_COORDINATOR_VERSION:1}"
fi

HELM_MAJOR_VERSION="$(helm version | sed -E 's/.*:"v+([0-9]*).*/\1/')"

if [ -n "$BUNDLE_VERSION_OVERRIDE" ]; then
  cp values.yaml tmp/
  cat tmp/values.yaml | sed -E 's/^  version: ([0-9A-Za-z.]*).*/  version: '$BUNDLE_VERSION_OVERRIDE'/' > values.yaml
  cat "values.yaml"
fi

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

_checkout_tag_if_exists() {
  local tag="$1"
  echo "> Trying with \"$tag\""
  CONTROLLER_COORDINATOR_FOUND_TAG=""
  if _git_ref_exists "$tag"; then
    CONTROLLER_COORDINATOR_FOUND_TAG="$tag"
    git checkout "$tag" || {
      echo "Error checking out tag \"$tag\"" 1>&2
      exit 3
    }
    return 0
  else
    return 1
  fi
}

if [ "$CONTROLLER_COORDINATOR_VERSION" != "-" ]; then
  (
    ERR=false
    CLONE_DIR="tmp/entando-k8s-controller-coordinator"
    rm -rf "$CLONE_DIR"
    if git clone "https://github.com/entando-k8s/entando-k8s-controller-coordinator" "$CLONE_DIR"; then
      cd "$CLONE_DIR" && {
        _checkout_tag_if_exists "v${CONTROLLER_COORDINATOR_VERSION}" ||
        _checkout_tag_if_exists "v${CONTROLLER_COORDINATOR_VERSION}+KB-${BASE_BRANCH}" ||
        _checkout_tag_if_exists "v${CONTROLLER_COORDINATOR_VERSION}+BB-${BASE_BRANCH}"
      } || ERR=true
    fi

    if [ -z "$CONTROLLER_COORDINATOR_FOUND_TAG" ]; then
      echo "Unable to find an existing controller coordinator tag" 1>&2
      exit 3
    fi

    if [ -z "$(git tag --points-at HEAD | grep "^$CONTROLLER_COORDINATOR_FOUND_TAG$")" ]; then
      ERR=true
    fi

    if $ERR; then
      echo "~~~"
      echo "ERROR: Unable to checkout the controller coordinator branch or tag \"$CONTROLLER_COORDINATOR_FOUND_TAG\""
      exit 1
    fi

    _set_all() {
      _sed_i "s|{{$1}}|$2|g" "./charts/preview/Chart.yaml"
      _sed_i "s|{{$1}}|$2|g" "./charts/preview/values.yaml"
      _sed_i "s|{{$1}}|$2|g" "./charts/preview/requirements.yaml"
      _sed_i "s|{{$1}}|$2|g" "./charts/entando-k8s-controller-coordinator/Chart.yaml"
      _sed_i "s|{{$1}}|$2|g" "./charts/entando-k8s-controller-coordinator/values.yaml"
    }


    _set_all "ENTANDO_PROJECT_VERSION" "$CONTROLLER_COORDINATOR_VERSION"
    _set_all "ENTANDO_IMAGE_TAG" "$CONTROLLER_COORDINATOR_VERSION"
    _set_all "ENTANDO_IMAGE_REPO" "entando/entando-k8s-controller-coordinator"
    _set_all "ENTANDO_OPT_TEST_*" "null"
  ) || exit "$?"
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

  if [ $k8s_version == "k8s-before-116" ]; then
    support_openshift_311="true"
  else
    support_openshift_311="false"
  fi

  # ~~~ NAMESPACE SCOPED ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  local output_dir=./manifests/${k8s_version}/namespace-scoped-deployment
  rm $output_dir/*.yaml 2>/dev/null

  # CLUSTER RESOURCES
  writeClusterResourceToFile ${k8s_version} ${output_dir}/cluster-resources.yaml

  # NAMESPACE RESOURCES
  _helm_template entando --set operator.supportOpenshift311=${support_openshift_311},operator.clusterScope=false,bundle.olmDisabled=true ./  >> ${output_dir}/namespace-resources.yaml

  # ALL-IN-ONE
  writeClusterResourceToFile ${k8s_version} ${output_dir}/all-in-one.yaml
  _helm_template entando --set operator.supportOpenshift311=${support_openshift_311},operator.clusterScope=false,bundle.olmDisabled=true ./  >> ${output_dir}/all-in-one.yaml

  # ~~~ CLUSTER SCOPED ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  output_dir=./manifests/${k8s_version}/cluster-scoped-deployment
  rm $output_dir/*.yaml 2>/dev/null

  # ALL-IN-ONE
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
