task :chef_sugar_spec do
  gem_path = Bundler.environment.specs['chef-sugar'].first.full_gem_path
  system("cd #{gem_path} && rake")
end

task :foodcritic_spec do
  gem_path = Bundler.environment.specs['foodcritic'].first.full_gem_path
  system("cd #{gem_path} && rake test")
end

task :chefspec_spec do
  gem_path = Bundler.environment.specs['chefspec'].first.full_gem_path
  system("cd #{gem_path} && rake")
end

task :chef_rewind_spec do
  gem_path = Bundler.environment.specs['chef-rewind'].first.full_gem_path
  system("cd #{gem_path} && rake spec")
end

task :poise_spec do
  gem_path = Bundler.environment.specs['poise'].first.full_gem_path
  system("cd #{gem_path} && rake spec")
end

task :halite_spec do
  gem_path = Bundler.environment.specs['halite'].first.full_gem_path
  system("cd #{gem_path} && rake spec")
end
