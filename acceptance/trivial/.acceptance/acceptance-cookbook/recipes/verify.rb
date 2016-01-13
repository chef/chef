execute 'bundle exec kitchen verify' do
  cwd node['chef-acceptance']['suite-dir']
end
