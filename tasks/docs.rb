RESOURCES_TO_SKIP = ["whyrun_safe_ruby_block", "l_w_r_p_base", "user_resource_abstract_base_class", "linux_user", "pw_user", "aix_user", "solaris_user", "windows_user", "mac_user", ""].freeze

namespace :docs_site do

  desc "Generate resource documentation pages in a docs_site directory"

  task :resources do
    Encoding.default_external = Encoding::UTF_8

    $:.unshift(File.expand_path(File.join(__dir__, "lib")))

    require "chef/resource_inspector"
    require "fileutils"
    require "yaml"

    # @return [String, nil] a pretty default value string or nil if we want to skip it
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
        next if p["name"] == "sensitive" # we don't need to document sensitive twice

        pretty_default = pretty_default(p["default"])

        text << "  #{p["name"].ljust(padding_size)}"
        text << friendly_types_list(p["is"])
        text << " # default value: 'name' unless specified" if p["name_property"]
        text << " # default value: #{pretty_default}" unless pretty_default.nil? || (pretty_default.is_a?(String) && pretty_default.length > 45) # 45 chars is too long for these example blocks
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
      prop_list = [
        "`#{name}` is the resource.",
        "`name` is the name given to the resource block.",
        "`action` identifies which steps Chef Infra Client will take to bring the node into the desired state.",
      ]

      # handle the case where we have no properties
      prop_list << friendly_property_list(properties) unless properties.empty?

      prop_list
    end

    # given an array of properties print out a single comma separated string
    # handling commas and plural vs. singular wording depending
    # on the number of properties
    # @return String
    def friendly_property_list(arr)
      return nil if arr.empty? # resources w/o properties

      props = arr.map { |x| "`#{x["name"]}`" }

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
    # handling TrueClass/FalseClass which needs to be "true" and "false"
    # and removing any nil values since those are less types in properties
    # and more side effects of legacy design
    # @return String
    # @todo still does not include nil (?)
    def friendly_types_list(arr)
      fixed_arr = Array(arr).map do |x|
        case x
        when "TrueClass"
          "true"
        when "FalseClass"
          "false"
        when "NilClass"
          nil
        else
          x
        end
      end
      # compact to remove the nil values
      fixed_arr.compact.join(", ")
    end

    # print out the human readable form of the default
    def friendly_default_value(property)
      return "The resource block's name" if property["name_property"]

      return nil if property["default"].nil? || property["default"] == ""

      # this way we properly print out a string of a hash or an array instead of just the values
      property["default"].to_s
    end

    #
    # Build the actions section of the resource yaml
    # as a hash of actions to markdown descriptions.
    #
    # @return [Hash]
    #
    def action_list(actions, default_action)
      actions = actions.map { |k, v| [k.to_sym, { "markdown" => k == default_action.first ? "#{v} (default)" : v } ] }.to_h
      actions[:nothing] = { "shortcode" => "resources_common_actions_nothing.md" }
      actions
    end

    # @todo what to do about "lazy default" for default?
    def properties_list(properties)
      properties.filter_map do |property|
        next if property["name"] == "sensitive" # we don't need to document sensitive twice

        default_val = friendly_default_value(property)

        values = {}
        values["property"] = property["name"]
        values["ruby_type"] = friendly_types_list(property["is"])
        values["required"] = !!property["required"] # right now we just want a boolean value here since the docs doesn't know what to do with an array of actions
        values["default_value"] = default_val unless default_val.nil?
        values["new_in"] = property["introduced"] unless property["introduced"].nil?
        values["allowed_values"] = property["equal_to"].join(", ") unless property["equal_to"].empty?
        values["description_list"] = split_description_values(property["description"])
        values
      end
    end

    def special_properties(name)
      properties = {}

      # these package properties support passing arrays for the package name
      properties["multi_package_resource"] = true if %w{snap_package dpkg_package yum_package apt_package zypper_package homebrew_package dnf_package pacman_package homebrew_package}.include?(name)

      properties["common_resource_functionality_resources_common_windows_security"] = true if name == "remote_directory"

      properties["cookbook_file_specificity"] = true if name == "cookbook_file"

      properties["debug_recipes_chef_shell"] = true if name == "breakpoint"

      properties["handler_custom"] = true if name == "chef_handler"

      properties["handler_types"] = true if name == "chef_handler"

      properties["nameless_apt_update"] = true if name == "apt_update"

      properties["nameless_build_essential"] = true if name == "build_essential"

      properties["properties_resources_common_windows_security"] = true if %w{cookbook_file file template remote_file directory}.include?(name)

      properties["properties_shortcode"] = "resource_log_properties.md" if name == "log"

      properties["ps_credential_helper"] = true if name == "dsc_script"

      properties["registry_key"] = true if name == "registry_key"

      properties["remote_directory_recursive_directories"] = true if name == "remote_directory"

      properties["remote_file_prevent_re_downloads"] =  true if name == "remote_file"

      properties["remote_file_unc_path"] = true if name == "remote_file"

      properties["resource_directory_recursive_directories"] = true if %w{directory remote_directory}.include?(name)

      properties["resource_package_options"] = true if name == "package"

      properties["resources_common_atomic_update"] = true if %w{cookbook_file file template remote_file}.include?(name)

      properties["resources_common_guard_interpreter"] = true if name == "script"

      properties["resources_common_guards"] = true unless %w{ruby_block chef_acl chef_environment chef_data_bag chef_mirror chef_container chef_client chef_organization remote_file chef_node chef_group breakpoint chef_role registry_key chef_data_bag_item chef_user package}.include?(name)

      properties["resources_common_notification"] = true unless %w{ruby_block chef_acl python chef_environment chef_data_bag chef_mirror perl chef_container chef_client chef_organization remote_file chef_node chef_group breakpoint chef_role registry_key chef_data_bag_item chef_user ruby package}.include?(name)

      properties["resources_common_properties"] = true unless %w{ruby_block chef_acl python chef_environment chef_data_bag chef_mirror perl chef_container chef_client chef_organization remote_file chef_node chef_group breakpoint chef_role registry_key chef_data_bag_item chef_user ruby package}.include?(name)

      properties["ruby_style_basics_chef_log"] = true if name == "log"

      properties["syntax_shortcode"] = "resource_log_syntax.md" if name == "log"

      properties["template_requirements"] = true if name == "template"

      properties["unit_file_verification"] = true if name == "systemd_unit"

      properties
    end

    # Breaks a block of text into the different sections expected for the description,
    # using the markers "Note:" for "note" sections and "Warning:" for "warning" sections.
    # TODO: has the limitation that the plain description section is assumed to come first,
    # and is followed by one or more "note"s or "warning"s sections.
    def split_description_values(text)
      return [{ "markdown" => nil }] if text.nil?

      description_pattern = /(Note:|Warning:)?((?:(?!Note:|Warning:).)*)/m

      description = []

      text.scan(description_pattern) do |preface, body|
        body.strip!
        next if body.empty?

        element = { "markdown" => body }

        case preface
        when "Note:"
          description << { "note" => element }
        when "Warning:"
          description << { "warning" => element }
        when nil
          description << element
        else
          raise "Unexpected thing happened! preface: '#{preface}', body: '#{body}'"
        end
      end

      description
    end

    # takes the resource description text, splits out warning/note fields and then adds multipackage based notes when appropriate
    def build_resource_description(name, text)
      description = split_description_values(text)

      # if we're on a package resource, depending on the OS we want to inject a warning / note that you can just use 'package' instead
      description << { "notes_resource_based_on_package" => true } if %w{apt_package bff_package dnf_package homebrew_package ips_package openbsd_package pacman_package portage_package smartos_package windows_package yum_package zypper_package pacman_package freebsd_package}.include?(name)

      description
    end

    # the main method that builds what will become the yaml file
    def build_resource_data(name, data)
      properties = data["properties"].reject { |v| v["name"] == "name" || v["deprecated"] }.sort_by! { |v| v["name"] }

      r = {}

      # We want all our resources to show up in the main resource reference page
      r["resource_reference"] = true

      # These properties are set to special values for only a few resources.
      r.merge!(special_properties(name))

      r["resource"] = name
      r["resource_description_list"] = build_resource_description(name, data["description"])
      r["resource_new_in"] = data["introduced"] unless data["introduced"].nil?
      r["syntax_full_code_block"] = generate_resource_block(name, properties, data["default_action"])
      r["syntax_properties_list"] = nil
      r["syntax_full_properties_list"] = friendly_full_property_list(name, properties)
      r["actions_list"] = action_list(data["actions"], data["default_action"] )
      r["properties_list"] = properties_list(properties)
      r["examples"] = data["examples"]

      r
    end

    FileUtils.mkdir_p "docs_site"
    resources = Chef::JSONCompat.parse(Chef::ResourceInspector.inspect)

    resources.each do |resource, data|
      # skip some resources we don't directly document
      next if RESOURCES_TO_SKIP.include?(resource)

      next if ENV["DEBUG"] && !(resource == ENV["DEBUG"])

      resource_data = build_resource_data(resource, data)

      if ENV["DEBUG"]
        require "pp"
        pp resource
        puts "=========="
        pp data
        puts "=========="
        pp resource_data
      else
        puts "Writing out #{resource}."
        File.open("docs_site/#{resource}.yaml", "w") { |f| f.write(YAML.dump(resource_data)) }
      end
    end
  end
end
