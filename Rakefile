require 'rspec/core/rake_task'

ROOT = File.expand_path(File.dirname(__FILE__))

desc "Run all specs in spec directory"
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = FileList['spec/**/*_spec.rb']
end

task :default => :spec