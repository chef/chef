
shared_context "diff disabled"  do
  before do
    @original_diff_disable = Chef::Config[:diff_disabled]
    Chef::Config[:diff_disabled] = true
  end

  after do
    Chef::Config[:diff_disabled] = @original_diff_disable
  end
end
