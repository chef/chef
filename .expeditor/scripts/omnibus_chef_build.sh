#!/bin/bash
set -ueo pipefail

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

export ARTIFACTORY_BASE_PATH="com/getchef"
export ARTIFACTORY_ENDPOINT="https://artifactory-internal.ps.chef.co/artifactory"
export ARTIFACTORY_USERNAME="buildkite"

export PROJECT_NAME="chef"
export PATH="/opt/omnibus-toolchain/bin:${PATH}"
export OMNIBUS_FIPS_MODE="true"
export OMNIBUS_PIPELINE_DEFINITION_PATH="${SCRIPT_DIR}/../release.omnibus.yml"

echo "--- Installing Chef Foundation"
curl -fsSL https://omnitruck.chef.io/chef/install.sh | bash -s -- -c "stable" -P "chef-foundation" -v "$CHEF_FOUNDATION_VERSION"

if [[ -f "/opt/omnibus-toolchain/embedded/ssl/certs/cacert.pem" ]]; then
  export SSL_CERT_FILE="/opt/omnibus-toolchain/embedded/ssl/certs/cacert.pem"
fi

if [[ "$BUILDKITE_LABEL" =~ rhel|rocky|sles|centos|amazon ]] && [[ $BUILDKITE_ORGANIZATION_SLUG != "chef-oss" ]]; then
  export OMNIBUS_RPM_SIGNING_PASSPHRASE=''

  echo "$RPM_SIGNING_KEY" | gpg --import

  cat <<-EOF > ~/.rpmmacros
    %_signature gpg
    %_gpg_name  Opscode Packages
EOF
fi

echo "--- Running bundle install for Omnibus"
cd "${SCRIPT_DIR}/../../omnibus"
bundle config set --local without development
bundle install

echo "--- Building Chef"
bundle exec omnibus build chef -l internal --override append_timestamp:false

echo "--- Uploading package to BuildKite"
extensions=( bff deb dmg msi p5p rpm solaris amd64.sh i386.sh )
for ext in "${extensions[@]}"
do
  buildkite-agent artifact upload "pkg/*.${ext}*"
done

if [[ $BUILDKITE_ORGANIZATION_SLUG != "chef-oss" ]]; then
  echo "--- Setting up Gem credentials"
  export GEM_HOST_API_KEY="Basic ${ARTIFACTORY_API_KEY}"

  echo "--- Publishing package to Artifactory"
  bundle exec ruby "${SCRIPT_DIR}/omnibus_chef_publish.rb"
fi
