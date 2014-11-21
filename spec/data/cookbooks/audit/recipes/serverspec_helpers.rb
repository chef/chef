# Serverspec helper `cgroup` should only be defined in controls block, not Chef::Recipe

controls "cgroup controls" do
  describe cgroup('group1') do
    true
  end
end

cgroup('group2')
