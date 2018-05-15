
action :test do

  ruby_block "interior-ruby-block-1" do
    block do
      # doesn't need to do anything
    end
    notifies :run, "ruby_block[interior-ruby-block-2]", :immediately
  end

  ruby_block "interior-ruby-block-2" do
    block do
      $interior_ruby_block_2 = "executed"
    end
    action :nothing
  end
end

action :no_updates do
  ruby_block "no-action" do
    block {}
    action :nothing
  end
end
