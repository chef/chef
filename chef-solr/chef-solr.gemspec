# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{chef-solr}
  s.version = "0.8.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Adam Jacob"]
  s.date = %q{2009-07-19}
  s.email = %q{adam@opscode.com}
  s.executables = ["chef-solr", "chef-solr-indexer", "chef-solr-rebuild"]
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.has_rdoc = true
  s.homepage = %q{http://github.com/adamhjk/chef-solr}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.1}
  s.summary = %q{Search indexing for Chef}
  s.test_files = [
    "spec/chef/solr/index_spec.rb",
     "spec/chef/solr/query_spec.rb",
     "spec/chef/solr_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 2

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
