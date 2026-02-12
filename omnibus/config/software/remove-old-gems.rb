name "remove-old-gems"

license :project_license
skip_transitive_dependency_licensing true

build do
  block "Removing old gem versions" do
    # Hash of gems to remove with version constraints
    # Key: gem name, Value: version constraint (e.g., "<3.4.2")
    gems_to_remove = {
      "rexml" => "<3.4.2",
      "net-imap" => "<0.2.5",
    }

    gemfile = "#{install_dir}/embedded/bin/gem"

    next unless File.exist?(gemfile)

    env = with_standard_compiler_flags(with_embedded_path)

    gems_to_remove.each do |gem_name, version_constraint|
      puts "Removing old versions of #{gem_name} #{version_constraint}"
      # remove [-a] all versions matching constraint including [-x] executables and [-I] ignore dependencies
      command "#{gemfile} uninstall #{gem_name} -v \"#{version_constraint}\" -a -x -I", env: env
    end
  end
end
