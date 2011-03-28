# This is kind of a crazy-ass setup, but it works.
When /^I run chef-solo with the '(.+)' recipe$/ do |recipe_name|
  # Set up the JSON file with the recipe we want to run.
  dna_file = "#{tmpdir}/chef-solo-features-dna.json"
  File.open(dna_file, "w") do |fp|
    fp.write("{ \"run_list\": [\"#{recipe_name}\"] }")
  end

  cleanup_files << "#{tmpdir}/chef-solo-features-dna.json"

  # Set up the cache dir.
  cache_dir = "#{tmpdir}/chef-solo-cache-features"
  system("mkdir -p #{cache_dir}")
  cleanup_dirs << cache_dir 

  # Cookbook dir
  cookbook_dir ||= File.expand_path(File.join(File.dirname(__FILE__), '..', 'data', 'cookbooks'))
  system("cp -r #{cookbook_dir} #{cache_dir}")

  # Config file
  config_file = "#{tmpdir}/chef-solo-config-features.rb"
  File.open(config_file, "w") do |fp|
    fp.write("cookbook_path \"#{cache_dir}/cookbooks\"\n")
    fp.write("file_cache_path \"#{cache_dir}/cookbooks\"\n")
  end
  cleanup_files << config_file

  binary_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'chef', 'bin', 'chef-solo'))
  command = "#{binary_path} -c #{config_file} -j #{dna_file}"
  command += " -l debug" if Chef::Log.debug?

  # Run it
  puts "Running solo: #{command}" if Chef::Log.debug?

  status = Chef::Mixin::Command.popen4(command) do |p, i, o, e|
    @stdout = o.gets(nil)
    @stderr = o.gets(nil)
  end
  @status = status

  print_output if Chef::Log.debug?
end


# This is kind of a crazy-ass setup, but it works.
When /^I run chef-solo without cookbooks$/ do

  # Set up the cache dir.
  cache_dir = "#{tmpdir}/chef-solo-cache-features"
  system("mkdir -p #{cache_dir}")
  cleanup_dirs << cache_dir 

  # Empty Cookbook dir
  system("mkdir #{cache_dir}/cookbooks")

  # Config file
  config_file = "#{tmpdir}/chef-solo-config-features.rb"
  File.open(config_file, "w") do |fp|
    fp.write("cookbook_path \"#{cache_dir}/cookbooks\"\n")
    fp.write("file_cache_path \"#{cache_dir}/cookbooks\"\n")
  end
  cleanup_files << config_file

  binary_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'chef', 'bin', 'chef-solo'))
  command = "#{binary_path} -c #{config_file}"
  command += " -l debug" if ENV['LOG_LEVEL'] == 'debug'

  # Run it
  puts "Running solo: #{command}" if ENV['LOG_LEVEL'] == 'debug'

  status = Chef::Mixin::Command.popen4(command) do |p, i, o, e|
    @stdout = o.gets(nil)
    @stderr = o.gets(nil)
  end
  @status = status

  print_output if ENV['LOG_LEVEL'] == 'debug'
end
