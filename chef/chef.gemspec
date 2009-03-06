Gem::Specification.new do |s|
  s.name = %q{chef}
  s.version = "0.5.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Adam Jacob"]
  s.date = %q{2009-01-15}
  s.description = %q{A systems integration framework, built to bring the benefits of configuration management to your entire infrastructure.}
  s.email = %q{adam@opscode.com}
  s.executables = ["chef-client", "chef-solo"]
  s.extra_rdoc_files = ["README.txt", "LICENSE", "NOTICE"]
  s.files = ["LICENSE", "README.txt", "Rakefile", "lib/chef", "lib/chef/client.rb", "lib/chef/compile.rb", "lib/chef/config.rb", "lib/chef/cookbook.rb", "lib/chef/cookbook_loader.rb", "lib/chef/couchdb.rb", "lib/chef/daemon.rb", "lib/chef/exceptions.rb", "lib/chef/file_cache.rb", "lib/chef/log", "lib/chef/log/formatter.rb", "lib/chef/log.rb", "lib/chef/mixin", "lib/chef/mixin/check_helper.rb", "lib/chef/mixin/checksum.rb", "lib/chef/mixin/command.rb", "lib/chef/mixin/create_path.rb", "lib/chef/mixin/from_file.rb", "lib/chef/mixin/generate_url.rb", "lib/chef/mixin/language.rb", "lib/chef/mixin/params_validate.rb", "lib/chef/mixin/template.rb", "lib/chef/node.rb", "lib/chef/openid_registration.rb", "lib/chef/platform.rb", "lib/chef/provider", "lib/chef/provider/directory.rb", "lib/chef/provider/execute.rb", "lib/chef/provider/file.rb", "lib/chef/provider/group", "lib/chef/provider/group/groupadd.rb", "lib/chef/provider/group.rb", "lib/chef/provider/http_request.rb", "lib/chef/provider/link.rb", "lib/chef/provider/package", "lib/chef/provider/package/apt.rb", "lib/chef/provider/package/portage.rb", "lib/chef/provider/package/rubygems.rb", "lib/chef/provider/package.rb", "lib/chef/provider/remote_directory.rb", "lib/chef/provider/remote_file.rb", "lib/chef/provider/script.rb", "lib/chef/provider/service", "lib/chef/provider/service/debian.rb", "lib/chef/provider/service/init.rb", "lib/chef/provider/service.rb", "lib/chef/provider/template.rb", "lib/chef/provider/user", "lib/chef/provider/user/useradd.rb", "lib/chef/provider/user.rb", "lib/chef/provider.rb", "lib/chef/queue.rb", "lib/chef/recipe.rb", "lib/chef/resource", "lib/chef/resource/apt_package.rb", "lib/chef/resource/bash.rb", "lib/chef/resource/csh.rb", "lib/chef/resource/directory.rb", "lib/chef/resource/execute.rb", "lib/chef/resource/file.rb", "lib/chef/resource/gem_package.rb", "lib/chef/resource/group.rb", "lib/chef/resource/http_request.rb", "lib/chef/resource/link.rb", "lib/chef/resource/package.rb", "lib/chef/resource/perl.rb", "lib/chef/resource/portage_package.rb", "lib/chef/resource/python.rb", "lib/chef/resource/remote_directory.rb", "lib/chef/resource/remote_file.rb", "lib/chef/resource/ruby.rb", "lib/chef/resource/script.rb", "lib/chef/resource/service.rb", "lib/chef/resource/template.rb", "lib/chef/resource/user.rb", "lib/chef/resource.rb", "lib/chef/resource_collection.rb", "lib/chef/resource_definition.rb", "lib/chef/rest.rb", "lib/chef/runner.rb", "lib/chef.rb", "config/server.rb", "examples/config", "examples/config/chef-solo.rb", "examples/config/cookbooks", "examples/config/cookbooks/fakefile", "examples/config/cookbooks/fakefile/attributes", "examples/config/cookbooks/fakefile/attributes/first.rb", "examples/config/cookbooks/fakefile/definitions", "examples/config/cookbooks/fakefile/definitions/test.rb", "examples/config/cookbooks/fakefile/files", "examples/config/cookbooks/fakefile/files/default", "examples/config/cookbooks/fakefile/files/default/remote_test", "examples/config/cookbooks/fakefile/files/default/remote_test/another", "examples/config/cookbooks/fakefile/files/default/remote_test/another/turn", "examples/config/cookbooks/fakefile/files/default/remote_test/another/turn/the_page.txt", "examples/config/cookbooks/fakefile/files/default/remote_test/another/window.txt", "examples/config/cookbooks/fakefile/files/default/remote_test/mycat.txt", "examples/config/cookbooks/fakefile/files/default/the_park.txt", "examples/config/cookbooks/fakefile/libraries", "examples/config/cookbooks/fakefile/libraries/test.rb", "examples/config/cookbooks/fakefile/recipes", "examples/config/cookbooks/fakefile/recipes/default.rb", "examples/config/cookbooks/fakefile/templates", "examples/config/cookbooks/fakefile/templates/default", "examples/config/cookbooks/fakefile/templates/default/monkey.erb", "examples/config/cookbooks/rubygems_server", "examples/config/cookbooks/rubygems_server/attributes", "examples/config/cookbooks/rubygems_server/attributes/first.rb", "examples/config/cookbooks/rubygems_server/files", "examples/config/cookbooks/rubygems_server/files/default", "examples/config/cookbooks/rubygems_server/files/default/packages", "examples/config/cookbooks/rubygems_server/files/default/packages/net-scp-1.0.1.gem", "examples/config/cookbooks/rubygems_server/files/default/packages/net-sftp-2.0.1.gem", "examples/config/cookbooks/rubygems_server/files/default/packages/net-ssh-2.0.3.gem", "examples/config/cookbooks/rubygems_server/files/default/packages/net-ssh-gateway-1.0.0.gem", "examples/config/cookbooks/rubygems_server/recipes", "examples/config/cookbooks/rubygems_server/recipes/default.rb", "examples/config/cookbooks/servicetest", "examples/config/cookbooks/servicetest/recipes", "examples/config/cookbooks/servicetest/recipes/default.rb", "examples/config/cookbooks/tempfile", "examples/config/cookbooks/tempfile/attributes", "examples/config/cookbooks/tempfile/attributes/second.rb", "examples/config/cookbooks/tempfile/recipes", "examples/config/cookbooks/tempfile/recipes/default.rb", "examples/config/nodes", "examples/config/nodes/adam.rb", "examples/config/nodes/default.rb", "examples/config/nodes/junglist.gen.nz.rb", "examples/config/nodes/latte.rb", "examples/config.rb", "examples/mrepo", "examples/mrepo/Rakefile", "examples/node.rb", "examples/node.yml", "examples/sample_definition.rb", "examples/sample_recipe.rb", "examples/search_index", "examples/search_index/segments", "examples/search_index/segments_0", "examples/search_syntax.rb", "examples/user_index.pl", "examples/user_index.rb", "bin/chef-client", "bin/chef-solo", "NOTICE"]
  s.has_rdoc = true
  s.homepage = %q{http://wiki.opscode.com/display/chef}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{A systems integration framework, built to bring the benefits of configuration management to your entire infrastructure.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<ruby-openid>, [">= 0"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_runtime_dependency(%q<erubis>, [">= 0"])
      s.add_runtime_dependency(%q<extlib>, [">= 0"])
      s.add_runtime_dependency(%q<stomp>, [">= 0"])
      s.add_runtime_dependency(%q<ohai>, [">= 0"])
    else
      s.add_dependency(%q<ruby-openid>, [">= 0"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<erubis>, [">= 0"])
      s.add_dependency(%q<extlib>, [">= 0"])
      s.add_dependency(%q<stomp>, [">= 0"])
      s.add_dependency(%q<ohai>, [">= 0"])
    end
  else
    s.add_dependency(%q<ruby-openid>, [">= 0"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<erubis>, [">= 0"])
    s.add_dependency(%q<extlib>, [">= 0"])
    s.add_dependency(%q<stomp>, [">= 0"])
    s.add_dependency(%q<ohai>, [">= 0"])
  end
end
