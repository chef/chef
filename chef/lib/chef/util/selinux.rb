module Chef::Util::Selinux
  # written against libselinux-ruby-2.0.94-2.fc13
  require 'selinux'

  def selinux_support?
    return false unless defined?(Selinux)
    return Selinux.is_selinux_enabled == 1 ? true : false
  end

  def selinux_get_context(path)
    return nil unless selinux_support?
    filecon = Selinux.lgetfilecon(path)
    return filecon == -1 ? nil : filecon[1]
  end

  def selinux_set_context(path, context)
    return nil unless selinux_support?
    retval = Selinux.lsetfilecon(path, context)
    return retval == 0 ? true : false
  end

  def selinux_get_default_context(path)
    return nil unless selinux_support?
    mode = File.lstat(path).mode || mode = 0
    pathcon = Selinux.matchpathcon(path,mode)
    return pathcon == -1 ? nil : pathcon[1]
  end
end
