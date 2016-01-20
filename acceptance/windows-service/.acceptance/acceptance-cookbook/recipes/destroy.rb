execute 'bundle exec kitchen destroy' do
  cwd node['chef-acceptance']['suite-dir']
end
