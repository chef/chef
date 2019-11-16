chef_repo_path "{{pkg.svc_data_path}}/chef"
file_backup_path "{{pkg.svc_data_path}}/{{cfg.file_backup_path}}"
pid_file "{{pkg.svc_data_path}}/{{cfg.pid_file}}"
data_collector.server_url "{{cfg.data_collector.url}}"
data_collector.token "{{cfg.data_collector.token}}"
data_collector.mode "{{cfg.data_collector.mode}}".to_sym
data_collector.raise_on_failure "{{cfg.data_collector.raise_on_failure}}"
minimal_ohai "{{cfg.minimal_ohai}}"
local_mode "{{cfg.local_mode}}"
{{#if cfg.chef-client.node_name ~}}
node_name "{{cfg.node_name}}"
{{/if ~}}
splay "{{cfg.splay}}"
interval "{{cfg.interval}}"
log_location "{{cfg.log_location}}"
log_level "{{cfg.log_level}}".to_sym
{{#if cfg.use_member_id_as_uuid ~}}
chef_guid "{{svc.me.member_id}}"
{{/if ~}}
