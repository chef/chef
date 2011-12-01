$:.unshift(File.dirname(__FILE__) + '/lib')
require 'mixlib/shellout/version'

Gem::Specification.new do |s|
  s.name = 'mixlib-shellout'
  s.version = Mixlib::Shellout::VERSION
  s.platform = Gem::Platform::RUBY
  s.has_rdoc = true
  s.extra_rdoc_files = ["README.md", "LICENSE" ]
  s.summary = "Run external commands on Unix or Windows"
  s.description = s.summary
  s.author = "Opscode"
  s.email = "info@opscode.com"
  s.homepage = "http://wiki.opscode.com/"


  %w(rspec-core rspec-expectations rspec-mocks).each { |gem| s.add_development_dependency gem }

  s.bindir       = "bin"
  s.executables  = []
  s.require_path = 'lib'
  s.files = %w(LICENSE README.rdoc) + Dir.glob("lib/**/*")
end
