
#
# Build "base" image
#   * Install chef-container.deb
#
    sudo docker build -t base jenkins/chef-container/images/base

#
# Build “chef-server” image using `docker build`
#   * add validation.pem
#   * add client.rb
#   * add encrypted_data_bag_secret
#
    sudo docker build -t chef-server jenkins/chef-container/images/chef-client

#
# Build “chef-solo” image using `docker build`
#   * add solo.rb
#
    sudo docker build -t chef-solo jenkins/chef-container/images/chef-solo

#
# Build “chef-zero” image using `docker build`
#   * add client.rb
#
    sudo docker build -t chef-zero jenkins/chef-container/images/chef-zero

#
# Build nginx “chef-server” container using `docker run`
#
    sudo docker run \
      -v /run/docker.sock:/run/docker.sock \
      -v /usr/bin/docker:/bin/docker \
      -v /home/vagrant/omnibus-chef/jenkins/chef-container/cookbooks:/etc/chef/first-run/cookbooks:ro \
      -e "CHEF_VALIDATION_KEY=`cat jenkins/chef-container/images/chef-server/validation.pem`" \
      -e "CHEF_ENCRYPTED_DATA_BAG_SECRET=`cat jenkins/chef-container/images/chef-server/encrypted_data_bag_secret`" \
      -e "CHEF_CLIENT_CONFIG=`cat jenkins/chef-container/images/chef-server/client.rb`" \
      -e "CHEF_FIRST_BOOT=`cat jenkins/chef-container/first-boot.json`" \
      base:build \
      chef-bootstrap

    sudo docker run -d \
      -v /run/docker.sock:/run/docker.sock \
      -v /usr/bin/docker:/bin/docker \
      -v /home/vagrant/omnibus-chef/jenkins/chef-container/cookbooks:/etc/chef/first-run/cookbooks:ro \
      -e "CHEF_FIRST_BOOT=`cat jenkins/chef-container/first-boot.json`" \
      chef-server:build \
      chef-init

#
# Build nginx “chef-solo” container using `docker run`
#
    sudo docker run \
      -v /run/docker.sock:/run/docker.sock \
      -v /usr/bin/docker:/bin/docker \
      -v /home/vagrant/omnibus-chef/jenkins/chef-container/cookbooks:/etc/chef/first-run/cookbooks:ro \
      -e "CHEF_SOLO_CONFIG=`cat jenkins/chef-container/images/chef-solo/solo.rb`" \
      -e "CHEF_FIRST_BOOT=`cat jenkins/chef-container/first-boot.json`" \
      base:build \
      chef-bootstrap

    sudo docker run -d \
      -v /run/docker.sock:/run/docker.sock \
      -v /usr/bin/docker:/bin/docker \
      -v /home/vagrant/omnibus-chef/jenkins/chef-container/cookbooks:/etc/chef/first-run/cookbooks:ro \
      -e "CHEF_FIRST_BOOT=`cat jenkins/chef-container/first-boot.json`" \
      chef-solo:build \
      chef-init

#
# Build nginx “chef-zero” container using `docker run`
#
    sudo docker run -it \
      -v /run/docker.sock:/run/docker.sock \
      -v /usr/bin/docker:/bin/docker \
      -v /home/vagrant/omnibus-chef/jenkins/chef-container/cookbooks:/cookbooks \
      -e "CHEF_FIRST_BOOT=`cat jenkins/chef-container/first-boot.json`" \
      base \
      chef-bootstrap

<<<<<<< HEAD
    sudo docker run -d \
      -v /run/docker.sock:/run/docker.sock \
      -v /usr/bin/docker:/bin/docker \
      -v /home/vagrant/omnibus-chef/jenkins/chef-container/cookbooks:/cookbooks \
      --expose=[80] \
      -p=[8080:80] \
      -e "CHEF_COMMAND=chef-client -z -r recipe[myface::webserver]" \
      base \
      chef-container

=======
>>>>>>> 2a4afac... Adding debug/testing tools for chef-container.
    sudo docker run \
      -v /run/docker.sock:/run/docker.sock \
      -v /usr/bin/docker:/bin/docker \
      -v /home/vagrant/omnibus-chef/jenkins/chef-container/cookbooks:/var/chef/cookbooks \
      -e "CHEF_CLIENT_CONFIG=`cat jenkins/chef-container/images/chef-zero/client.rb`" \
      -e "CHEF_FIRST_BOOT=`cat jenkins/chef-container/first-boot.json`" \
      base \
      chef-bootstrap

    sudo docker run -d \
      -v /run/docker.sock:/run/docker.sock \
      -v /usr/bin/docker:/bin/docker \
      -v /home/vagrant/omnibus-chef/jenkins/chef-container/cookbooks:/etc/chef/first-run/cookbooks:ro \
      -e "CHEF_FIRST_BOOT=`cat jenkins/chef-container/first-boot.json`" \
      chef-zero:build \
      chef-init
<<<<<<< HEAD
=======

>>>>>>> 2a4afac... Adding debug/testing tools for chef-container.
