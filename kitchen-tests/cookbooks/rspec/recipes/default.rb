# we're using chef-client now as a glorified way to push a file to the remote host
# if we had a way to turn off chef-client converge and push arbitrary files to the
# remote this complexity could be removed.
template "/usr/local/bin/run-chef-rspec" do
  source "run-chef-rspec"
  mode 0755
end

# do NOT even think of trying to add an execute resource here to launch rspec.
# chefception is proven to be a bad idea, and the rspec tests that really launch
# chef-client will likely break due to the outer chef-client run.  i also do not
# want to debug rspec's output being filtered through chef-client's logger -- fuck
# all of that noise.
