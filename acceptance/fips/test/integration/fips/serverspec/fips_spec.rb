require "mixlib/shellout"
require "bundler"

describe "Chef Fips Specs" do
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

  it "passes the unit and functional specs" do
    Bundler.with_clean_env do
      cmd = Mixlib::ShellOut.new(
        "bundle exec rspec -t ~requires_git spec/unit spec/functional spec/integration",
        env: env, live_stream: STDOUT, cwd: chef_dir, timeout: 3600
      )
      cmd.run_command.error!
    end
  end
end
