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
