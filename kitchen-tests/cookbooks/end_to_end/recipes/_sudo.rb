#
# Cookbook:: end_to_end
# Recipe:: sudo
#

sudo "sysadmins" do
  users "bob_bobberson"
  groups "sysadmins, superusers"
  nopasswd true
end

sudo "tomcat" do
  user "%tomcat"
  runas "app_user"
  commands ["/etc/init.d/tomcat restart", "/etc/init.d/tomcat stop", "/etc/init.d/tomcat start"]
  defaults ["!requiretty", "env_reset"]
end

sudo "bob" do
  user "bob"
end

sudo "invalid.user" do
  user "bob"
end

sudo "tilde-invalid~user" do
  user "bob"
  action :create
end

# Like above, but ensure the tilde at the front gets munged as well
sudo "~bob" do
  user "bob"
end

sudo "alice" do
  user "alice"
  command_aliases [{ name: "STARTSSH", command_list: ["/etc/init.d/ssh start", "/etc/init.d/ssh restart", "! /etc/init.d/ssh stop"] }]
  commands ["STARTSSH"]
end

sudo "webteam" do
  command_aliases [
    {
      "name": "WEBTEAM_SYSTEMD_JBOSS",
      "command_list": [
      "/usr/bin/systemctl start eap7-standalone.service",
      "/usr/bin/systemctl start jbcs-httpd24-httpd.service", \
      "/usr/bin/systemctl stop eap7-standalone.service", \
      "/usr/bin/systemctl stop jbcs-httpd24-httpd.service", \
      "/usr/bin/systemctl restart eap7-standalone.service", \
      "/usr/bin/systemctl restart jbcs-httpd24-httpd.service", \
      "/usr/bin/systemctl --full edit eap7-standalone.service", \
      "/usr/bin/systemctl --full edit jbcs-httpd24-httpd.service", \
      "/usr/bin/systemctl daemon-reload",
      ],
    },
    {
      "name": "GENERIC_SYSTEMD",
      "command_list": [
        "/usr/sbin/systemctl list-unit-files",
        "/usr/sbin/systemctl list-timers", \
        "/usr/sbin/systemctl is-active *", \
        "/usr/sbin/systemctl is-enabled *",
      ],
    },
  ]
  nopasswd               true
  users                  "%webteam"
  commands %w{WEBTEAM_SYSTEMD_JBOSS GENERIC_SYSTEMD}
end

sudo "git" do
  user "git"
  runas "phabricator"
  nopasswd true
  setenv true
  commands ["/usr/bin/git-upload-pack", "/usr/bin/git-receive-pack"]
end

sudo "jane" do
  user "jane"
  noexec true
  commands ["/usr/bin/less"]
end

sudo "rbenv" do
  env_keep_add %w{PATH RBENV_ROOT RBENV_VERSION}
end

sudo "java_home" do
  env_keep_subtract ["JAVA_HOME"]
end
