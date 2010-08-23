log_level                :debug
log_location             STDOUT
# Webui is an admin.
# env.rb gets the client name from Chef::Config[:web_ui_client_name] but we
# cannot use that since it won't be loaded in knife's memory.
systmpdir = File.expand_path(File.join(Dir.tmpdir, "chef_integration"))
node_name                'chef-webui' 
client_key               File.join(systmpdir, "webui.pem")
validation_client_name   'chef-validator'
validation_key           File.join(systmpdir, "validation.pem")
chef_server_url          'http://localhost:4000'
cache_type               'BasicFile'
