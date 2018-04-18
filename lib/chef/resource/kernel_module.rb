#
# Resource:: kernel_module
#
# The MIT License (MIT)
#
# Copyright 2016-2018, Shopify Inc.
# Copyright 22018, Chef Software, Inc.

require "chef/resource"

class Chef
  class Resource
    class KernelModule < Chef::Resource
      resource_name :kernel_module
      provides(:kernel_module) { true }

      property :modname, String, name_property: true, identity: true
      property :load_dir, String, default: "/etc/modules-load.d"
      property :unload_dir, String, default: "/etc/modprobe.d"

      # Load kernel module, and ensure it loads on reboot
      action :install do
        declare_resource(:directory, new_resource.load_dir) do
          recursive true
        end

        declare_resource(:file, "#{new_resource.load_dir}/#{new_resource.modname}.conf") do
          content "#{new_resource.modname}\n"
          notifies :run, "execute[update initramfs]"
        end

        declare_resource(:execute, "update initramfs") do
          command initramfs_command
          action :nothing
        end

        new_resource.run_action(:load)
      end

      # Unload module and remove module config, so it doesn't load on reboot.
      action :uninstall do
        declare_resource(:file, "#{new_resource.load_dir}/#{new_resource.modname}.conf") do
          action :delete
          notifies :run, "execute[update initramfs]"
        end

        declare_resource(:file, "#{new_resource.unload_dir}/blacklist_#{new_resource.modname}.conf") do
          action :delete
          notifies :run, "execute[update initramfs]"
        end

        declare_resource(:execute, "update initramfs") do
          command initramfs_command
          action :nothing
        end

        new_resource.run_action(:unload)
      end

      # Blacklist kernel module
      action :blacklist do
        declare_resource(:file, "#{new_resource.unload_dir}/blacklist_#{new_resource.modname}.conf") do
          content "blacklist #{new_resource.modname}"
          notifies :run, "execute[update initramfs]"
        end

        declare_resource(:execute, "update initramfs") do
          command initramfs_command
          action :nothing
        end

        new_resource.run_action(:unload)
      end

      # Load kernel module
      action :load do
        declare_resource(:execute, "modprobe #{new_resource.modname}") do
          not_if "cat /proc/modules | grep ^#{new_resource.modname}"
        end
      end

      # Unload kernel module
      action :unload do
        declare_resource(:execute, "modprobe -r #{new_resource.modname}") do
          only_if "cat /proc/modules | grep ^#{new_resource.modname}"
        end
      end

      action_class do
        def initramfs_command
          if platform_family?("debian")
            "update-initramfs -u"
          else
            "dracut -f"
          end
        end
      end
    end
  end
end
