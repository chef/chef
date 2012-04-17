# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'bundler/setup'
require 'omnibus/vagrant/omnibus'

Vagrant::Config.run do |config|

  config.vm.define 'ubuntu-10.04' do |c|
    c.vm.box     = "opscode-ubuntu-10.04"
    c.vm.box_url = "http://opscode-vm.s3.amazonaws.com/vagrant/boxes/opscode-ubuntu-10.04.box"
  end

  config.vm.define 'ubuntu-11.04' do |c|
    c.vm.box     = "opscode-ubuntu-11.04"
    c.vm.box_url = "http://opscode-vm.s3.amazonaws.com/vagrant/boxes/opscode-ubuntu-11.04.box"
  end

  config.vm.define 'centos-5.5' do |c|
    c.vm.box     = "opscode-centos-5.5"
    c.vm.box_url = "http://opscode-vm.s3.amazonaws.com/vagrant/boxes/opscode-centos-5.5.box"
  end

  config.vm.define 'centos-5.7' do |c|
    c.vm.box     = "opscode-centos-5.7"
    c.vm.box_url = "http://opscode-vm.s3.amazonaws.com/vagrant/boxes/opscode-centos-5.7.box"
  end

  config.vm.define 'centos-6.0' do |c|
    c.vm.box     = "opscode-centos-6.0"
    c.vm.box_url = "http://opscode-vm.s3.amazonaws.com/vagrant/boxes/opscode-centos-6.0.box"
  end

  config.vm.define 'centos-6.2' do |c|
    c.vm.box     = "opscode-centos-6.2"
    c.vm.box_url = "http://opscode-vm.s3.amazonaws.com/vagrant/boxes/opscode-centos-6.2.box"
  end

  # Share an additional folder to the guest VM. The first argument is
  # an identifier, the second is the path on the guest to mount the
  # folder, and the third is the path on the host to the actual folder.
  # config.vm.share_folder "v-data", "/vagrant_data", "../data"
  config.vm.share_folder "omnibus-chef", "~/omnibus-chef", File.expand_path("..", __FILE__)
  config.vm.share_folder "omnibus-ruby", "~/omnibus-ruby", File.expand_path("../../omnibus-ruby", __FILE__)

  # Enable provisioning with chef solo, specifying a cookbooks path (relative
  # to this Vagrantfile), and adding some recipes and/or roles.
  config.vm.provision :chef_solo do |chef|
    chef.cookbooks_path = ["cookbooks", File.join(Bundler.definition.specs["omnibus"][0].gem_dir, "cookbooks")]
    chef.add_recipe "omnibus"
    chef.json = {
      "omnibus" => {
        "install-dirs" => ["/opt/chef", "/opt/chef-server"]
      }
    }
  end

  # Enable SSH agent forwarding for git clones
  config.ssh.forward_agent = true
  
  # Give enough horsepower to build PC without taking all day
  # or several hours worth of swapping  Disable support we don't need
  config.vm.customize [ 
    "modifyvm", :id,
    "--memory", "1536", 
    "--cpus", "2", 
    "--usb", "off", 
    "--usbehci", "off",
    "--audio", "none"
  ]

  config.omnibus.path = "~/omnibus-chef"
end

