namespace :docs_site do

  desc "Generate resource documentation pages in a docs_site directory"

  task :resources do
    Encoding.default_external = Encoding::UTF_8

    $:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "lib")))

    require "chef/resource_inspector"
    require "fileutils"
    require "yaml"

    # @return [String, nil] a pretty defaul value string or nil if we want to skip it
    def pretty_default(default)
      return nil if default.nil? || default == "" || default == "lazy default"

      if default.is_a?(String)

        # .inspect wraps the value in quotes which we want for strings, but not sentences or symbols as strings
        return default.inspect unless default[0] == ":" || default.end_with?(".")
      end
      default
    end

    # generate the top example resource block example text
    # @param properties Array<Hash>
    # @return String
    def generate_resource_block(resource_name, properties, default_action)
      padding_size = largest_property_name(properties) + 6

      # build the resource string with property spacing between property names and comments
      text = ""
      text << "#{resource_name} 'name' do\n"
      properties.each do |p|
        text << "  #{p["name"].ljust(padding_size)}"
        text << friendly_types_list(p["is"])
        text << " # default value: 'name' unless specified" if p["name_property"]
        text << " # default value: #{pretty_default(p["default"])}" unless pretty_default(p["default"]).nil?
        text << "\n"
      end
      text << "  #{"action".ljust(padding_size)}Symbol # defaults to :#{default_action.first} if not specified\n"
      text << "end"
      text
    end

    # we need to know how much space to leave so columns line up
    # @return String
    def largest_property_name(properties)
      if properties.empty?
        6 # we'll include "action" even without properties and it's 6 chars long
      else
        properties.max_by { |x| x["name"].size }["name"].size
      end
    end

    def friendly_full_property_list(name, properties)
      [
        "`#{name}` is the resource.",
        "`name` is the name given to the resource block.",
        "`action` identifies which steps Chef Infra Client will take to bring the node into the desired state.",
        friendly_property_list(properties),
      ]
    end

    # given an array of properties print out a single comma separated string
    # handling commas and plural vs. singular wording depending
    # on the number of properties
    # @return String
    def friendly_property_list(arr)
      return nil if arr.empty? # resources w/o properties

      props = arr.map { |x| "``#{x["name"]}``" }

      # build the text string containing all properties bolded w/ punctuation
      if props.size > 1
        props[-1] = "and #{props[-1]}"
      end
      text = props.size == 2 ? props.join(" ") : props.join(", ")
      text << ( props.size > 1 ? " are the properties" : " is the property" )
      text << " available to this resource."
      text
    end

    # given an array of types print out a single comma separated string
    # handling a nil value that needs to be printed as "nil" and TrueClass/FalseClass
    # which needs to be "true" and "false"
    # @return String
    # TODO:
    # - still does not include nil (?)
    def friendly_types_list(arr)
      fixed_arr = Array(arr).map do |x|
        case x
        when "TrueClass"
          "true"
        when "FalseClass"
          "false"
        when "NilClass", nil
          "nil"
        else
          x
        end
      end
      fixed_arr.compact.join(", ")
    end

    # Makes sure the resource name is bolded within the description
    # @return String
    def bolded_description(name, description)
      return nil if description.nil? # handle resources missing descriptions

      # we only want to bold occurences of the resource name in the first 5 words so treat it as an array
      desc_array = description.split(" ")

      desc_array = desc_array[0..4].map! { |x| name == x ? "**#{x}**" : x } + desc_array[5..-1]

      # strip out notes and return just the description
      desc_array.join(" ").split("Note: ").first.strip
    end

    def note_text(description)
      return nil if description.nil?

      note = description.split("Note: ")[1]
      if note
        <<-HEREDOC

      .. note::

      #{note}
        HEREDOC
      end
    end

    # build the menu entry for this resource
    def build_menu_item(name)
      {
        "infra" => {
          "title" => name,
          "identifier" => "chef_infra/cookbook_reference/resources/#{name} #{name}",
          "parent" => 'chef_infra/cookbook_reference/resources',
          "weight" => @weight,
        }
      }
    end

    # TODO:
    # - what to do about "lazy default" for default?
    def properties_list(properties)
      properties.map do |property|
        {
          property: property["name"],
          ruby_type: friendly_types_list(property["is"]),
          required: property["required"],
          default_value: property["default"],
          new_in: property["introduced"],
          description_list: [{ markdown: property["description"] }],
        }
      end
    end

    def special_properties(name, data)
      properties = {}

      properties["common_resource_functionality_multiple_packages"] =
        case name
        when "yum_package", "apt_package"
          true
        when "package"
          nil
        else
          false
        end

      properties["common_resource_functionality_resources_common_windows_security"] = name == "remote_directory"

      properties["cookbook_file_specificity"] = name == "cookbook_file"

      properties["debug_recipes_chef_shell"] = name == "breakpoint"

      properties["handler_custom"] = name == "chef_handler"

      properties["handler_types"] = name == "chef_handler"

      properties["nameless_apt_update"] = name == "apt_update"

      properties["nameless_build_essential"] = name == "build_essential"

      properties["properties_multiple_packages"] = ["dnf_package", "package", "zypper_package"].include?(name)

      properties["properties_resources_common_windows_security"] = ["cookbook_file", "file", "template", "remote_file", "directory"].include?(name)


      properties["properties_shortcode"] =
        case name
        when "breakpoint"
          "resource_breakpoint_properties.md"
        when "ohai"
          "resource_ohai_properties.md"
        when "log"
          "resource_log_properties.md"
        else
          nil
        end

      properties["ps_credential_helper"] = name == "dsc_script"

      properties["registry_key"] = name == "registry_key"

      properties["remote_directory_recursive_directories"] = name == "remote_directory"

      properties["remote_file_prevent_re_downloads"] = name == "remote_file"

      properties["remote_file_unc_path"] = name == "remote_file"

      properties["resource_directory_recursive_directories"] = ["directory", "remote_directory"].include?(name)

      properties["resource_package_options"] = name == "package"

      properties["resources_common_atomic_update"] = ["cookbook_file", "file", "template", "remote_file"].include?(name)

      properties["resources_common_guard_interpreter"] = name == "script"

      properties["resources_common_guards"] = !["ruby_block", "chef_acl", "chef_environment", "chef_data_bag", "chef_mirror", "chef_container", "chef_client", "chef_organization", "remote_file", "chef_node", "chef_group", "breakpoint", "chef_role", "registry_key", "chef_data_bag_item", "chef_user", "package"].include?(name)

      properties["resources_common_notification"] = !["ruby_block", "chef_acl", "python", "chef_environment", "chef_data_bag", "chef_mirror", "perl", "chef_container", "chef_client", "chef_organization", "remote_file", "chef_node", "chef_group", "breakpoint", "chef_role", "registry_key", "chef_data_bag_item", "chef_user", "ruby", "package"].include?(name)

      properties["resources_common_properties"] = !["ruby_block", "chef_acl", "python", "chef_environment", "chef_data_bag", "chef_mirror", "perl", "chef_container", "chef_client", "chef_organization", "remote_file", "chef_node", "chef_group", "breakpoint", "chef_role", "registry_key", "chef_data_bag_item", "chef_user", "ruby", "package"].include?(name)

      properties["ruby_style_basics_chef_log"] = name == "log"

      properties["syntax_shortcode"] =
        case name
        when "breakpoint"
          "resource_breakpoint_syntax.md"
        when "log"
          "resource_log_syntax.md"
        else
          nil
        end

      properties["template_requirements"] = name == "template"

      properties["unit_file_verification"] = name == "systemd_unit"

      properties
    end

    # the main method that builds what will become the yaml file
    def build_resource_data(name, data)
      properties = data["properties"].reject { |v| v["name"] == "name" }.sort_by! { |v| v["name"] }

      r = {}

      # These properties are always set to these values.
      r['draft'] = false
      r['resource_reference'] = true
      r['robots'] = nil
      r['syntax_code_block'] = nil

      # These properties are set to special values for only a few resources.
      r.merge!(special_properties(name, data))

      r['title'] = "#{name} resource"
      r['resource'] = name
      r['aliases'] = ["/resource_#{name}.html"]
      r['menu'] = build_menu_item(name)
      r['resource_description_list'] = {}
      r['resource_description_list']['markdown'] = data['description']
      r['resource_new_in'] = data["introduced"]
      r['syntax_full_code_block'] = generate_resource_block(name, properties, data["default_action"])
      r['syntax_properties_list'] = nil
      r['syntax_full_properties_list'] = friendly_full_property_list(name, properties)
      r['properties_list'] = properties_list(properties)

      #require 'pry'; binding.pry
      r
    end

    FileUtils.mkdir_p "docs_site"
    resources = Chef::JSONCompat.parse(ResourceInspector.inspect)

    # sort the hash so we can generate the menu weights later
    resources = Hash[resources.sort]

    # weight is used to build the menu order. We start at 10 and increment by 10 each time
    @weight = 10

    resources.each do |resource, data|
      # skip some resources we don't directly document
      next if ["scm", "whyrun_safe_ruby_block", "l_w_r_p_base", "user_resource_abstract_base_class", "linux_user", "pw_user", "aix_user", "dscl_user", "solaris_user", "windows_user", ""].include?(resource)

      next unless resource == ENV["DEBUG"] if ENV["DEBUG"]

      resource_data = build_resource_data(resource, data)

      if ENV["DEBUG"]
        require 'pp'
        pp resource
        puts "=========="
        pp data
        puts "=========="
        pp resource_data
      else
        puts "Writing out #{resource}."
        FileUtils.mkdir_p "docs_site/#{resource}"
        File.open("docs_site/#{resource}/_index.md", "w") { |f| f.write(resource_data.to_yaml) }
      end

      @weight += 10
    end
  end
end
