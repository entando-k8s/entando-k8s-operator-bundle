#!/bin/bash

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_log_i "Installing prerequirements"

# PRE
export ARCH=$(case $(uname -m) in x86_64) echo -n amd64 ;; aarch64) echo -n arm64 ;; *) echo -n $(uname -m) ;; esac)
export OS=$(uname | awk '{print tolower($0)}')

# HELM
#curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# OLM
#curl -sLO "$ENTANDO_OPT_OPM_CLI_URL"
#tar xvfz "$ENTANDO_OPT_OPM_CLI_PKG"
curl -sLO "https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/latest-4.9/opm-linux-4.9.59.tar.gz"
tar xvfz opm-linux-4.9.59.tar.gz
chmod +x opm && mv opm /usr/local/bin/

opm version

# OPERATOR SDK
curl -sLO "${ENTANDO_OPT_OPERATOR_SDK_CLI_URL}"
chmod +x "$ENTANDO_OPT_OPERATOR_SDK_CLI_PKG" && sudo mv "$ENTANDO_OPT_OPERATOR_SDK_CLI_PKG" /usr/local/bin/operator-sdk

operator-sdk version
