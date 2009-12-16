Gem::Specification.new do |s|
  s.name = %q{chef-server}
  s.version = "0.5.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Adam Jacob"]
  s.date = %q{2009-01-15}
  s.description = %q{A systems integration framework, built to bring the benefits of configuration management to your entire infrastructure.}
  s.email = %q{adam@opscode.com}
  s.executables = ["chef-indexer", "chef-server"]
  s.extra_rdoc_files = ["README.txt", "LICENSE", "NOTICE"]
  s.files = ["LICENSE", "README.txt", "Rakefile", "lib/chef", "lib/chef/search.rb", "lib/chef/search_index.rb", "lib/controllers", "lib/controllers/application.rb", "lib/controllers/cookbook_attributes.rb", "lib/controllers/cookbook_definitions.rb", "lib/controllers/cookbook_files.rb", "lib/controllers/cookbook_libraries.rb", "lib/controllers/cookbook_recipes.rb", "lib/controllers/cookbook_templates.rb", "lib/controllers/cookbooks.rb", "lib/controllers/exceptions.rb", "lib/controllers/nodes.rb", "lib/controllers/openid_consumer.rb", "lib/controllers/openid_register.rb", "lib/controllers/openid_server.rb", "lib/controllers/search.rb", "lib/controllers/search_entries.rb", "lib/helpers", "lib/helpers/cookbooks_helper.rb", "lib/helpers/global_helpers.rb", "lib/helpers/nodes_helper.rb", "lib/helpers/openid_server_helpers.rb", "lib/init.rb", "lib/public", "lib/public/images", "lib/public/images/indicator.gif", "lib/public/images/merb.jpg", "lib/public/javascript", "lib/public/javascript/chef.js", "lib/public/jquery", "lib/public/jquery/jquery-1.2.6.min.js", "lib/public/jquery/jquery.jeditable.mini.js", "lib/public/stylesheets", "lib/public/stylesheets/master.css", "lib/views", "lib/views/cookbook_templates", "lib/views/cookbook_templates/index.html.haml", "lib/views/cookbooks", "lib/views/cookbooks/_attribute_file.html.haml", "lib/views/cookbooks/_syntax_highlight.html.haml", "lib/views/cookbooks/attribute_files.html.haml", "lib/views/cookbooks/index.html.haml", "lib/views/cookbooks/show.html.haml", "lib/views/exceptions", "lib/views/exceptions/bad_request.json.erb", "lib/views/exceptions/internal_server_error.html.erb", "lib/views/exceptions/not_acceptable.html.erb", "lib/views/exceptions/not_found.html.erb", "lib/views/layout", "lib/views/layout/application.html.haml", "lib/views/nodes", "lib/views/nodes/_action.html.haml", "lib/views/nodes/_node.html.haml", "lib/views/nodes/_resource.html.haml", "lib/views/nodes/compile.html.haml", "lib/views/nodes/index.html.haml", "lib/views/nodes/show.html.haml", "lib/views/openid_consumer", "lib/views/openid_consumer/index.html.haml", "lib/views/openid_consumer/start.html.haml", "lib/views/openid_login", "lib/views/openid_login/index.html.haml", "lib/views/openid_register", "lib/views/openid_register/index.html.haml", "lib/views/openid_register/show.html.haml", "lib/views/openid_server", "lib/views/openid_server/decide.html.haml", "lib/views/search", "lib/views/search/_search_form.html.haml", "lib/views/search/index.html.haml", "lib/views/search/show.html.haml", "lib/views/search_entries", "lib/views/search_entries/index.html.haml", "lib/views/search_entries/show.html.haml", "bin/chef-indexer", "bin/chef-server", "NOTICE"]
  s.has_rdoc = true
  s.homepage = %q{http://wiki.opscode.com/display/chef}
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.2.0}
  s.summary = %q{A systems integration framework, built to bring the benefits of configuration management to your entire infrastructure.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if current_version >= 3 then
      s.add_runtime_dependency(%q<stomp>, [">= 0"])
      s.add_runtime_dependency(%q<stompserver>, [">= 0"])
      s.add_runtime_dependency(%q<ferret>, [">= 0"])
      s.add_runtime_dependency(%q<merb-core>, [">= 0"])
      s.add_runtime_dependency(%q<merb-haml>, [">= 0"])
      s.add_runtime_dependency(%q<thin>, [">= 0"])
      s.add_runtime_dependency(%q<haml>, [">= 0"])
      s.add_runtime_dependency(%q<ruby-openid>, [">= 0"])
      s.add_runtime_dependency(%q<json>, [">= 0"])
      s.add_runtime_dependency(%q<syntax>, [">= 0"])
    else
      s.add_dependency(%q<stomp>, [">= 0"])
      s.add_dependency(%q<stompserver>, [">= 0"])
      s.add_dependency(%q<ferret>, [">= 0"])
      s.add_dependency(%q<merb-core>, [">= 0"])
      s.add_dependency(%q<merb-haml>, [">= 0"])
      s.add_dependency(%q<thin>, [">= 0"])
      s.add_dependency(%q<haml>, [">= 0"])
      s.add_dependency(%q<ruby-openid>, [">= 0"])
      s.add_dependency(%q<json>, [">= 0"])
      s.add_dependency(%q<coderay>, [">= 0"])
    end
  else
    s.add_dependency(%q<stomp>, [">= 0"])
    s.add_dependency(%q<stompserver>, [">= 0"])
    s.add_dependency(%q<ferret>, [">= 0"])
    s.add_dependency(%q<merb-core>, [">= 0"])
    s.add_dependency(%q<merb-haml>, [">= 0"])
    s.add_dependency(%q<thin>, [">= 0"])
    s.add_dependency(%q<haml>, [">= 0"])
    s.add_dependency(%q<ruby-openid>, [">= 0"])
    s.add_dependency(%q<json>, [">= 0"])
    s.add_dependency(%q<syntax>, [">= 0"])
  end
end
