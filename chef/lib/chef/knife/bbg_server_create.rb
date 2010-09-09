#
# Author:: Jim Van Fleet (<jim@itsbspoke.com>)
# Copyright:: Copyright (c) 2010 it's bspoke, LLC.
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
    class BbgServerCreate < Knife

      banner "knife bbg server create NAME [RUN LIST...] (options)"

      option :bluebox_customer_id,
        :short => "-I CUSTOMER_ID",
        :long => "--blue_box_customer_id CUSTOMER_ID",
        :description => "Your BlueBox Group customer id",
        :proc => Proc.new { |id| Chef::Config[:knife][:bluebox_customer_id] = id } 

      option :bluebox_api_key,
        :short => "-K API_KEY",
        :long => "--blue_box_api_key API_KEY",
        :description => "Your BlueBox API Key",
        :proc => Proc.new { |key| Chef::Config[:knife][:bluebox_api_key] = key }

      option :product,
        :short => "-P PRODUCT",
        :long => "--product PRODUCT",
        :description => "BlueBox Product ID (e.g. 94fd37a7-2606-47f7-84d5-9000deda52ae)",
        :proc => Proc.new { |pid| Chef::Config[:knife][:product] = pid }

      option :template,
        :short => "-T TEMPLATE",
        :long => "--template TEMPLATE",
        :description => "BlueBox Template ID (e.g. c66b8145-f768-45ef-9878-395bf8b1b7ff)",
        :proc => Proc.new { |tmpl| Chef::Config[:knife][:template] = tmpl }
        
      option :ssh_key,
        :short => "-I SSH_PUBLIC_KEY",
        :long => "--ssh_public_key SSH_PUBLIC_KEY",
        :description => "Your SSH public key",
        :proc => Proc.new { |pubkey| Chef::Config[:knife][:ssh_key] = pubkey }
        

      def h
        @highline ||= HighLine.new
      end

      def run 
        require 'fog'
        require 'highline'
        require 'net/ssh/multi'
        require 'readline'
        require 'net/scp'

        server_name = @name_args[0]

        bbg = Fog::Bluebox.new(
          :bluebox_api_key => Chef::Config[:knife][:bluebox_api_key],
          :bluebox_customer_id => Chef::Config[:knife][:bluebox_customer_id]
        )

        $stdout.sync = true

        puts "Instantiating box #{h.color(server_name, :bold)}"
        box = bbg.servers.new(:flavor_id => Chef::Config[:knife][:product], 
                              :image_id => Chef::Config[:knife][:template],
                              :ssh_key => Chef::Config[:knife][:ssh_key])
                              
        puts "\nProvisioning at BlueBox:"
        box.save

        public_ip = box.ips.first["address"]
        puts "\nBootstrapping (#{public_ip}) #{h.color(server_name, :bold)}..."        

        command =  <<EOH
bash -c '
echo nameserver 208.67.222.222 > /etc/resolv.conf
echo nameserver 208.67.220.220 >> /etc/resolv.conf

if [ ! -f /usr/bin/chef-client ]; then
  apt-get update
  apt-get install -y ruby ruby1.8-dev build-essential wget libruby-extras libruby1.8-extras
  cd /tmp
  wget http://rubyforge.org/frs/download.php/69365/rubygems-1.3.6.tgz
  tar xvf rubygems-1.3.6.tgz
  cd rubygems-1.3.6
  ruby setup.rb
  cp /usr/bin/gem1.8 /usr/bin/gem
  gem install chef ohai --no-rdoc --no-ri --verbose
fi

mkdir -p /etc/chef

(
cat <<'EOP'
#{IO.read(Chef::Config[:validation_key])}
EOP
) > /etc/chef/validation.pem

(
cat <<'EOP'
log_level        :info
log_location     STDOUT
chef_server_url  "#{Chef::Config[:chef_server_url]}" 
validation_client_name "#{Chef::Config[:validation_client_name]}"
EOP
) > /etc/chef/client.rb

(
cat <<'EOP'
#{{ "run_list" => @name_args[1..-1] }.to_json}
EOP
) > /etc/chef/first-boot.json

/usr/bin/chef-client -j /etc/chef/first-boot.json'
EOH

        begin
          Net::SSH.start(public_ip, "deploy") do |ssh|
            # capture all stderr and stdout output from a remote process
            puts "Beginning bootstrap..."
            ssh.exec!(command)
          end
        rescue Errno::ETIMEDOUT
          puts "Timed out on bootstrap, re-trying. Hit CTRL-C to abort."
          retry
        end

      end
    end
  end
end
