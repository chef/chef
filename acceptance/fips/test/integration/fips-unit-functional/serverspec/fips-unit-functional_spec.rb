require "mixlib/shellout"
require "bundler"

describe "Chef Fips Unit/Functional Specs" do
  def windows?
    if RUBY_PLATFORM =~ /mswin|mingw|windows/
      true
    else
      false
    end
  end

  let(:omnibus_root) do
    if windows?
      "c:/opscode/chef"
    else
      "/opt/chef"
    end
  end

  let(:env) do
    {
      "PATH" => [ "#{omnibus_root}/embedded/bin", ENV["PATH"] ].join(File::PATH_SEPARATOR),
      "BUNDLE_GEMFILE" => "#{omnibus_root}/Gemfile",
      "GEM_PATH" => nil, "GEM_CACHE" => nil, "GEM_HOME" => nil,
      "BUNDLE_IGNORE_CONFIG" => "true",
      "BUNDLE_FROZEN" => "1",
      "CHEF_FIPS" => "1"
    }
  end

  let(:chef_dir) do
    cmd = Mixlib::ShellOut.new("bundle show chef", env: env).run_command
    cmd.error!
    cmd.stdout.chomp
  end

  def run_rspec_test(test)
    Bundler.with_clean_env do
      cmd = Mixlib::ShellOut.new(
        "bundle exec rspec -f documentation -t ~requires_git #{test}",
        env: env, cwd: chef_dir, timeout: 3600
      )
      cmd.run_command.error!
    end
  end

  it "passes the unit specs" do
    run_rspec_test("spec/unit")
  end

  it "passes the functional specs" do
    run_rspec_test("spec/functional")
  end

end
