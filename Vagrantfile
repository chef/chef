# -*- mode: ruby -*-
# vi: set ft=ruby :

require "vagrant"

if Vagrant::VERSION < "1.2.1"
  raise "The Omnibus Build Lab is only compatible with Vagrant 1.2.1+"
end

host_project_path = File.expand_path("..", __FILE__)
guest_project_path = "/home/vagrant/#{File.basename(host_project_path)}"
project_name = 'chef'
host_name = "#{project_name}-omnibus-build-lab"
bootstrap_chef_version = '11.6.2'

Vagrant.configure('2') do |config|

  %w{
    centos-5.10
    centos-6.5
    freebsd-8.3
    freebsd-9.1
    smartos
    ubuntu-10.04
    ubuntu-11.04
    ubuntu-12.04
  }.each_with_index do |platform, index|

    config.vm.define platform do |c|

      case platform

      ####################################################################
      # SMARTOS-SPECIFIC CONFIG
      ####################################################################
      when 'smartos'
        use_nfs = false

        c.vm.box = "smartos-base1310-64-virtualbox-20130806"
        c.vm.box_url = "http://dlc-int.openindiana.org/aszeszo/vagrant/smartos-base1310-64-virtualbox-20130806.box"

        # bootstrap chef
        c.vm.provision :shell, :inline => <<-SMARTOS_SETUP
          which ruby || pkgin -Fy install ruby193
          which gcc || pkgin -Fy install gcc47
          which make || pkgin -Fy install gmake

          gem list chef -i -v #{bootstrap_chef_version} || \
            gem install chef --version #{bootstrap_chef_version} --bindir=/opt/local/bin/ --no-ri --no-rdoc
        SMARTOS_SETUP

      ####################################################################
      # FREEBSD-SPECIFIC CONFIG
      ####################################################################
      when /^freebsd/

        use_nfs = true

        # FreeBSD's mount_nfs does not like paths over 88 characters
        # http://lists.freebsd.org/pipermail/freebsd-hackers/2012-April/038547.html
        ENV['BERKSHELF_PATH'] = File.join('/tmp')

        major_version = platform.split(/freebsd-(.*)\..*/).last

        c.vm.guest = :freebsd
        c.vm.box = platform
        c.vm.box_url = "http://dyn-vm.s3.amazonaws.com/vagrant/#{platform}_chef-11.8.0.box"
        c.vm.network :private_network, :ip => "33.33.33.#{50 + index}"

        c.vm.provision :shell, :inline => <<-FREEBSD_SETUP
          sed -i '' -E 's%^([^#].*):setenv=%\1:setenv=PACKAGESITE=ftp://ftp.freebsd.org/pub/FreeBSD/ports/amd64/packages-#{major_version}-stable/Latest,%' /etc/login.conf
        FREEBSD_SETUP

      ####################################################################
      # LINUX-SPECIFIC CONFIG
      ####################################################################
      else
        use_nfs = false

        c.vm.box = "opscode-#{platform}"
        c.vm.box_url = "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_#{platform}_chef-provisionerless.box"
        c.omnibus.chef_version = bootstrap_chef_version

        c.vm.provider :virtualbox do |vb|
          # Give enough horsepower to build without taking all day.
          vb.customize [
            'modifyvm', :id,
            '--memory', '1536',
            '--cpus', '2'
          ]
        end

      end # case

      ####################################################################
      # CONFIG SHARED ACROSS ALL PLATFORMS
      ####################################################################

      config.berkshelf.enabled = true
      config.ssh.forward_agent = true

      config.vm.synced_folder '.', '/vagrant', :id => 'vagrant-root', :nfs => use_nfs
      config.vm.synced_folder host_project_path, guest_project_path, :nfs => use_nfs

      # Uncomment for DEV MODE
      # config.vm.synced_folder File.expand_path('../../omnibus-ruby', __FILE__), '/home/vagrant/omnibus-ruby', :nfs => use_nfs
      # config.vm.synced_folder File.expand_path('../../omnibus-software', __FILE__), '/home/vagrant/omnibus-software', :nfs => use_nfs

      # prepare VM to be an Omnibus builder
      c.vm.provision :chef_solo do |chef|
        chef.nfs = use_nfs
        chef.json = {
          'omnibus' => {
            'build_user' => 'vagrant',
            'build_dir' => guest_project_path,
            'install_dir' => "/opt/#{project_name}"
          }
        }

        chef.run_list = [
          'recipe[omnibus::default]'
        ]
      end

      # We have to nuke any chef omnibus packages (used during provisioning) before
      # we build new chef omnibus packages!
      c.vm.provision :shell, :inline => <<-REMOVE_OMNIBUS
        if command -v dpkg &>/dev/null;
        then
          sudo dpkg -P #{project_name} || true
        elseif command -v rpm &>/dev/null;
          sudo rpm -ev #{project_name} || true
        else
          sudo rm -r /opt/#{project_name} || true
        fi
      REMOVE_OMNIBUS

      c.vm.provision :shell, :inline => <<-OMNIBUS_BUILD
        sudo mkdir -p /opt/#{project_name}
        sudo chown vagrant /opt/#{project_name}
        export PATH=/usr/local/bin:$PATH
        cd #{guest_project_path}
        sudo su vagrant -c "bundle install --path=/home/vagrant/.bundler"
        sudo su vagrant -c "bundle exec omnibus build project #{project_name}"
      OMNIBUS_BUILD

    end # config.vm.define.platform
  end # each_with_index
end # Vagrant.configure
