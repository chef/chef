name "chef-appbundle"
default_version "local_source"

license :project_license
skip_transitive_dependency_licensing true

source path: project.files_path

dependency "chef"

build do
  # This is where we get the definitions below
  require_relative "../../files/chef-appbundle/build-chef-appbundle"
  extend BuildChefAppbundle

  appbundle_gem "chef"
  appbundle_gem "ohai"
end
