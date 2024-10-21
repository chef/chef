#!/bin/bash
set -eu -o pipefail

s3_bucket_uri="s3://<bucket_uri>/<bucket_path>"

pkg_identifiers=(
    $EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64LINUX
    $EXPEDITOR_PKG_IDENTS_CHEFINFRACLIENTX86_64WINDOWS
)

for identifier in "${pkg_identifiers[@]}"; do
    echo "--- habitat: extracting tar for $identifier ---"
    hab pkg export tar $identifier --channel LTS-2024

    tar_filename=$(sed 's/\//-/g' <<< $identifier).tar.gz
    echo "--- aws: uploading $tar_filename to s3 bucket ---"
    aws s3 cp $tar_filename $s3_bucket_uri/$tar_filename --content-type "application/gzip" --profile "<profile to use>"

    rm $tar_filename
done
