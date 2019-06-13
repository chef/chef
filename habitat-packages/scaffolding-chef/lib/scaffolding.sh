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

  pkg_deps=(
    "${pkg_deps[@]}"
    "$scaffold_chef_client"
    "core/cacerts"
  )
  pkg_build_deps=(
    "${pkg_build_deps[@]}"
    "$scaffold_chef_dk"
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
  mkdir -p "$pkg_prefix/hooks"
  chmod 0750 "$pkg_prefix/hooks"

  # Run hook
  cat << EOF >> "$pkg_prefix/hooks/run"
#!/bin/sh

chef_client_cmd()
{
  chef-client -z -l {{cfg.log_level}} -c $pkg_svc_config_path/client-config.rb -j $pkg_svc_config_path/attributes.json --once --no-fork --run-lock-timeout {{cfg.run_lock_timeout}}
}

SPLAY_DURATION=\$({{pkgPathFor "core/coreutils"}}/bin/shuf -i 0-{{cfg.splay}} -n 1)

SPLAY_FIRST_RUN_DURATION=\$({{pkgPathFor "core/coreutils"}}/bin/shuf -i 0-{{cfg.splay_first_run}} -n 1)

export SSL_CERT_FILE="{{pkgPathFor "core/cacerts"}}/ssl/cert.pem"

cd {{pkg.path}}

# After the first run of the chef-client,
# export the new package ident so that
# other software can bind to it.
# For example, this is useful for InSpec
# to execute its run hook immediately after
# the chef-client run has finished.

exec 2>&1
sleep \$SPLAY_FIRST_RUN_DURATION
chef_client_cmd

while true; do

sleep \$SPLAY_DURATION
sleep {{cfg.interval}}
chef_client_cmd
done
EOF
  chmod 0750 "$pkg_prefix/hooks/run"
}

do_default_build() {
  if [ -d "$PLAN_CONTEXT/../policyfiles" ]; then
    _policyfile_path="$PLAN_CONTEXT/../policyfiles"
  else
    if [ -d "$PLAN_CONTEXT/../../policyfiles" ]; then
      _policyfile_path="$PLAN_CONTEXT/../../policyfiles"
    else
      if [ -d "$PLAN_CONTEXT/../../../policyfiles" ]; then
        _policyfile_path="$PLAN_CONTEXT/../../../policyfiles"
      else
        echo "Cannot detect a policyfiles directory!"
        exit 1
      fi
    fi
  fi
  rm -f "$_policyfile_path"/*.lock.json
  policyfile="$_policyfile_path/$scaffold_policy_name.rb"
  for x in $(grep include_policy "$policyfile" | awk -F "," '{print $1}' | awk -F '"' '{print $2}' | tr -d " "); do
    chef install "$_policyfile_path/$x.rb"
  done
  chef install "$policyfile"
}

do_default_install() {
  chef export "$_policyfile_path/$scaffold_policy_name.lock.json" "$pkg_prefix"

  mkdir -p "$pkg_prefix/config"
  chmod 0750 "$pkg_prefix/config"
  cat << EOF >> "$pkg_prefix/.chef/config.rb"
cache_path "$pkg_svc_data_path/cache"
node_path "$pkg_svc_data_path/nodes"
role_path "$pkg_svc_data_path/roles"

chef_zero.enabled true
EOF

  cp "$pkg_prefix/.chef/config.rb" "$pkg_prefix/config/bootstrap-config.rb"
  cat << EOF >> "$pkg_prefix/config/bootstrap-config.rb"
ENV['PATH'] = "/sbin:/usr/sbin:/usr/local/sbin:/usr/local/bin:/usr/bin:/bin:#{ENV['PATH']}"
EOF

  cp "$pkg_prefix/.chef/config.rb" "$pkg_prefix/config/client-config.rb"
  cat << EOF >> "$pkg_prefix/config/client-config.rb"
ssl_verify_mode {{cfg.ssl_verify_mode}}
ENV['PATH'] = "{{cfg.env_path_prefix}}:#{ENV['PATH']}"

{{#if cfg.data_collector.enable ~}}
chef_guid "{{sys.member_id}}"
data_collector.token "{{cfg.data_collector.token}}"
data_collector.server_url "{{cfg.data_collector.server_url}}"
{{/if ~}}
EOF
  chmod 0640 "$pkg_prefix/config/client-config.rb"

  cat << EOF >> "$pkg_prefix/config/attributes.json"
{{#if cfg.attributes ~}}
{{toJson cfg.attributes}}
{{else ~}}
{}
{{/if ~}}
EOF

  ## Create config
  cat << EOF >> "$pkg_prefix/default.toml"
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
  chmod 0640 "$pkg_prefix/default.toml"
}

do_default_strip() {
  return 0
}
