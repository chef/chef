apt_update

hab_sup "default" do
  license "accept"
end

ruby_block "wait-for-sup-default-startup" do
  block do
    raise unless system("hab sup status")
  end
  retries 30
  retry_delay 1
end

hab_package "core/jq-static" do
  binlink true
end

hab_user_toml "nginx" do
  config(
    worker_processes: 2,
    http: {
      keepalive_timeout: 120,
    }
  )
end

hab_package "core/nginx"
hab_service "core/nginx"

# we need to sleep to let the nginx service have enough time to
# startup properly before we can configure it.
# This is here due to https://github.com/habitat-sh/habitat/issues/3155 and
# can be removed if that issue is fixed.
ruby_block "wait-for-nginx-startup" do
  block do
    sleep 3
  end
  action :nothing
  subscribes :run, "hab_service[core/nginx]", :immediately
end
