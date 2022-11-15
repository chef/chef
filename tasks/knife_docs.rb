namespace :knife_docs do

  desc "Generate knife CLI YAML files for documentation on docs.chef.io."

  task :knife do
    puts "Generate knife CLI docs files."

    require_relative "../knife/lib/chef/knife"

    # require everything in knife/lib/chef/knife
    Dir["knife/lib/chef/knife/**/*.rb"]
      .map { |f| f.gsub(/\Aknife\//, "../knife/") }
      .map { |f| f.gsub(/\.rb$/, "") }
      .each { |f| require_relative f }
    require "fileutils"
    require "yaml"

    def output_yaml_file(filename, data)
      File.open("docs-chef-io/data/knife/#{filename}", "w") { |f| f.write(YAML.dump(data)) }
    end

    # delete and recreate the chef/docs-chef-io/data/knife directory
    docs_data_dir = "docs-chef-io/data/knife"
    docs_knife_pages_dir = 'docs-chef-io/content/workstation'
    FileUtils.remove_dir docs_data_dir
    FileUtils.mkdir_p docs_data_dir

    ###
    ## Generate knife common options file
    ###

    # Get a hash of common options for all knife commands
    common_options = Chef::Application::Knife.options.merge

    # Put the hash in alphabetical order
    common_options = common_options.sort.to_h

    # Remove proc from hash if it exists
    common_options.each {|_,v| v.delete_if {|key, val| key == :proc}}

    # Output common_options to file
    output_yaml_file('common_options.yaml', common_options)

    ###
    ## Generate data files for each knife subcommand
    ###

    knife_classes = ObjectSpace.each_object(Class).select { |klass| klass < Chef::Knife }

    knife_classes.each do |klass|

      if klass.name == 'Chef::ChefFS::Knife'
        next
      end

      # generate filename
      filename = klass.name.gsub('Chef::Knife::', 'knife_')
      filename.gsub!(/([a-z])([A-Z])/,'\1_\2')
      filename = filename.downcase + '.yaml'

      # get subcommand data
      data = klass.options.merge
      data = data.sort.to_h
      data = {'banner': klass.banner}.merge(data)

      # Hugo can't handle the symbol output in keys
      data.transform_keys!(&:to_s)
      data.each do |key, val|
        if val.class == Hash
          val.transform_keys!(&:to_s)
        end
      end

      # output data
      output_yaml_file(filename, data)
    end

  end

end
