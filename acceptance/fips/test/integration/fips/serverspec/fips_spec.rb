require 'mixlib/shellout'
require 'bundler'

describe "Chef Fips Specs" do
  def windows?
    if RUBY_PLATFORM =~ /mswin|mingw|windows/
      true
    else
      false
    end
  end

  let(:chef_dir) do
    if windows?
      Dir.glob('c:/opscode/chef/embedded/lib/ruby/gems/*/gems/chef-[0-9]*').last
    else
      Dir.glob('/opt/chef/embedded/lib/ruby/gems/*/gems/chef-[0-9]*').last
    end
  end

  let(:path) do
    if windows?
      'C:\opscode\chef\embedded\bin'
    else
      "/opt/chef/embedded/bin"
    end
  end

  it 'passes the unit and functional specs' do
    Bundler.with_clean_env do
      ruby_cmd = Mixlib::ShellOut.new(
        'bundle exec rspec spec/unit spec/functional', :env => {'PATH' => "#{ENV['PATH']}:#{path}",
                                                                'GEM_PATH' => nil, 'GEM_CACHE'=>nil, 'GEM_HOME'=>nil,
                                                                'CHEF_FIPS'=>'1'},
        :live_stream => STDOUT, :cwd => chef_dir)
      expect { ruby_cmd.run_command.error! }.not_to raise_exception
    end
  end
end
