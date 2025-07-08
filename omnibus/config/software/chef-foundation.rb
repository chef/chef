name "chef-foundation"
license "Apache-2.0"
license_file "LICENSE"
license_file "NOTICE"

skip_transitive_dependency_licensing true

if windows?
  source path: "c:/opscode/chef"
else
  source path: "/opt/chef"
end

relative_path "chef-foundation"

build do
  # Sync everything except the Ruby directory
  sync "#{project_dir}", "#{install_dir}", exclude: "embedded/bin/ruby*"
  sync "#{project_dir}", "#{install_dir}", exclude: "embedded/lib/ruby"
  
  # Create placeholder directories that will be replaced by your custom Ruby
  mkdir "#{install_dir}/embedded/bin"
  mkdir "#{install_dir}/embedded/lib/ruby"
end