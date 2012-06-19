$:.unshift(File.dirname(__FILE__) + '/lib')

sandbox = Module.new
sandbox.module_eval(IO.read(File.expand_path('../lib/chef/expander/version.rb', __FILE__)))

Gem::Specification.new do |s|
  s.name = 'chef-expander'
  s.version = sandbox::Chef::Expander::VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.rdoc", "LICENSE" ]
  s.summary = "A systems integration framework, built to bring the benefits of configuration management to your entire infrastructure."
  s.description = s.summary
  s.author = "Adam Jacob"
  s.email = "adam@opscode.com"
  s.homepage = "http://wiki.opscode.com/display/chef"

  s.add_dependency "mixlib-log", ">= 1.2.0"
  s.add_dependency "amqp", "~> 0.6.7"
  s.add_dependency "eventmachine", '~> 0.12.10'
  s.add_dependency "em-http-request", "~> 0.2.11"
  s.add_dependency 'yajl-ruby', "~> 1.0"
  s.add_dependency 'uuidtools', "~> 2.1.1"
  s.add_dependency 'bunny', '~> 0.6.0'
  s.add_dependency 'fast_xs', "~> 0.7.3"
  s.add_dependency 'highline', '~> 1.6.1'

  %w(rake rspec-core rspec-expectations rspec-mocks).each { |gem| s.add_development_dependency gem }

  s.bindir       = "bin"
  s.executables  = %w( chef-expander chef-expander-vnode chef-expanderctl )
  s.require_path = 'lib'
  s.files = %w(LICENSE README.rdoc) + Dir.glob("{scripts,conf,lib}/**/*")
end
