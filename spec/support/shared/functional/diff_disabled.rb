
shared_context "diff disabled"  do
  before do
    Chef::Config[:diff_disabled] = true
  end

  after do
    Chef::Config[:diff_disabled] = false
  end
end
