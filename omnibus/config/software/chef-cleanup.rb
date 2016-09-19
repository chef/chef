name "chef-cleanup"
default_version "local_source"

license :project_license
skip_transitive_dependency_licensing true

source path: project.files_path

dependency "chef"

build do
  # This is where we get the definitions below
  require_relative "../../files/chef/build-chef"
  extend BuildChef

  # Clear the now-unnecessary git caches, cached gems, and git-checked-out gems
  block "Delete bundler git cache and git installs" do
    gemdir = shellout!("#{gem_bin} environment gemdir", env: env).stdout.chomp
    remove_directory "#{gemdir}/cache"
    remove_directory "#{gemdir}/bundler"
  end

  delete "#{install_dir}/embedded/docs"
  delete "#{install_dir}/embedded/share/man"
  delete "#{install_dir}/embedded/share/doc"
  delete "#{install_dir}/embedded/share/gtk-doc"
  delete "#{install_dir}/embedded/ssl/man"
  delete "#{install_dir}/embedded/man"
  delete "#{install_dir}/embedded/info"
end
