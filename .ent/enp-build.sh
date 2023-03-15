#!/bin/bash

. .ent/enp-prereq.sh

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
_log_i "Running build"

./generate-manifests.sh \
  --version "${ENTANDO_PRJ_VERSION}" \
  --mainline "${ENTANDO_PRJ_MAINLINE_VERSION}"
