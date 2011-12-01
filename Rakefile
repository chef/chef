require 'rspec/core/rake_task'
require 'rubygems/package_task'

gemspec = eval(IO.read('mixlib-shellout.gemspec'))
Gem::PackageTask.new(gemspec).define

desc "Run all specs in spec directory"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec
