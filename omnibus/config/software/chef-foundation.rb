name "chef-foundation"
license "Apache-2.0"
license_file "LICENSE"

# Grab accompanying notice file.
# So that Open4/deep_merge/diff-lcs disclaimers are present in Omnibus LICENSES tree.
license_file "NOTICE"

skip_transitive_dependency_licensing true

if windows?
  source path: "c:/opscode/chef"
else
  source path: "/opt/chef"
end

relative_path "chef-foundation"

# In order to pass notarization we need to sign any binaries and libraries included in the package.
# This makes sure we include and bins and libs that are brought in by gems.
ruby_version = `#{project_dir}/embedded/bin/ruby -v`
ruby_version = ruby_version.split(" ")[1][0..2]
ruby_mmv = "#{ruby_version}.0"
ruby_dir = "#{install_dir}/embedded/lib/ruby/#{ruby_mmv}"
gem_dir = "#{install_dir}/embedded/lib/ruby/gems/#{ruby_mmv}"
bin_dirs bin_dirs.concat ["#{gem_dir}/gems/*/bin/**"]
lib_dirs ["#{ruby_dir}/**", "#{gem_dir}/extensions/**", "#{gem_dir}/bundler/gems/extensions/**", "#{gem_dir}/bundler/gems/*", "#{gem_dir}/bundler/gems/*/lib/**", "#{gem_dir}/gems/*", "#{gem_dir}/gems/*/lib/**", "#{gem_dir}/gems/*/ext/**"]

build do
  sync "#{project_dir}", "#{install_dir}"
end