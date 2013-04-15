# -*- mode: ruby -*-
# vi: set ft=ruby :

host_project_path = File.expand_path("..", __FILE__)
guest_project_path = "/home/vagrant/#{File.basename(host_project_path)}"
project_name = "chef"

Vagrant.configure("2") do |config|

  config.vm.hostname = "#{project_name}-omnibus-build-lab"

  config.vm.define 'ubuntu-10.04' do |c|
    c.vm.box = "opscode-ubuntu-10.04"
    c.vm.box_url = "http://opscode-vm.s3.amazonaws.com/vagrant/opscode_ubuntu-10.04_chef-11.2.0.box"
  end

  config.vm.define 'ubuntu-11.04' do |c|
    c.vm.box = "opscode-ubuntu-11.04"
    c.vm.box_url = "http://opscode-vm.s3.amazonaws.com/vagrant/boxes/opscode-ubuntu-11.04.box"
  end

  config.vm.define 'ubuntu-12.04' do |c|
    c.vm.box = "canonical-ubuntu-12.04"
    c.vm.box_url = "http://cloud-images.ubuntu.com/vagrant/precise/current/precise-server-cloudimg-amd64-vagrant-disk1.box"
  end

  config.vm.define 'centos-5' do |c|
    c.vm.box = "opscode-centos-5.8"
    c.vm.box_url = "http://opscode-vm.s3.amazonaws.com/vagrant/opscode_centos-5.8_chef-11.2.0.box"
  end

  config.vm.define 'centos-6' do |c|
    c.vm.box = "opscode-centos-6.3"
    c.vm.box_url = "http://opscode-vm.s3.amazonaws.com/vagrant/opscode_centos-6.3_chef-11.2.0.box"
  end

  config.vm.provider :virtualbox do |vb|
    # Give enough horsepower to build without taking all day.
    vb.customize [
      "modifyvm", :id,
      "--memory", "1536",
      "--cpus", "2"
    ]
  end

  # Ensure a recent version of the Chef Omnibus packages are installed
  config.omnibus.chef_version = "11.4.0"

  # Enable the berkshelf-vagrant plugin
  config.berkshelf.enabled = true
  # The path to the Berksfile to use with Vagrant Berkshelf
  config.berkshelf.berksfile_path = "./Berksfile"

  config.ssh.max_tries = 40
  config.ssh.timeout   = 120
  config.ssh.forward_agent = true

  host_project_path = File.expand_path("..", __FILE__)
  guest_project_path = "/home/vagrant/#{File.basename(host_project_path)}"

  config.vm.synced_folder host_project_path, guest_project_path

  # prepare VM to be an Omnibus builder
  config.vm.provision :chef_solo do |chef|
    chef.json = {
      "omnibus" => {
        "build_user" => "vagrant",
        "build_dir" => guest_project_path,
        "install_dir" => "/opt/#{project_name}"
      }
    }

    chef.run_list = [
      "recipe[omnibus::default]"
    ]
  end

  # We have to nuke any chef omnibus packages (used during provisioning) before
  # we build new chef omnibus packages!
  config.vm.provision :shell, :inline => <<-REMOVE_OMNIBUS
    if command -v dpkg &>/dev/null;
    then
      sudo dpkg -P #{project_name} || true
    else
      sudo rpm -ev #{project_name} || true
    fi
  REMOVE_OMNIBUS

  config.vm.provision :shell, :inline => <<-OMNIBUS_BUILD
    sudo mkdir -p /opt/#{project_name}
    sudo chown vagrant /opt/#{project_name}
    export PATH=/usr/local/bin:$PATH
    cd #{guest_project_path}
    su vagrant -c "bundle install --binstubs"
    su vagrant -c "bin/omnibus build project #{project_name}"
  OMNIBUS_BUILD
end
