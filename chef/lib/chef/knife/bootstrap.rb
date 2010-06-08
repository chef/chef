#
# Author:: Adam Jacob (<adam@opscode.com>)
# Copyright:: Copyright (c) 2010 Opscode, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/knife'
require 'json'
require 'tempfile'

class Chef
  class Knife
    class Bootstrap < Knife

      banner "Sub-Command: knife bootstrap FQDN [RUN LIST...] (options)"

      option :ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :default => "root" 

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node"

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems"


      def h
        @highline ||= HighLine.new
      end

      def run 
        require 'highline'

        server_name = @name_args[0]

        puts "Bootstrapping Chef on #{h.color(server_name, :bold)}"

        $stdout.sync = true

        command =  <<EOH
bash -c '
if [ ! -f /usr/bin/chef-client ]; then
  apt-get update
  apt-get install -y ruby ruby1.8-dev build-essential wget libruby-extras libruby1.8-extras
  cd /tmp
  wget http://rubyforge.org/frs/download.php/69365/rubygems-1.3.6.tgz
  tar xvf rubygems-1.3.6.tgz
  cd rubygems-1.3.6
  ruby setup.rb
  cp /usr/bin/gem1.8 /usr/bin/gem
  gem install ohai chef --no-rdoc --no-ri --verbose #{"--prerelease" if config[:prerelease]}
fi

mkdir -p /etc/chef

(
cat <<'EOP'
#{IO.read(Chef::Config[:validation_key])}
EOP
) > /tmp/validation.pem
awk NF /tmp/validation.pem > /etc/chef/validation.pem
rm /tmp/validation.pem

(
cat <<'EOP'
log_level        :info
log_location     STDOUT
chef_server_url  "#{Chef::Config[:chef_server_url]}" 
validation_client_name "#{Chef::Config[:validation_client_name]}"
#{config[:chef_node_name] == nil ? "# Using default node name" : "node_name \"#{config[:chef_node_name]}\""} 
EOP
) > /etc/chef/client.rb

(
cat <<'EOP'
#{{ "run_list" => @name_args[1..-1] }.to_json}
EOP
) > /etc/chef/first-boot.json

/usr/bin/chef-client -j /etc/chef/first-boot.json'
EOH

        ssh = Chef::Knife::Ssh.new
        ssh.name_args = [ server_name, "sudo #{command}" ]
        ssh.config[:ssh_user] = config[:ssh_user] 
        ssh.config[:password] = config[:ssh_password]
        ssh.config[:manual] = true

        begin
          ssh.run
        rescue Net::SSH::AuthenticationFailed
          unless config[:ssh_password]
            puts "Failed to authenticate #{config[:ssh_user]} - trying password auth"
            ssh = Chef::Knife::Ssh.new
            ssh.name_args = [ server_name, "sudo #{command}" ]
            ssh.config[:ssh_user] = config[:ssh_user] 
            ssh.config[:manual] = true
            ssh.config[:password] = ssh.get_password
            ssh.run
          end
        end

      end
    end
  end
end

