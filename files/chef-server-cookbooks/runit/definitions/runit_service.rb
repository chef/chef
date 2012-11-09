#
# Cookbook Name:: runit
# Definition:: runit_service
#
# Copyright 2008-2009, Opscode, Inc.
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

define :runit_service, :directory => nil, :only_if => false, :finish_script => false, :control => [], :run_restart => true, :active_directory => nil, :init_script_template => nil, :owner => "root", :group => "root", :template_name => nil, :start_command => "start", :stop_command => "stop", :restart_command => "restart", :status_command => "status", :options => Hash.new, :env => Hash.new, :action => :enable, :down => false do

  include_recipe "runit"

  params[:directory] ||= node[:runit][:sv_dir]
  params[:active_directory] ||= node[:runit][:service_dir]
  params[:template_name] ||= params[:name]

  sv_dir_name = "#{params[:directory]}/#{params[:name]}"
  service_dir_name = "#{params[:active_directory]}/#{params[:name]}"
  params[:options].merge!(:env_dir => "#{sv_dir_name}/env") unless params[:env].empty?

  case params[:action]
  when :enable


    directory sv_dir_name do
      owner params[:owner]
      group params[:group]
      mode 0755
      action :create
    end

    directory "#{sv_dir_name}/log" do
      owner params[:owner]
      group params[:group]
      mode 0755
      action :create
    end

    directory "#{sv_dir_name}/log/main" do
      owner params[:owner]
      group params[:group]
      mode 0755
      action :create
    end

    template "#{sv_dir_name}/run" do
      owner params[:owner]
      group params[:group]
      mode 0755
      source "sv-#{params[:template_name]}-run.erb"
      cookbook params[:cookbook] if params[:cookbook]
      if params[:options].respond_to?(:has_key?)
        variables :options => params[:options]
      end
    end

    template "#{sv_dir_name}/log/run" do
      owner params[:owner]
      group params[:group]
      mode 0755
      source "sv-#{params[:template_name]}-log-run.erb"
      cookbook params[:cookbook] if params[:cookbook]
      if params[:options].respond_to?(:has_key?)
        variables :options => params[:options]
      end
    end

    if params[:down]
      file "#{sv_dir_name}/down" do
        mode "0644"
      end
    else
      file "#{sv_dir_name}/down" do
        action :delete
      end
    end

    unless params[:env].empty?
      directory "#{sv_dir_name}/env" do
        mode 0755
        action :create
      end

      params[:env].each do |var, value|
        file "#{sv_dir_name}/env/#{var}" do
          content value
        end
      end
    end

    if params[:finish_script]
      template "#{sv_dir_name}/finish" do
        owner params[:owner]
        group params[:group]
        mode 0755
        source "sv-#{params[:template_name]}-finish.erb"
        cookbook params[:cookbook] if params[:cookbook]
        if params[:options].respond_to?(:has_key?)
          variables :options => params[:options]
        end
      end
    end

    unless params[:control].empty?
      directory "#{sv_dir_name}/control" do
        owner params[:owner]
        group params[:group]
        mode 0755
        action :create
      end

      params[:control].each do |signal|
        template "#{sv_dir_name}/control/#{signal}" do
          owner params[:owner]
          group params[:group]
          mode 0755
          source "sv-#{params[:template_name]}-control-#{signal}.erb"
          cookbook params[:cookbook] if params[:cookbook]
          if params[:options].respond_to?(:has_key?)
            variables :options => params[:options]
          end
        end
      end
    end

    if params[:init_script_template]
      template "/opt/chef-server/init/#{params[:name]}" do
        owner params[:owner]
        group params[:group]
        mode 0755
        source params[:init_script_template]
        if params[:options].respond_to?(:has_key?)
          variables :options => params[:options]
        end
      end
    else
      if params[:active_directory] == node[:runit][:service_dir]
        link "/opt/chef-server/init/#{params[:name]}" do
          to node[:runit][:sv_bin]
        end
      end
    end

    unless node[:platform] == "gentoo"
      link service_dir_name do
        to sv_dir_name
      end
    end

    ruby_block "supervise_#{params[:name]}_sleep" do
      block do
        Chef::Log.debug("Waiting until named pipe #{sv_dir_name}/supervise/ok exists.")
        (1..10).each {|i| sleep 1 unless ::FileTest.pipe?("#{sv_dir_name}/supervise/ok") }
      end
      not_if { FileTest.pipe?("#{sv_dir_name}/supervise/ok") }
    end

    service params[:name] do
      control_cmd = node[:runit][:sv_bin]
      if params[:owner]
        control_cmd = "#{node[:runit][:chpst_bin]} -u #{params[:owner]} #{control_cmd}"
      end
      provider Chef::Provider::Service::Simple
      supports :restart => true, :status => true
      start_command "#{control_cmd} #{params[:start_command]} #{service_dir_name}"
      stop_command "#{control_cmd} #{params[:stop_command]} #{service_dir_name}"
      restart_command "#{control_cmd} #{params[:restart_command]} #{service_dir_name}"
      status_command "#{control_cmd} #{params[:status_command]} #{service_dir_name}"
      if params[:run_restart] && OmnibusHelper.should_notify?(params[:name])
        subscribes :restart, resources(:template => "#{sv_dir_name}/run"), :delayed
      end
      action :nothing
    end
  when :disable
    link service_dir_name do
      action :delete
    end
  end
end
