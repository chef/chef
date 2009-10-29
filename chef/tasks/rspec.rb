require 'rubygems'
require 'rake'
require 'spec/rake/spectask'

CHEF_ROOT = File.join(File.dirname(__FILE__), "..")

task :default => :spec

desc "Run all specs in spec directory"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts = ['--format', 'specdoc', '--options', "\"#{CHEF_ROOT}/spec/spec.opts\""]
  t.spec_files = FileList['spec/**/*_spec.rb']
end

namespace :spec do
  desc "Run all specs in spec directory with RCov"
  Spec::Rake::SpecTask.new(:rcov) do |t|
    t.spec_opts = ['--options', "\"#{CHEF_ROOT}/spec/spec.opts\""]
    t.spec_files = FileList['spec/**/*_spec.rb']
    t.rcov = true
    t.rcov_opts = lambda do
      IO.readlines("#{CHEF_ROOT}/spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
    end
  end
  
  desc "Print Specdoc for all specs"
  Spec::Rake::SpecTask.new(:doc) do |t|
    t.spec_opts = ["--format", "specdoc", "--dry-run"]
    t.spec_files = FileList['spec/**/*_spec.rb']
  end

  [:unit].each do |sub|
    desc "Run the specs under spec/#{sub}"
    Spec::Rake::SpecTask.new(sub) do |t|
      t.spec_opts = ['--options', "\"#{CHEF_ROOT}/spec/spec.opts\""]
      t.spec_files = FileList["spec/#{sub}/**/*_spec.rb"]
    end
  end
  
  desc "Translate/upgrade specs using the built-in translator"
  task :translate do
    translator = ::Spec::Translator.new
    dir = CHEF_ROOT + '/spec'
    translator.translate(dir, dir)
  end
end
