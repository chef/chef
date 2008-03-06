require 'rubygems'
require 'rake'
require 'spec/rake/spectask'

desc "Run all examples"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList[File.join(File.dirname(__FILE__), "..", "spec", "**", "*.rb")]
end
