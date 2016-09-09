

pkgs = %w{lsof tcpdump strace zsh dmidecode ltrace bc curl wget telnet subversion git traceroute htop tmux s3cmd sysbench }

# this deliberately calls the multipackage API N times in order to do one package installation in order to exercise the
# multipackage cookbook.
pkgs.each do |pkg|
  multipackage pkgs
end

gems = %w{fpm aws-sdk}

gems.each do |gem|
  chef_gem gem do
    compile_time false
  end
end
