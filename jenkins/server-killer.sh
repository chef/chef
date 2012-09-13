#!/bin/bash -x

# chef server killing script: nukes OSC

# for backing out centos5/sysvinit-style launching of runsvdir-start
if [ -e "/etc/inittab" ]; then
  sudo egrep -v "/opt/chef-server/embedded/bin/runsvdir-start" /etc/inittab > /etc/inittab.new && sudo mv /etc/inittab.new /etc/inittab && sudo kill -1 1
fi

if [ -e "/etc/init/chef-server-runsvdir.conf" ]; then
  sudo rm /etc/init/chef-server-runsvdir.conf
fi

ps ax | egrep 'runsvdir -P /opt/chef-server/service' | grep -v grep | awk '{ print $1 }' | xargs sudo kill -HUP
sleep 5
ps ax | egrep 'runsvdir -P /opt/chef-server/service' | grep -v grep | awk '{ print $1 }' | xargs sudo kill -TERM
ps ax | egrep 'svlogd -tt /var/log/chef-server.*' | grep -v grep | awk '{ print $1 }' | xargs sudo kill -TERM
sudo rm -rf /opt/chef-server
sudo rm -rf /var/opt/chef-server
sudo rm -rf /var/log/chef-server
sudo rm -rf /tmp/opt
sudo rm -rf /etc/chef-server
sleep 5
sudo lsof|grep deleted |awk '{print $2}'|sort|uniq|xargs sudo kill -9

# always succeed
exit 0
