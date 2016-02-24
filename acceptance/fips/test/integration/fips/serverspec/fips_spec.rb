require 'mixlib/shellout'
require 'bundler'

describe "Chef Fips Specs" do
  it 'passes the unit and functional specs' do
    chef_dir = Dir.glob('/opt/chef/embedded/lib/ruby/gems/*/gems/chef-[0-9]*').last
    Bundler.with_clean_env do
      ruby_cmd = Mixlib::ShellOut.new(
        'bundle exec rspec spec/unit spec/functional', :env => {'PATH' => "#{ENV['PATH']}:/opt/chef/embedded/bin",
                                                                'GEM_PATH' => nil, 'GEM_CACHE'=>nil, 'GEM_HOME'=>nil,
                                                                'CHEF_FIPS'=>'1'},
        :live_stream => STDOUT, :cwd => chef_dir)
      expect { ruby_cmd.run_command.error! }.not_to raise_exception
    end
  end
end

