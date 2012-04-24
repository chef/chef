#
# Copyright 2012, Opscode, Inc.
#
# All Rights Reserved
#

runit_service "couchdb" do
  action :disable
end

%w[couchdb_bounce couchdb_compact].each do |file_name|
  file File.join("/etc/cron.d/", file_name) do
    action :delete
  end
end
