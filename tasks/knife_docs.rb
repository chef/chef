namespace :knife_docs do

  desc "Generate knife CLI YAML files for documentation on docs.chef.io."

  task :knife do
    puts "Generate knife CLI docs files."

    require_relative "../knife/lib/chef/application/knife"
    require "fileutils"
    require "yaml"

    # Get a hash of common options for all knife commands
    common_options = Chef::Application::Knife.options.merge

    # Put the hash in alphabetical order
    common_options = common_options.sort.to_h

    # Remove proc from hash if it exists
    common_options.each {|_,v| v.delete_if {|key, val| key == :proc}}

    # Output common_options to file
    File.open("docs-chef-io/data/knife/common_options.yaml", "w") { |f| f.write(YAML.dump(common_options)) }

    def generate_knife_doc(command)
      text = ""
    end

    def generate_common_options
      test = ""
    end

  end

end
