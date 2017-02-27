default["apache"]["remote_host_ip"] = "127.0.0.1"

default["webapp"]["database"] = "webapp"
default["webapp"]["db_username"] = "webapp"
default["webapp"]["path"] = "/srv/webapp"

# XXX: apache2 cookbook 2.0.0 has bugs around changing the mpm and then attempting a graceful restart
# which fails and leaves the service down.
case node["platform"]
when "ubuntu"
  if node["platform_version"].to_f >= 14.04
    default[:apache][:mpm] = "event"
  end
end
