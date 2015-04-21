require 'rspec/core/rake_task'
require 'rubygems/package_task'
require 'mixlib/shellout/version'

Dir[File.expand_path("../*gemspec", __FILE__)].reverse.each do |gemspec_path|
  gemspec = eval(IO.read(gemspec_path))
  Gem::PackageTask.new(gemspec).define
end

desc "Run all specs in spec directory"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = FileList['spec/**/*_spec.rb']
end

desc "Build it and ship it"
task ship: [:clobber_package, :gem] do
  sh("git tag #{Mixlib::ShellOut::VERSION}")
  sh("git push opscode --tags")
  Dir[File.expand_path("../pkg/*.gem", __FILE__)].reverse.each do |built_gem|
    sh("gem push #{built_gem}")
  end
end

task default: :spec
