module CookbookGit
  def self.test_cookbook_name
    "git"
  end
  def self.test_run_path
    File.join(Chef.node["chef-acceptance"]["suite-dir"], "test_run")
  end
  def self.acceptance_path
    File.expand_path("..", Chef.node["chef-acceptance"]["suite-dir"])
  end
  def self.acceptance_gemfile
    File.join(acceptance_path, "Gemfile")
  end
end

ENV["KITCHEN_LOCAL_YAML"] ||= File.join(Chef.node["chef-acceptance"]["suite-dir"], ".kitchen.#{ENV["KITCHEN_DRIVER"] || "vagrant"}.yml")
