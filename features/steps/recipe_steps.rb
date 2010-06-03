Given /^the cookbook has a '(.+)' named '(.+)' in the '(.+)' specific directory$/ do |file_type, filename, specificity|
  cookbook_name, recipe_name = recipe.split('::')
  type_dir = file_type == 'file' ? 'files' : 'templates'
  specific_dir = nil
  case specificity
  when "host"
    specific_dir = "host-#{client.node[:fqdn]}"
  when "platform-version"
    specific_dir = "#{client.node[:platform]}-#{client.node[:platform_version]}"
  when "platform"
    specific_dir = client.node[:platform]
  when "default"
    specific_dir = "default"
  end
  new_file_dir = File.expand_path(File.dirname(__FILE__) + "/../data/cookbooks/#{cookbook_name}/#{type_dir}/#{specific_dir}")
  cleanup_dirs << new_file_dir unless new_file_dir =~ /default$/
  system("mkdir -p #{new_file_dir}")
  new_file_name = File.join(new_file_dir, filename)
  cleanup_files << new_file_name
  new_file = File.open(new_file_name, "w")
  new_file.puts(specificity)
  new_file.close
end
