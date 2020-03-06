require "chef/shell/shell_session"

class TestableShellSession < Shell::ShellSession

  def rebuild_node
    nil
  end

  def rebuild_collection
    nil
  end

  def loading
    nil
  end

  def loading_complete
    nil
  end

end
