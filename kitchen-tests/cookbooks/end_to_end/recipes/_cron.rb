#
# Cookbook:: end_to_end
# Recipe:: cron
#

#
# cron_d resource
#

cron_d "noop" do
  hour "5"
  minute "0"
  command "/bin/true"
end

cron_d "name_of_cron_entry" do
  minute "0"
  hour "8"
  weekday "6"
  mailto "admin@example.com"
  command "/bin/true"
  action :create
end

cron_d "name_of_cron_entry" do
  minute "0"
  hour "20"
  day "*"
  month "11"
  weekday "1-5"
  command "/bin/true"
  action :create
end

cron_d "job_to_remove" do
  action :delete
end

#
# cron_access resource
#

cron_access "alice" do
  action :allow
end

cron_access "bob"

# legacy resource name
cron_manage "Bill breaks things. Take away cron" do
  user "bill"
  action :deny
end

#
# cron resource
#

cron "some random cron job" do
  minute  0
  hour    23
  command "/usr/bin/true"
end

cron "remove_a_job" do
  action :delete
end
