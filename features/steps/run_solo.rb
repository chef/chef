# This is kind of a crazy-ass setup, but it works.
When /^I run chef-solo with the '(.+)' recipe$/ do |recipe_name|
  # Set up the JSON file with the recipe we want to run.
  dna_file = "/tmp/chef-solo-features-dna.json"
  File.open(dna_file, "w") do |fp|
    fp.write("{ \"recipes\": [\"#{recipe_name}\"] }")
  end

  # Set up the cache dir.
  cache_dir = "/tmp/chef-solo-cache-features"
  result = `rm -fr #{cache_dir}; mkdir #{cache_dir}; chmod 777 #{cache_dir}`

  # Cookbook dir
  cookbook_dir ||= File.expand_path(File.join(File.dirname(__FILE__), '..', 'data', 'cookbooks'))
  result = `ln -sf #{cookbook_dir} #{cache_dir}/cookbooks`

  # Config file
  config_file = "/tmp/chef-solo-config-features.rb"
  File.open(config_file, "w") do |fp|
    fp.write("file_cache_path \"#{cache_dir}\"\n")
  end

  binary_path = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'chef', 'bin', 'chef-solo'))
  command = "#{binary_path} -c #{config_file} -j #{dna_file}"

  # Run it
  puts "Running solo: #{command}" if ENV['LOG_LEVEL'] == 'debug'

  status = Chef::Mixin::Command.popen4(command) do |p, i, o, e|
    @stdout = o.gets(nil)
    @stderr = o.gets(nil)
  end
  @status = status

  print_output if ENV['LOG_LEVEL'] == 'debug'
end
