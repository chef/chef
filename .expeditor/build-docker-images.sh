#! /bin/bash
set -eou pipefail

#set expeditor_version equal to the version file
export EXPEDITOR_VERSION=$(cat VERSION)
export AWS_REGION='us-west-2'
export HAB_AUTH_TOKEN=$(aws ssm get-parameter --name 'habitat-prod-auth-token' --with-decryption --query Parameter.Value --output text --region ${AWS_REGION})

arch=$1

if [[ $arch == "arm64" ]]; then
  dockerfile_arch="aarch64"
else
  dockerfile_arch="x86_64"
fi

channel="${EXPEDITOR_CHANNEL:-unstable}"
version="${EXPEDITOR_VERSION:?You must manually set the EXPEDITOR_VERSION environment variable to an existing semantic version.}"

echo "--- Building chef/chef-hab:${version} docker image for ${arch}"
docker build \
  --build-arg "CHANNEL=${channel}" \
  --build-arg "VERSION=${version}" \
  --build-arg "ARCH=${dockerfile_arch}" \
  --build-arg "HAB_AUTH_TOKEN=${HAB_AUTH_TOKEN}" \
  -t "chef/chef-hab:${version}-${arch}" .

echo "--- Pushing chef/chef-hab:${version} docker image for ${arch} to dockerhub"
docker push "chef/chef-hab:${version}-${arch}"
