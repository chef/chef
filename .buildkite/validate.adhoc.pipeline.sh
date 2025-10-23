#!/bin/bash

workdir=$(pwd)

echo "--- Installing Ruby.."
curl -sSL https://cache.ruby-lang.org/pub/ruby/3.4/ruby-3.4.2.tar.xz | tar -xJ -C /tmp

cd /tmp/ruby-3.4.2
./configure --prefix=/tmp/ruby-3.4.2-install
make -j"$(nproc)"
make install

echo "Installed Ruby version"
/tmp/ruby-3.4.2-install/bin/ruby -v

cd $workdir

echo "--- Generating pipeline configuration.."
/tmp/ruby-3.4.2-install/bin/ruby .buildkite/validate-adhoc.rb > pipeline-config.yaml

# Habitat plans
habitat_plans=("linux" "windows")

for plan in ${habitat_plans[@]}; do
  echo "- label: \":habicat: $plan plan\"" >> $pipeline_config
  echo "  retry:" >> $pipeline_config
  echo "    automatic:" >> $pipeline_config
  echo "      limit: 1" >> $pipeline_config
  echo "  agents:" >> $pipeline_config
  if [ $plan == "windows" ]; then
    echo "    queue: single-use-windows-2019-privileged" >> $pipeline_config
  else
    echo "    queue: single-use-privileged" >> $pipeline_config
  fi
  echo "  env:" >> $pipeline_config
  echo "    ARTIFACTORY_URL: ${ARTIFACTORY_URL:-https://artifactory-internal.ps.chef.co/artifactory/omnibus-gems-local}" >> $pipeline_config
  echo "  timeout_in_minutes: 60" >> $pipeline_config
  echo "  commands:" >> $pipeline_config
  if [ $plan == "windows" ]; then
    echo "    - ./.expeditor/scripts/verify-plan.ps1" >> $pipeline_config
  else
    echo "    - sudo -E ./.expeditor/scripts/install-hab.sh 'x86_64-$plan'" >> $pipeline_config
    echo "    - sudo ./.expeditor/scripts/verify-plan.sh" >> $pipeline_config
  fi
done

echo "--- Uploading pipeline configuration.."
buildkite-agent pipeline upload pipeline-config.yaml
