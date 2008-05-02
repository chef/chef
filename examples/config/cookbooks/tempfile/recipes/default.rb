
  file "/tmp/glen" do
    owner  "adam"
    mode   0755
    action "create"
  end

  directory "/tmp/marginal" do
    owner "adam"
    mode 0755
    action :create
  end

