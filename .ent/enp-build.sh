#!/bin/bash

. .ent/enp-prereq.sh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_log_i "Running build"

./generate-manifests.sh \
  --version "${ENTANDO_PRJ_VERSION}" \
  --mainline "$ENTANDO_OPT_MAINLINE_VERSION" \
  --controller-coordinator-branch release/7.1
