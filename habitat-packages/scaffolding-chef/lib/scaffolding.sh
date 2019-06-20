#
# A scaffolding for Chef Policyfile packages
#

if [ -z "${scaffold_policy_name+x}" ]; then
  echo "You must set \$scaffold_policy_name to a valid policy name. For example:"
  echo
  echo "\$scaffold_policy_name=base"
  echo
  echo "Will build a base.rb policyfile"
  exit 1
fi

scaffolding_load() {
  : "${scaffold_chef_client:=chef/chef-client}"
  : "${scaffold_chef_dk:=chef/chef-dk}"
  : "${scaffold_policyfiles_path:=$PLAN_CONTEXT/../policyfiles}"
  : "${scaffold_data_bags_path:=$PLAN_CONTEXT/../data_bags}"

  pkg_deps=(
    "${pkg_deps[@]}"
    "${scaffold_chef_client}"
    "core/cacerts"
  )
  pkg_build_deps=(
    "${pkg_build_deps[@]}"
    "${scaffold_chef_dk}"
    "core/git"
  )

  pkg_svc_user="root"
  pkg_svc_run="set_just_so_you_will_render"
}

do_default_download() {
  return 0
}

do_default_verify() {
  return 0
}

do_default_unpack() {
  return 0
}

do_default_build_service() {
  ## Create hooks
  build_line "Creating lifecycle hooks"
  mkdir -p "${pkg_prefix}/hooks"
  chmod 0750 "${pkg_prefix}/hooks"

  # Run hook
  cat << EOF >> "${pkg_prefix}/hooks/run"
#!/bin/sh

CFG_ENV_PATH_PREFIX={{cfg.env_path_prefix}}
CFG_ENV_PATH_PREFIX="\${CFG_ENV_PATH_PREFIX:-/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin}"
CFG_INTERVAL={{cfg.interval}}
CFG_INTERVAL="\${CFG_INTERVAL:-1800}"
CFG_LOG_LEVEL={{cfg.log_level}}
CFG_LOG_LEVEL="\${CFG_LOG_LEVEL:-warn}"
CFG_RUN_LOCK_TIMEOUT={{cfg.run_lock_timeout}}
CFG_RUN_LOCK_TIMEOUT="\${CFG_RUN_LOCK_TIMEOUT:-1800}"
CFG_SPLAY={{cfg.splay}}
CFG_SPLAY="\${CFG_SPLAY:-1800}"
CFG_SPLAY_FIRST_RUN={{cfg.splay_first_run}}
CFG_SPLAY_FIRST_RUN="\${CFG_SPLAY_FIRST_RUN:-0}"
CFG_SSL_VERIFY_MODE={{cfg.ssl_verify_mode}}
CFG_SSL_VERIFY_MODE="\${CFG_SSL_VERIFY_MODE:-:verify_peer}"

chef_client_cmd()
{
  chef-client -z -l \$CFG_LOG_LEVEL -c $pkg_svc_config_path/client-config.rb -j $pkg_svc_config_path/attributes.json --once --no-fork --run-lock-timeout \$CFG_RUN_LOCK_TIMEOUT
}

SPLAY_DURATION=\$(shuf -i 0-\$CFG_SPLAY -n 1)

SPLAY_FIRST_RUN_DURATION=\$(shuf -i 0-\$CFG_SPLAY_FIRST_RUN -n 1)

export SSL_CERT_FILE="{{pkgPathFor "core/cacerts"}}/ssl/cert.pem"

cd {{pkg.path}}

exec 2>&1
sleep \$SPLAY_FIRST_RUN_DURATION
chef_client_cmd

while true; do

sleep \$SPLAY_DURATION
sleep \$CFG_INTERVAL
chef_client_cmd
done
EOF

  chmod 0750 "${pkg_prefix}/hooks/run"
}

do_default_build() {
  if [ ! -d "${scaffold_policyfiles_path}" ]; then
    build_line "Could not detect a policyfiles directory, this is required to proceed!"
    exit 1
  fi

  rm -f "${scaffold_policyfiles_path}"/*.lock.json

  policyfile="${scaffold_policyfiles_path}/${scaffold_policy_name}.rb"

  for p in $(grep include_policy "${policyfile}" | awk -F "," '{print $1}' | awk -F '"' '{print $2}' | tr -d " "); do
    build_line "Detected included policyfile, ${p}.rb, installing"
    chef install "${scaffold_policyfiles_path}/${p}.rb"
  done

  build_line "Installing ${policyfile}"
  chef install "${policyfile}"
}

do_default_install() {
  build_line "Exporting Chef Infra Repository"
  chef export "${scaffold_policyfiles_path}/${scaffold_policy_name}.lock.json" "${pkg_prefix}"

  build_line "Creating Chef Infra configuration"
  mkdir -p "${pkg_prefix}/config"
  chmod 0750 "${pkg_prefix}/config"
  cat << EOF >> "${pkg_prefix}/.chef/config.rb"
cache_path "$pkg_svc_data_path/cache"
node_path "$pkg_svc_data_path/nodes"
role_path "$pkg_svc_data_path/roles"

chef_zero.enabled true
EOF

  build_line "Creating initial bootstrap configuration"
  cp "${pkg_prefix}/.chef/config.rb" "${pkg_prefix}/config/bootstrap-config.rb"
  cat << EOF >> "${pkg_prefix}/config/bootstrap-config.rb"
ENV['PATH'] = "/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:#{ENV['PATH']}"
EOF

  build_line "Creating Chef Infra client configuration"
  cp "${pkg_prefix}/.chef/config.rb" "${pkg_prefix}/config/client-config.rb"
  cat << EOF >> "${pkg_prefix}/config/client-config.rb"
ssl_verify_mode {{cfg.ssl_verify_mode}}
ENV['PATH'] = "{{cfg.env_path_prefix}}:#{ENV['PATH']}"

{{#if cfg.data_collector.enable ~}}
chef_guid "{{sys.member_id}}"
data_collector.token "{{cfg.data_collector.token}}"
data_collector.server_url "{{cfg.data_collector.server_url}}"
{{/if ~}}
EOF
  chmod 0640 "${pkg_prefix}/config/client-config.rb"

  build_line "Generating config/attributes.json"
  cat << EOF >> "${pkg_prefix}/config/attributes.json"
{{#if cfg.attributes ~}}
{{toJson cfg.attributes}}
{{else ~}}
{}
{{/if ~}}
EOF

  build_line "Generating Chef Habitat configuration, default.toml"
  cat << EOF >> "${pkg_prefix}/default.toml"
interval = 1800
splay = 1800
splay_first_run = 0
run_lock_timeout = 1800
log_level = "warn"
chef_client_ident = "" # this is blank by default so it can be populated from the bind
env_path_prefix = "/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin"
ssl_verify_mode = ":verify_peer"

[data_collector]
enable = false
token = "set_to_your_token"
server_url = "set_to_your_url"
EOF
  chmod 0640 "${pkg_prefix}/default.toml"

  if [ -d "${scaffold_data_bags_path}" ]; then
    build_line "Detected a data bags directory, installing into package"
    cp -a "${scaffold_data_bags_path}" "${pkg_prefix}"
  fi
}

do_default_strip() {
  return 0
}
