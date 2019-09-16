#
# Resource:: kernel_module
#
# The MIT License (MIT)
#
# Copyright 2016-2018, Shopify Inc.
# Copyright 2018, Chef Software, Inc.

require_relative "../resource"

class Chef
  class Resource
    class KernelModule < Chef::Resource
      resource_name :kernel_module

      description "Use the kernel_module resource to manage kernel modules on Linux systems. This resource can load, unload, blacklist, disable, install, and uninstall modules."
      introduced "14.3"
      examples <<~DOC
        Install and load a kernel module, and ensure it loads on reboot.
        ```ruby
        kernel_module 'loop'
        ```
        Install and load a kernel with a specific set of options, and ensure it loads on reboot. Consult kernel module
        documentation for specific options that are supported.
        ```ruby
        kernel_module 'loop' do
          options [
            'max_loop=4',
            'max_part=8'
          ]
        end
        ```
        Load a kernel module.
        ```ruby
        kernel_module 'loop' do
          action :load
        end
        ```
        Unload a kernel module and remove module config, so it doesn’t load on reboot.
        ```ruby
        kernel_module 'loop' do
          action :uninstall
        end
        ```
        Unload kernel module.
        ```ruby
        kernel_module 'loop' do
          action :unload
        end
        ```
        Blacklist a module from loading.
        ```ruby
        kernel_module 'loop' do
          action :blacklist
        end
        ```
        Disable a kernel module.
        ```ruby
        kernel_module 'loop' do
          action :disable
        end
        ```
      DOC

      property :modname, String,
        description: "An optional property to set the kernel module name if it differs from the resource block's name.",
        name_property: true, identity: true

      property :options, Array,
        description: "An optional property to set options for the kernel module.",
        introduced: "15.4"

      property :load_dir, String,
        description: "The directory to load modules from.",
        default: "/etc/modules-load.d"

      property :unload_dir, String,
        description: "The modprobe.d directory.",
        default: "/etc/modprobe.d"

      action :install do
        description "Load kernel module, and ensure it loads on reboot."

        # create options file before loading the module
        unless new_resource.options.nil?
          file "#{new_resource.unload_dir}/options_#{new_resource.modname}.conf" do
            content "options #{new_resource.modname} #{new_resource.options.join(" ")}\n"
          end.run_action(:create)
        end

        # load the module first before installing
        new_resource.run_action(:load)

        directory new_resource.load_dir do
          recursive true
        end

        file "#{new_resource.load_dir}/#{new_resource.modname}.conf" do
          content "#{new_resource.modname}\n"
          notifies :run, "execute[update initramfs]", :delayed
        end

        with_run_context :root do
          find_resource(:execute, "update initramfs") do
            command initramfs_command
            action :nothing
          end
        end
      end

      action :uninstall do
        description "Unload a kernel module and remove module config, so it doesn't load on reboot."

        file "#{new_resource.load_dir}/#{new_resource.modname}.conf" do
          action :delete
          notifies :run, "execute[update initramfs]", :delayed
        end

        file "#{new_resource.unload_dir}/blacklist_#{new_resource.modname}.conf" do
          action :delete
          notifies :run, "execute[update initramfs]", :delayed
        end

        file "#{new_resource.unload_dir}/options_#{new_resource.modname}.conf" do
          action :delete
        end

        with_run_context :root do
          find_resource(:execute, "update initramfs") do
            command initramfs_command
            action :nothing
          end
        end

        new_resource.run_action(:unload)
      end

      action :blacklist do
        description "Blacklist a kernel module."

        file "#{new_resource.unload_dir}/blacklist_#{new_resource.modname}.conf" do
          content "blacklist #{new_resource.modname}"
          notifies :run, "execute[update initramfs]", :delayed
        end

        with_run_context :root do
          find_resource(:execute, "update initramfs") do
            command initramfs_command
            action :nothing
          end
        end

        new_resource.run_action(:unload)
      end

      action :disable do
        description "Disable a kernel module."

        file "#{new_resource.unload_dir}/disable_#{new_resource.modname}.conf" do
          content "install #{new_resource.modname} /bin/false"
          notifies :run, "execute[update initramfs]", :delayed
        end

        with_run_context :root do
          find_resource(:execute, "update initramfs") do
            command initramfs_command
            action :nothing
          end
        end

        new_resource.run_action(:unload)
      end

      action :load do
        description "Load a kernel module."

        unless module_loaded?
          converge_by("load kernel module #{new_resource.modname}") do
            shell_out!("modprobe #{new_resource.modname}")
          end
        end
      end

      action :unload do
        description "Unload kernel module."

        if module_loaded?
          converge_by("unload kernel module #{new_resource.modname}") do
            shell_out!("modprobe -r #{new_resource.modname}")
          end
        end
      end

      action_class do
        # determine the correct command to regen the initramfs based on platform
        # @return [String]
        def initramfs_command
          if platform_family?("debian")
            "update-initramfs -u"
          else
            "dracut -f"
          end
        end

        # see if the module is listed in /proc/modules or not
        # @return [Boolean]
        def module_loaded?
          /^#{new_resource.modname}/.match?(::File.read("/proc/modules"))
        end
      end
    end
  end
end
