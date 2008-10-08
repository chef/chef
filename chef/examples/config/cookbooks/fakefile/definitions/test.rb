define :monkey, :eats => "bananna" do  
  file "/tmp/monkeynews-#{params[:name]}" do
    owner "root"
    mode 0644
    action :create
  end
  
  file "/tmp/monkeynews-#{params[:name]}-second-#{params[:eats]}" do
    owner "root"
    mode 0644
    notifies :touch, resources(:file => "/tmp/monkeynews-#{params[:name]}"), :immediately
  end 
end