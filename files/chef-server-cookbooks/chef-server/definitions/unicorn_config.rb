#
# Copyright:: Copyright (c) 2012 Opscode, Inc.
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

define :unicorn_config, :listen => nil, :working_directory => nil, :worker_timeout => 60, :preload_app => false, :worker_processes => 4, :before_fork => nil, :after_fork => nil, :pid => nil, :stderr_path => nil, :stdout_path => nil, :notifies => nil, :owner => nil, :group => nil, :mode => nil do
  config_dir = File.dirname(params[:name])

  directory config_dir do
    recursive true
    action :create
  end

  tvars = params.clone
  params[:listen].each do |port, options|
    oarray = Array.new
    options.each do |k, v|
      oarray << ":#{k} => #{v}"
    end
    tvars[:listen][port] = oarray.join(", ")
  end

  template params[:name] do
    source "unicorn.rb.erb"
    mode "0644"
    owner params[:owner] if params[:owner]
    group params[:group] if params[:group]
    mode params[:mode]   if params[:mode]
    variables params
    notifies *params[:notifies] if params[:notifies]
  end

end
