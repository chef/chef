namespace :docs_site do

  desc "Generate resource documentation .rst pages in a docs_site directory"

  task :resources do
    Encoding.default_external = Encoding::UTF_8

    $:.unshift(File.expand_path(File.join(File.dirname(__FILE__), "lib")))

    require "chef/resource_inspector"
    require "erb"
    require "fileutils"

    # @param version String
    # @return String Chef Infra Client or Chef Client depending on version
    def branded_chef_client_name(version)
      return "Chef Infra Client" if Gem::Version.new(version) >= Gem::Version.new("15")

      "Chef Client"
    end

    # @return [String, nil] a pretty defaul value string or nil if we want to skip it
    def pretty_default(default)
      return nil if default.nil? || default == "" || default == "lazy default"

      if default.is_a?(String)
        return default.inspect unless default[0] == ":"
      end
      default
    end

    # generate the top example resource block example text
    # @param properties Array<Hash>
    # @return String
    def generate_resource_block(resource_name, properties)
      padding_size = largest_property_name(properties) + 6

      # build the resource string with property spacing between property names and comments
      text = "  #{resource_name} 'name' do\n"
      properties.each do |p|
        text << "    #{p["name"].ljust(padding_size)}"
        text << friendly_types_list(p["is"])
        text << " # default value: 'name' unless specified" if p["name_property"]
        text << " # default value: #{pretty_default(p["default"])}" unless pretty_default(p["default"]).nil?
        text << "\n"
      end
      text << "    #{"action".ljust(padding_size)}Symbol # defaults to :#{@default_action.first} if not specified\n"
      text << "  end"
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

    # given an array of properties print out a single comma separated string
    # handling commas / and properly and plural vs. singular wording depending
    # on the number of properties
    # @return String
    def friendly_properly_list(arr)
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
    def friendly_types_list(arr)
      fixed_arr = Array(arr).map do |x|
        case x
        when "TrueClass"
          "true"
        when "FalseClass"
          "false"
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

      description.gsub( "#{name} ", "**#{name}** ").split("Note: ").first.strip
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

    def boilerplate_content
      <<~HEREDOC
        Common Resource Functionality
        =====================================================

        Chef resources include common properties, notifications, and resource guards.

        Common Properties
        -----------------------------------------------------

        .. tag resources_common_properties

        The following properties are common to every resource:

        ``ignore_failure``
          **Ruby Type:** true, false | **Default Value:** ``false``

          Continue running a recipe if a resource fails for any reason.

        ``retries``
          **Ruby Type:** Integer | **Default Value:** ``0``

          The number of attempts to catch exceptions and retry the resource.

        ``retry_delay``
          **Ruby Type:** Integer | **Default Value:** ``2``

          The retry delay (in seconds).

        ``sensitive``
          **Ruby Type:** true, false | **Default Value:** ``false``

          Ensure that sensitive resource data is not logged by Chef Infra Client.

        .. end_tag

        Notifications
        -----------------------------------------------------

        ``notifies``
          **Ruby Type:** Symbol, 'Chef::Resource[String]'

          .. tag resources_common_notification_notifies

          A resource may notify another resource to take action when its state changes. Specify a ``'resource[name]'``, the ``:action`` that resource should take, and then the ``:timer`` for that action. A resource may notify more than one resource; use a ``notifies`` statement for each resource to be notified.

          .. end_tag

        .. tag resources_common_notification_timers

        A timer specifies the point during a Chef Infra Client run at which a notification is run. The following timers are available:

        ``:before``
           Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

        ``:delayed``
           Default. Specifies that a notification should be queued up, and then executed at the end of a Chef Infra Client run.

        ``:immediate``, ``:immediately``
           Specifies that a notification should be run immediately, per resource notified.

        .. end_tag

        .. tag resources_common_notification_notifies_syntax

        The syntax for ``notifies`` is:

        .. code-block:: ruby

          notifies :action, 'resource[name]', :timer

        .. end_tag

        ``subscribes``
          **Ruby Type:** Symbol, 'Chef::Resource[String]'

        .. tag resources_common_notification_subscribes

        A resource may listen to another resource, and then take action if the state of the resource being listened to changes. Specify a ``'resource[name]'``, the ``:action`` to be taken, and then the ``:timer`` for that action.

        Note that ``subscribes`` does not apply the specified action to the resource that it listens to - for example:

        .. code-block:: ruby

         file '/etc/nginx/ssl/example.crt' do
           mode '0600'
           owner 'root'
         end

         service 'nginx' do
           subscribes :reload, 'file[/etc/nginx/ssl/example.crt]', :immediately
         end

        In this case the ``subscribes`` property reloads the ``nginx`` service whenever its certificate file, located under ``/etc/nginx/ssl/example.crt``, is updated. ``subscribes`` does not make any changes to the certificate file itself, it merely listens for a change to the file, and executes the ``:reload`` action for its resource (in this example ``nginx``) when a change is detected.

        .. end_tag

        .. tag resources_common_notification_timers

        A timer specifies the point during a Chef Infra Client run at which a notification is run. The following timers are available:

        ``:before``
           Specifies that the action on a notified resource should be run before processing the resource block in which the notification is located.

        ``:delayed``
           Default. Specifies that a notification should be queued up, and then executed at the end of a Chef Infra Client run.

        ``:immediate``, ``:immediately``
           Specifies that a notification should be run immediately, per resource notified.

        .. end_tag

        .. tag resources_common_notification_subscribes_syntax

        The syntax for ``subscribes`` is:

        .. code-block:: ruby

           subscribes :action, 'resource[name]', :timer

        .. end_tag

        Guards
        -----------------------------------------------------

        .. tag resources_common_guards

        A guard property can be used to evaluate the state of a node during the execution phase of a Chef Infra Client run. Based on the results of this evaluation, a guard property is then used to tell Chef Infra Client if it should continue executing a resource. A guard property accepts either a string value or a Ruby block value:

        * A string is executed as a shell command. If the command returns ``0``, the guard is applied. If the command returns any other value, then the guard property is not applied. String guards in a **powershell_script** run Windows PowerShell commands and may return ``true`` in addition to ``0``.
        * A block is executed as Ruby code that must return either ``true`` or ``false``. If the block returns ``true``, the guard property is applied. If the block returns ``false``, the guard property is not applied.

        A guard property is useful for ensuring that a resource is idempotent by allowing that resource to test for the desired state as it is being executed, and then if the desired state is present, for Chef Infra Client to do nothing.

        .. end_tag

        **Properties**

        .. tag resources_common_guards_properties

        The following properties can be used to define a guard that is evaluated during the execution phase of a Chef Infra Client run:

        ``not_if``
          Prevent a resource from executing when the condition returns ``true``.

        ``only_if``
          Allow a resource to execute only if the condition returns ``true``.

        .. end_tag
      HEREDOC
    end

    template = %{=====================================================
<%= @name %> resource
=====================================================
`[edit on GitHub] <https://github.com/chef/chef-web-docs/blob/master/chef_master/source/resource_<%= @name %>.rst>`__

<%= bolded_description(@name, @description) %>
<%= note_text(@description) -%>
<% unless @introduced.nil? -%>

**New in <%= branded_chef_client_name(@introduced) %> <%= @introduced %>.**
<% end -%>

Syntax
=====================================================

The <%= @name %> resource has the following syntax:

.. code-block:: ruby

<%= @resource_block %>

where:

* ``<%= @name %>`` is the resource.
* ``name`` is the name given to the resource block.
* ``action`` identifies which steps Chef Infra Client will take to bring the node into the desired state.
<% unless @property_list.nil? %>* <%= @property_list %><% end %>

Actions
=====================================================

The <%= @name %> resource has the following actions:
<% @actions.each do |a| %>
``:<%= a %>``
   <% if a == @default_action %>Default. <% end %>Description here.
<% end %>
``:nothing``
   .. tag resources_common_actions_nothing

   This resource block does not act unless notified by another resource to take action. Once notified, this resource block either runs immediately or is queued up to run at the end of a Chef Infra Client run.

   .. end_tag

Properties
=====================================================

The <%= @name %> resource has the following properties:
<% @properties.each do |p| %>
``<%= p['name'] %>``
   **Ruby Type:** <%= friendly_types_list(p['is']) %><% unless pretty_default(p['default']).nil? %> | **Default Value:** ``<%= pretty_default(p['default']) %>``<% end %><% if p['required'] %> | ``REQUIRED``<% end %><% if p['deprecated'] %> | ``DEPRECATED``<% end %><% if p['name_property'] %> | **Default Value:** ``The resource block's name``<% end %>

<% unless p['description'].nil? %>   <%= p['description'].strip %><% end %>
<% unless p['introduced'].nil? -%>\n\n   *New in <%= branded_chef_client_name(p['introduced']) %> <%= p['introduced'] -%>.*\n<% end -%>
<% end %>
<% if @properties.empty? %>This resource does not have any properties.\n<% end -%>
<%= boilerplate_content %>
Examples
=====================================================

The following examples demonstrate various approaches for using resources in recipes:

<%= @examples -%>
}

    FileUtils.mkdir_p "docs_site"
    resources = Chef::JSONCompat.parse(ResourceInspector.inspect)
    resources.each do |resource, data|
      next if ["scm", "whyrun_safe_ruby_block", "l_w_r_p_base", "user_resource_abstract_base_class", "linux_user", "pw_user", "aix_user", "dscl_user", "solaris_user", "windows_user", ""].include?(resource)

      puts "Writing out #{resource}."
      @name = resource
      @description = data["description"]
      @default_action = data["default_action"]
      @actions = (data["actions"] - ["nothing"]).sort
      @examples = data["examples"]
      @introduced = data["introduced"]
      @preview = data["preview"]
      @properties = data["properties"].reject { |v| v["name"] == "name" }.sort_by! { |v| v["name"] }
      @resource_block = generate_resource_block(resource, @properties)
      @property_list = friendly_properly_list(@properties)
      @examples = data["examples"]

      t = ERB.new(template, nil, "-")
      File.open("docs_site/resource_#{@name}.rst", "w") do |f|
        f.write t.result(binding)
      end
    end
  end
end
