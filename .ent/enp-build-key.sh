#!/bin/bash

#~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

TMP="$(sha256sum "values.yaml" --zero | cut -d' ' -f1)"
TMP+="${PPL_COMMIT_ID}_${ENTANDO_PRJ_VERSION}"
echo "$TMP"

