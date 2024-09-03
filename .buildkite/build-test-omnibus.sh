set -e pipefail

if [[ -z "${BUILDKITE_BUILD_CREATOR_TEAMS:-}" ]]
then
  echo "- block: Build & Test Omnibus Packages"
  echo "  prompt: Continue to run omnibus package build and tests for applicable platforms?"
else
  echo "- wait: ~"
fi

FILTER="${OMNIBUS_FILTER:=*}"

# array of all container platforms in the format test-platform:build-platform
container_platforms=("amazon-2:centos-7" "amazon-2-arm:amazon-2-arm" "rhel-9:rhel-9" "rhel-9-arm:rhel-9-arm" "debian-9:debian-9" "debian-10:debian-9" "debian-11:debian-9" "ubuntu-2004:ubuntu-2004" "ubuntu-2204:ubuntu-2204" "ubuntu-2404:ubuntu-2404" "ubuntu-1804-arm:ubuntu-1804-arm" "ubuntu-2004-arm:ubuntu-2004-arm" "ubuntu-2204-arm:ubuntu-2204-arm" "windows-2019:windows-2019" "rocky-8:rocky-8" "rocky-9:rocky-9" "amazon-2023:amazon-2023" "amazon-2023-arm:amazon-2023-arm")

# add rest of windows platforms to tests, if not on chef-oss org
if [[ $BUILDKITE_ORGANIZATION_SLUG != "chef-oss" ]]
then
  container_platforms=( "${container_platforms[@]}" "windows-2012:windows-2019" "windows-2012r2:windows-2019" "windows-2016:windows-2019" "windows-2022:windows-2019" "windows-10:windows-2019" "windows-11:windows-2019" )
fi

# array of all esoteric platforms in the format test-platform:build-platform. We reduced this list for Chef-19
esoteric_platforms=("mac_os_x-11-x86_64:mac_os_x-11-x86_64" "mac_os_x-12-x86_64:mac_os_x-11-x86_64" "mac_os_x-11-arm64:mac_os_x-11-arm64" "mac_os_x-12-arm64:mac_os_x-11-arm64")

omnibus_build_platforms=()
omnibus_test_platforms=()

# build build array and test array based on filter
for platform in ${container_platforms[@]}; do
    case ${platform%:*} in
        $FILTER)
            omnibus_build_platforms[${#omnibus_build_platforms[@]}]=${platform#*:}
            omnibus_test_platforms[${#omnibus_test_platforms[@]}]=$platform
            ;;
    esac
done

# remove duplicates from build array
if [[ ! -z "${omnibus_build_platforms:-}" ]]
then
  omnibus_build_platforms=($(printf "%s\n" "${omnibus_build_platforms[@]}" | sort -u | tr '\n' ' '))
fi

## add esoteric platforms in chef/chef-canary
if [[ $BUILDKITE_ORGANIZATION_SLUG != "chef-oss" ]]
then
  esoteric_build_platforms=()
  esoteric_test_platforms=()

  # build build array and test array based on filter
  for platform in ${esoteric_platforms[@]}; do
    case ${platform%:*} in
        $FILTER)
            esoteric_build_platforms[${#esoteric_build_platforms[@]}]=${platform#*:}
            esoteric_test_platforms[${#esoteric_test_platforms[@]}]=$platform
            ;;
    esac
  done

  # remove duplicates from build array
  # using shell parameter expansion this checks to make sure the esoteric_build_platforms array isn't empty if OMNIBUS_FILTER is only container platforms
  # prevents esoteric_build_platforms unbound variable error
  if [[ ! -z "${esoteric_build_platforms:-}" ]]
  then
    esoteric_build_platforms=($(printf "%s\n" "${esoteric_build_platforms[@]}" | sort -u | tr '\n' ' '))
  fi
fi

# using shell parameter expansion this checks to make sure the omnibus_build_platforms array isn't empty if OMNIBUS_FILTER is only esoteric platforms
# prevents omnibus_build_platforms unbound variable error
container_platforms=("centos-7:centos-7" "centos-7-arm:centos-7-arm")

if [[ ! -z "${omnibus_build_platforms:-}" ]]
then
  for platform in ${omnibus_build_platforms[@]}; do
    if [[ $platform != *"windows"* ]]; then
      if [[ $platform == *"arm"* ]]; then
        echo "- label: \":hammer_and_wrench::docker::muscle: $platform\""
      else
        echo "- label: \":hammer_and_wrench::docker: $platform\""
      fi
      echo "  retry:"
      echo "    automatic:"
      echo "      limit: 1"
      echo "  key: build-$platform"
      echo "  agents:"
      if [[ $platform == *"arm"* ]]; then
        echo "    queue: docker-linux-arm64"
      else
        echo "    queue: default-privileged"
      fi
      echo "  plugins:"
      echo "  - docker#v3.5.0:"
      echo "      image: chefes/omnibus-toolchain-$platform:$OMNIBUS_TOOLCHAIN_VERSION" | sed 's/-arm//'
      echo "      privileged: true"
      echo "      propagate-environment: true"
      echo "      environment:"
      echo "        - ARTIFACTORY_PASSWORD"
      echo "        - ARTIFACTORY_API_KEY"
      echo "        - RPM_SIGNING_KEY"
      echo "        - CHEF_FOUNDATION_VERSION"
      echo "  commands:"
      echo "    - ./.expeditor/scripts/omnibus_chef_build.sh"
      echo "  timeout_in_minutes: 60"
    else
      echo "- label: \":hammer_and_wrench::windows: $platform\""
      echo "  retry:"
      echo "    automatic:"
      echo "      limit: 1"
      echo "  key: build-$platform"
      echo "  agents:"
      echo "    queue: default-$platform-privileged"
      echo "  plugins:"
      echo "  - docker#v3.5.0:"
      echo "      image: chefes/omnibus-toolchain-$platform:$OMNIBUS_TOOLCHAIN_VERSION"
      echo "      shell:"
      echo "      - powershell"
      echo "      - \"-Command\""
      echo "      propagate-environment: true"
      echo "      environment:"
      echo "        - CHEF_FOUNDATION_VERSION"
      echo "        - BUILDKITE_AGENT_ACCESS_TOKEN"
      echo "        - ARTIFACTORY_PASSWORD"
      echo "        - ARTIFACTORY_API_KEY"
      echo "        - AWS_ACCESS_KEY_ID"
      echo "        - AWS_SECRET_ACCESS_KEY"
      echo "        - AWS_SESSION_TOKEN"
      echo "      volumes:"
      echo '        - "c:\\buildkite-agent:c:\\buildkite-agent"'
      echo "  commands:"
      echo "    - ./.expeditor/scripts/omnibus_chef_build.ps1"
      echo "  timeout_in_minutes: 120"
    fi
  done
fi

if [[ $BUILDKITE_ORGANIZATION_SLUG != "chef-oss" ]] && [[ ! -z "${esoteric_build_platforms:-}" ]]
then

  for platform in ${esoteric_build_platforms[@]}; do
    # replace . with _ in build key
    build_key=$(echo $platform | tr . _)
    echo "- env:"
    if [ $platform == "el-7-ppc64" ] || [ $platform == "el-7-ppc64le" ]
    then
      echo "    OMNIBUS_FIPS_MODE: true"
    else
      echo "    OMNIBUS_FIPS_MODE: false"
    fi
    echo "    IGNORE_CACHE: true"
    echo "  key: build-$build_key"
    echo "  label: \":hammer_and_wrench: $platform\""
    echo "  retry:"
    echo "    automatic:"
    echo "      limit: 1"
    echo "  timeout_in_minutes: 120"
    echo "  agents:"
    echo "    queue: omnibus-$platform"
    if [[ $platform == mac_os_x* ]]
    then
      echo "    omnibus: builder"
      echo "    omnibus-toolchain: \"*\""
    fi
    echo "  plugins:"
    echo "  - chef/omnibus#v0.2.89:"
    echo "      build: chef"
    echo "      chef-foundation-version: $CHEF_FOUNDATION_VERSION"
    echo "      config: omnibus/omnibus.rb"
    echo "      install-dir: \"/opt/chef\""
    if [ $build_key == "mac_os_x-11-x86_64" ]
    then
      echo "      remote-host: buildkite-omnibus-$platform"
    fi
    echo "      omnibus-pipeline-definition-path: \".expeditor/release.omnibus.yml\""
    # if [ $build_key == "mac_os_x-11-arm64" ]
    # then
    #   echo "  concurrency: 2"
    #   echo "  concurrency_group: omnibus-$build_key/build/chef"
    # fi
  done

  if  [[ " ${esoteric_build_platforms[*]} " =~ "mac_os_x" ]]
  then
    echo "- key: notarize-macos"
    echo "  label: \":lock_with_ink_pen: Notarize macOS Packages\""
    echo "  agents:"
    echo "    queue: omnibus-mac_os_x-12-x86_64"
    echo "  plugins:"
    echo "  - chef/omnibus#v0.2.86:"
    echo "      config: omnibus/omnibus.rb"
    echo "      remote-host: buildkite-omnibus-mac_os_x-12-x86_64"
    echo "      notarize-macos-package: chef"
    echo "      omnibus-pipeline-definition-path: \".expeditor/release.omnibus.yml\""
    echo "  depends_on:"
    for platform in ${esoteric_build_platforms[@]}; do
      if [[ $platform =~ mac_os_x ]]
      then
        echo "  - build-$(echo $platform | tr . _)"
      fi
    done
  fi
fi

if [[ $BUILDKITE_PIPELINE_SLUG == "chef-chef-main-validate-release" ]]
then
  echo "- wait: ~"
  echo "- key: create-build-record"
  echo "  label: \":artifactory: Create Build Record\""
  echo "  plugins:"
  echo "  - chef/omnibus#v0.2.89:"
  echo "      create-build-record: chef"
fi

echo "- wait: ~"

# using shell parameter expansion this checks to make sure the omnibus_test_platforms array isn't empty if OMNIBUS_FILTER is only esoteric platforms
# prevents omnibus_test_platforms unbound variable error
if [[ ! -z "${omnibus_test_platforms:-}" ]]
then
  for platform in ${omnibus_test_platforms[@]}; do
    if [[ $platform != *"windows"* ]]; then
      echo "- env:"
      echo "    OMNIBUS_BUILDER_KEY: build-${platform#*:}"
      if [[ $platform == *"arm"* ]]; then
        echo "  label: \":mag::docker::muscle: ${platform%:*}\""
      else
        echo "  label: \":mag::docker: ${platform%:*}\""
      fi
      echo "  key: test-${platform%:*}"
      echo "  retry:"
      echo "    automatic:"
      echo "      limit: 1"
      echo "  agents:"
      if [[ $platform == *"arm"* ]]; then
        echo "    queue: docker-linux-arm64"
      else
        echo "    queue: default-privileged"
      fi
      echo "  plugins:"
      echo "  - docker#v3.5.0:"
      echo "      image: chefes/omnibus-toolchain-${platform%:*}:$OMNIBUS_TOOLCHAIN_VERSION" | sed 's/-arm//'
      echo "      privileged: true"
      echo "      propagate-environment: true"
      echo "  commands:"
      echo "    - ./.expeditor/scripts/download_built_omnibus_pkgs.sh"
      echo "    - omnibus/omnibus-test.sh"
      echo "  timeout_in_minutes: 60"
    else
      echo "- env:"
      echo "    OMNIBUS_BUILDER_KEY: build-${platform#*:}"
      echo "  label: \":mag::windows: ${platform%:*}\""
      echo "  key: test-${platform%:*}"
      echo "  retry:"
      echo "    automatic:"
      echo "      limit: 1"
      echo "  agents:"
      if [[ $BUILDKITE_ORGANIZATION_SLUG == "chef-oss" ]]
      then
        echo "    queue: default-${platform%:*}-privileged"
      else
        echo "    queue: omnibus-${platform%:*}-x86_64"
      fi
      echo "  commands:"
      echo "    - ./.expeditor/scripts/download_built_omnibus_pkgs.ps1"
      echo "    - ./omnibus/omnibus-test.ps1"
      echo "  timeout_in_minutes: 120"
    fi
  done
fi

# using shell parameter expansion this checks to make sure the esoteric_test_platforms array isn't empty if OMNIBUS_FILTER is only container platforms
# prevents esoteric_test_platforms unbound variable error
if [[ $BUILDKITE_ORGANIZATION_SLUG != "chef-oss" ]] && [[ ! -z "${esoteric_test_platforms:-}" ]]
then

  for platform in ${esoteric_test_platforms[@]}; do
    build_key=$(echo ${platform#*:} | tr . _)
    test_key=$(echo ${platform%:*} | tr . _)
    echo "- env:"
    if [ $build_key == "el-7-ppc64" ] || [ $build_key == "el-7-ppc64le" ]
    then
      echo "    OMNIBUS_FIPS_MODE: true"
    else
      echo "    OMNIBUS_FIPS_MODE: false"
    fi
    echo "    OMNIBUS_BUILDER_KEY: build-${build_key}"
    echo "  key: test-${test_key}"
    echo "  label: \":mag: ${platform%:*}\""
    echo "  retry:"
    echo "    automatic:"
    echo "      limit: 1"
    if [[ $platform == *"aix"* ]]; then
      echo "  timeout_in_minutes: 180"
    else
      echo "  timeout_in_minutes: 90"
    fi
    echo "  agents:"
    echo "    queue: omnibus-${platform%:*}"
    if [ $build_key == "mac_os_x-11-x86_64" ] || [ $build_key == "mac_os_x-11-arm64" ]
    then
      echo "    omnibus: tester"
      echo "    omnibus-toolchain: \"*\""
    fi
    echo "  plugins:"
    echo "  - chef/omnibus#v0.2.89:"
    echo "      test: chef"
    echo "      test-path: omnibus/omnibus-test.sh"
    echo "      install-dir: \"/opt/chef\""
    if [[ ${platform%:*} == mac_os_x*x86_64 ]]
    then
      echo "      remote-host: buildkite-omnibus-${platform%:*}"
    fi
    # if [ $test_key == "mac_os_x-11-arm64" ] || [ $test_key == "mac_os_x-12-arm64" ]
    # then
    #   echo "  concurrency: 2"
    #   echo "  concurrency_group: omnibus-$test_key/test/chef"
    # fi
    if [ $test_key == "freebsd-13-amd64" ]
    then
      echo "  soft_fail: true"
    fi
  done
fi

if [[ $BUILDKITE_PIPELINE_SLUG == "chef-chef-main-validate-release" ]]
then
  echo "- wait: ~"
  echo "- key: promote"
  echo "  label: \":artifactory: Promote to Current\""
  echo "  plugins:"
  echo "  - chef/omnibus#v0.2.89:"
  echo "      promote: chef"
fi
