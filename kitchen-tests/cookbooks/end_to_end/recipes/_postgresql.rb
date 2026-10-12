#
# Cookbook:: end_to_end
# Recipe:: _postgresql
#
# Copyright:: Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
#

# Exercises postgresql_user/postgresql_database from the sous-chefs postgresql
# cookbook. Both resources chef_gem-install `pg` and load its compiled
# pg_ext.so, which links against libpq.so.5 at runtime — regression coverage
# for https://github.com/sous-chefs/postgresql/issues/833, where Habitat's
# scoped LD_LIBRARY_PATH hides libpq.so.5 from the dynamic linker.
if platform_family?("rhel", "debian", "amazon")
  postgresql_install "postgresql" do
    action %i{install init_server}
  end

  postgresql_service "postgresql" do
    action %i{enable start}
  end

  postgresql_user "end_to_end_test_user" do
    unencrypted_password "end_to_end_test_password"
  end

  postgresql_database "end_to_end_test_db" do
    owner "end_to_end_test_user"
  end
end
