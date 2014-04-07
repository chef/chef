require 'spec_helper'
require 'chef/node'
require 'chef/node/attribute'
require 'chef_zero/server'
require 'tmpdir'

module AttributeTracingHelpers
  FIXTURES = {
    :roles => {
      :alpha => {
        'default_attributes' => { 'role_default' => 'role_default', },
        'override_attributes' => { 'role_override' => 'role_override', },                                      
      }
    },

    :environments => {
      :pure_land => {
        'name' => 'pure_land',
        'default_attributes' => { 'env_default' => 'env_default', },
        'override_attributes' => { 'env_override' => 'env_override', },        
      }
    },

    :cookbooks => {
      'bloodsmasher-0.1.1' => {
        'recipes' => { 'default.rb' => '# Time to smash blood!' },
        'attributes' => {
          'default.rb' => <<-EOT,
# Andy, did you hear about this one?
default[:goofin][:on][:elvis] = 'Hey, Baby!'
EOT

          'hideous.rb' => <<-EOT,




override[:goofin][:on][:elvis] = 'No particular expertise in poultry managment is meant to be implied, here.'
EOT
        },
        'metadata.rb' => 'version "0.1.1"',
      },
      'bloodsmasher-0.2.0' => {
        'recipes' => { 'default.rb' => '# Time to smash blood!' },
        'attributes' => {
          'default.rb' => <<-EOT,
# Andy, did you hear about this one?
default[:goofin][:on][:elvis] = 'Hey, Baby!'

default[:are][:we][:having][:fun] \
  = 'Probably'
EOT
        },
        'metadata.rb' => 'version "0.2.0"',
      },
      # AttributeTracingHelpers.canned_fixtures[:cookbooks]['burgers-0.1.0'] },
      'burgers-0.1.7' => {
        'metadata.rb' => 'version "0.1.7"',
        'attributes' => {
          'default.rb' => <<-EOT,
default['lim'] = 'tasty'
EOT
        },
        'recipes' => {
          'default.rb' => <<-EOT,

node.normal['ham']['mustard'] = true

ruby_block "Set an attr at converge time" do
  block do 
    node.normal['ham']['relish'] = true
  end
end

# Set lim burger to not be tasty (overwriting attributes)
node.default['lim'] = 'yecchy'

# Reload attributes 
ruby_block 'Reload an attribute file at converge time' do
  block do
    node.from_file(run_context.resolve_attribute("burgers", "default"))
  end
end

include_recipe('burgers::kansas')

EOT
          'kansas.rb' => <<-EOT,
# In Kansas City, we put coleslaw on everything.
node.normal['ham']['cole_slaw'] = true
EOT
        }
      }    
    }
  }

  def AttributeTracingHelpers.canned_fixtures
    return FIXTURES
  end
  
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

    node = nil
    Dir.mktmpdir do |tmpdir|
      config_settings_to_restore = [
                                    :chef_server_url,
                                    :node_name, 
                                    :client_key,
                                    :lockfile,
                                    :log_level,
                                    :chef_repo_path,
                                    :cache_path,
                                   ]
      orig_config = {}
      config_settings_to_restore.each { |k| orig_config[k] = Chef::Config.send(k) }
      orig_config[:ohai_disabled_plugins] = Ohai::Config[:disabled_plugins].dup

      Chef::Config.chef_server_url = 'http://localhost:19090'
      Chef::Config.node_name = fixtures['fqdn']
      Chef::Config.client_key = client_key.path
      Chef::Config.client_fork = false
      Chef::Config.lockfile = tmpdir + '/client-lockfile'
      Chef::Config.log_level = :debug
      Chef::Config.chef_repo_path = tmpdir
      Chef::Config.cache_path = tmpdir
      
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

        # Load any referenced cookbooks into chef-zero
        if fixtures['cookbooks'] 
          server.load_data("cookbooks" => fixtures['cookbooks']) 
        end

        # Create a client object and do the run
        run_client = Chef::Client.new
        run_client.run
        node = run_client.node

      ensure
        server.stop

        # Reset config
        Ohai::Config[:disabled_plugins] = orig_config[:ohai_disabled_plugins]
        config_settings_to_restore.each { |k| Chef::Config.send((k.to_s + '=').to_sym, orig_config[k]) }
        
      end # Exception handling for chef-zero

    end # tmpdir

    return node

  end

end


