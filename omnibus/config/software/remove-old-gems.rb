name "remove-old-gems"

license :project_license
skip_transitive_dependency_licensing true

dependency "ruby"

build do
  block "Removing old versions of rexml < 3.3.6" do
    env = with_standard_compiler_flags(with_embedded_path)
    command "gem uninstall rexml -v '<3.3.6' -a -x -I", env: env
  end
end