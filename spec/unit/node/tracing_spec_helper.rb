require 'spec_helper'
require 'chef/node'
require 'chef/node/attribute'
require 'chef_zero/server'

module AttributeTracingHelpers

  def AttributeTracingHelpers.apply_fixture_defaults(fixtures)
    #.....
    # Provide defaults for laziness's sake
    #.....
    fixtures['fqdn'] ||= 'hostname.example.org'
    fixtures['ohai'] ||= {
      'platform' => 'centos',
      'platform_version' => '6.3',
    }
    fixtures['roles'] ||= {}
    fixtures['roles'].each do |role_name, role_opts|
      fixtures['roles'][role_name] = {
        'json_class'=> "Chef::Role",
        'chef_type'=> "role",
        'run_list'=> [],
        'default'=> {},
        'override'=> {},
      }.merge(role_opts)
    end
    fixtures['node'] = {
      'name'=> 'hostname.example.org',
      'json_class'=> "Chef::Node",
      'chef_type'=> "node",
      'run_list'=> [],
      'chef_environment'=> '_default',
      'normal'=> {}
    }.merge(fixtures['node'] || {})
    fixtures['environments'] ||= {}
    fixtures['environments'].each do |env_name, env_opts|
      fixtures['environments'][env_name] = {
        'json_class'=> "Chef::Environment",
        'chef_type'=> "environment",
        'name' => '_default',
        'run_list'=> [],
        'cookbook_versions' => {},
        'default_attributes'=> {},
        'override_attributes'=> {},
      }.merge(env_opts)
    end

  end

  def AttributeTracingHelpers.chef_zero_client_run(fixtures)
    AttributeTracingHelpers.apply_fixture_defaults(fixtures)
    
    # Start chef-zero
    server = ChefZero::Server.new(port: 19090, debug: true)
    server.start_background

    client_key = Tempfile.new(['chef_zero_client_key', '.pem'])
    client_key.write(ChefZero::PRIVATE_KEY)
    client_key.close

    old_config = {
      :chef_server_url => Chef::Config.chef_server_url,
      :node_name => Chef::Config.node_name,
      :client_key => Chef::Config.client_key,
    }

    Chef::Config.chef_server_url = 'http://localhost:19090'
    Chef::Config.node_name = fixtures['fqdn']
    Chef::Config.client_key = client_key.path
    Chef::Config.client_fork = false    # TODO reset
    Chef::Config.lockfile = '/tmp/glahh' # TODO reset
    Chef::Config.log_level = :debug  # DEBUG
    Ohai::Config[:disabled_plugins] = [
                                       :Azure,
                                       :Blockdevice,
                                       :C,
                                       :Chef,
                                       :Cloud,
                                       :Command,
                                       :Cpu,
                                       :Dmi,
                                       :Ec2,
                                       :Erlang,
                                       :Eucalyptus,
                                       :Filesystem,
                                       :Gce,
                                       :Groovy,
                                       #:Hostname,
                                       :Ipscopes,
                                       :Java,
                                       :Kernel,
                                       :Keys,
                                       :Languages,
                                       :Linode,
                                       :Lsb,
                                       :Lua,
                                       :Memory,
                                       :Mono,
                                       :Network,
                                       :Networkaddresses,
                                       :Networklisteners,
                                       :Networkroutes,
                                       :Nodejs,
                                       :Ohai,
                                       :Ohaitime,
                                       :Openstack,
                                       :Os,
                                       :Passwd,
                                       :Perl,
                                       :Php,
                                       #:Platform,
                                       :Ps,
                                       :Python,
                                       :Rackspace,
                                       :Rootgroup,
                                       :Ruby,
                                       :Sshhostkey,
                                       :Systemprofile,
                                       :Uptime,
                                       :Virtualization,
                                       :Virtualizationinfo,
                                       :Zpools,
                                      ]



    begin

      # Load any roles into chef-zero
      if fixtures['roles'] 
        server.load_data("roles" => fixtures['roles']) 
      end

      # Load any envs into chef-zero
      if fixtures['environments'] 
        server.load_data("environments" => fixtures['environments']) 
      end

      # Load node into chef-zero
      if fixtures['node'] 
        server.load_data("nodes" => { fixtures['node']['name'] => fixtures['node'] }) 
      end

      # TODO Load any referenced cookbooks into chef-zero

      # Create a client object and do the run
      run_client = Chef::Client.new
      run_client.run
      node = run_client.node

    ensure
      server.stop

      # Reset config
      Chef::Config.chef_server_url = old_config[:chef_server_url]
      Chef::Config.node_name = old_config[:node_name]
      Chef::Config.client_key = old_config[:client_key]
    end

    return node

  end

end


