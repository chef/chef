require 'tempfile'
require 'bundler'

CURRENT_GEM_NAME = 'chef'
CURRENT_GEM_PATH = File.expand_path('../..', __FILE__)

def bundle_exec_with_chef(test_gem, commands)
  gem_path = Bundler.environment.specs[test_gem].first.full_gem_path
  gemfile_path = File.join(gem_path, "Gemfile.#{CURRENT_GEM_NAME}-external-test")
  gemfile = File.open(gemfile_path, "w")
  begin
    IO.read(File.join(gem_path, 'Gemfile')).each_line do |line|
      if line =~ /^\s*gemspec/
        next
      elsif line =~ /^\s*gem '#{CURRENT_GEM_NAME}'|\s*gem "#{CURRENT_GEM_NAME}"/
        next
      elsif line =~ /^\s*dev_gem\s*['"](.+)['"]\s*$/
        line = "gem '#{$1}', github: 'poise/#{$1}'"
      elsif line =~ /\s*gem\s*['"]#{test_gem}['"]/ # foodcritic      end
        next
      end
      gemfile.puts(line)
    end
    gemfile.puts("gem #{CURRENT_GEM_NAME.inspect}, path: #{CURRENT_GEM_PATH.inspect}")
    gemfile.puts("gemspec path: #{gem_path.inspect}")
    gemfile.close
    Dir.chdir(gem_path) do
      unless system({ 'RUBYOPT' => nil, 'GEMFILE_MOD' => nil }, "bundle install --gemfile #{gemfile_path}")
        raise "Error running bundle install --gemfile #{gemfile_path} in #{gem_path}: #{$?.exitstatus}\nGemfile:\n#{IO.read(gemfile_path)}"
      end
      Array(commands).each do |command|
        unless system({ 'BUNDLE_GEMFILE' => gemfile_path, 'RUBYOPT' => nil, 'GEMFILE_MOD' => nil }, "bundle exec #{command}")
          raise "Error running bundle exec #{command} in #{gem_path} with BUNDLE_GEMFILE=#{gemfile_path}: #{$?.exitstatus}\nGemfile:\n#{IO.read(gemfile_path)}"
        end
      end
    end
  ensure
    File.delete(gemfile_path) if File.exist?(gemfile_path)
  end
end

EXTERNAL_PROJECTS = {
  "chef-zero"             => [ "rake spec", "rake cheffs" ],
  "cheffish"              => "rake spec",
  "chef-provisioning"     => "rake spec",
  "chef-provisioning-aws" => "rake spec",
  "chef-sugar"            => "rake",
  "foodcritic"            => "rake test",
  "chefspec"              => "rake",
  "chef-rewind"           => "rake spec",
  "poise"                 => "rake spec",
  "halite"                => "rake spec"
}

task :external_specs => EXTERNAL_PROJECTS.keys.map { |g| :"#{g.sub("-","_")}_spec" }

EXTERNAL_PROJECTS.each do |test_gem, commands|
  task :"#{test_gem.gsub('-','_')}_spec" do
    bundle_exec_with_chef(test_gem, commands)
  end
end
