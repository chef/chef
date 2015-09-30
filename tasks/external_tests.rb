require 'tempfile'

def bundle_exec_with_chef(test_gem, commands)
  gem_path = Bundler.environment.specs[test_gem].first.full_gem_path
  gemfile_path = File.join(gem_path, 'Gemfile.chef-external-test')
  gemfile = File.open(gemfile_path, "w")
  begin
    IO.read(File.join(gem_path, 'Gemfile')).each_line do |line|
      if line =~ /^\s*gemspec/
        next
      elsif line =~ /^\s*gem 'chef'|\s*gem "chef"/
        next
      elsif line =~ /^\s*dev_gem\s*['"](.+)['"]\s*$/
        line = "gem '#{$1}', github: 'poise/#{$1}'"
      elsif line =~ /\s*gem\s*['"]#{test_gem}['"]/ # foodcritic
        next
      end
      gemfile.puts(line)
    end
    gemfile.puts("gem 'chef', path: #{File.expand_path('../..', __FILE__).inspect}")
    gemfile.puts("gemspec path: #{gem_path.inspect}")
    gemfile.close
    Dir.chdir(gem_path) do
      system({ 'BUNDLE_GEMFILE' => gemfile.path, 'RUBYOPT' => nil }, "bundle install")
      Array(commands).each do |command|
        system({ 'BUNDLE_GEMFILE' => gemfile.path, 'RUBYOPT' => nil }, "bundle exec #{command}")
      end
    end
  ensure
    File.delete(gemfile_path)
  end
end

EXTERNAL_PROJECTS = {
  "chef-zero"             => [ "rake spec", "rake pedant" ],
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
