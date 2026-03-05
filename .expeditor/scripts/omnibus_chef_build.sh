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

# Set default AWS Region
export AWS_REGION="${AWS_REGION:-us-west-2}"

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
    %_gpg_digest_algo sha256
EOF
fi

echo "--- AIX gemfile.lock"
if [[ -n "${BUILDKITE_LABEL:-}" ]] && [[ "$BUILDKITE_LABEL" =~ aix ]]; then
  cd "${SCRIPT_DIR}/../.."
  cp -f Gemfile.aix.lock Gemfile.lock
fi

# -------------------------------------------------------------------
# GitHub auth for private repos needed during bundle install (omnibus-private)
# Token env var: OMNIBUS_SUBMODULE_CONFIG_PRIVATE
#
# IMPORTANT:
# - Do NOT echo token
# - Do NOT print git config or .bundle/config (would leak token)
# - Ensure this env var is passed into the docker container by the pipeline
# -------------------------------------------------------------------
echo "--- Configuring GitHub auth for private repos"
export GIT_TERMINAL_PROMPT=0
export GIT_ASKPASS=/bin/false

if [[ -n "${OMNIBUS_SUBMODULE_CONFIG_PRIVATE:-}" ]]; then
  echo "OMNIBUS_SUBMODULE_CONFIG_PRIVATE is set (len=${#OMNIBUS_SUBMODULE_CONFIG_PRIVATE})"

  # Ensure git operations that bundler performs can authenticate to GitHub over HTTPS
  # Repo-scoped config (safe for the mounted workspace). This writes to .git/config.
  git config --local url."https://x-access-token:${OMNIBUS_SUBMODULE_CONFIG_PRIVATE}@github.com/".insteadOf "https://github.com/" || true

  # Also apply inside the omnibus submodule repo, since bundler runs from there
  if [[ -d "${SCRIPT_DIR}/../../omnibus" ]]; then
    ( cd "${SCRIPT_DIR}/../../omnibus" && git config --local url."https://x-access-token:${OMNIBUS_SUBMODULE_CONFIG_PRIVATE}@github.com/".insteadOf "https://github.com/" ) || true
  fi
else
  echo "OMNIBUS_SUBMODULE_CONFIG_PRIVATE is NOT set; private repo fetch (e.g. omnibus-private) may fail/hang."
fi

echo "--- Running bundle install for Omnibus"
cd "${SCRIPT_DIR}/../../omnibus"
bundle config set --local without development
bundle install

# Set up build options similar to omnibus-buildkite-plugin
BUILD_OPTIONS="-l internal --populate-s3-cache"

# Add override options
BUILD_OPTIONS+=" --override"
BUILD_OPTIONS+=" s3_region:$AWS_REGION"
BUILD_OPTIONS+=" s3_access_key:$AWS_S3_ACCESS_KEY"
BUILD_OPTIONS+=" s3_secret_key:$AWS_S3_SECRET_KEY"
BUILD_OPTIONS+=" cache_suffix:$PROJECT_NAME"
BUILD_OPTIONS+=" append_timestamp:false"
BUILD_OPTIONS+=" use_git_caching:true"

echo "--- Building Chef"
echo "Build options: $BUILD_OPTIONS"
bundle exec omnibus build "$PROJECT_NAME" $BUILD_OPTIONS

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
