#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright (c) 2012 Thomas Bishop
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


require 'spec_helper'
require 'chef/solr/application/solr'

describe Chef::Solr::Application::Solr do

  describe 'initialize' do
    it 'should have a default config_file option' do
      subject.config[:config_file].should == '/etc/chef/solr.rb'
    end
  end

  describe 'schema_file_path' do
    it 'should return the default schema file path' do
      subject.schema_file_path.should == '/var/chef/solr/conf/schema.xml'
    end

    context 'with a custom solr home path' do
      it 'should return the schema path' do
        Chef::Config.stub(:[]).with(:solr_home_path).
                               and_return('/opt/chef/solr')
        subject.schema_file_path.should == '/opt/chef/solr/conf/schema.xml'
      end
    end

  end

  describe 'solr_config_file_path' do
    it 'should return the default solr config path' do
      subject.solr_config_file_path.should == '/var/chef/solr/conf/solrconfig.xml'
    end

    context 'with a custom solr home path' do
      it 'should return the solr config path' do
        Chef::Config.stub(:[]).with(:solr_home_path).
                               and_return('/opt/chef/solr')
        subject.solr_config_file_path.should == '/opt/chef/solr/conf/solrconfig.xml'
      end
    end

  end

  describe 'schema_document' do
    before do
      @schema_path = '/opt/chef/solr/conf/schema.xml'
      subject.stub :schema_file_path => @schema_path
      @doc_contents = '<?xml version="1.0" encoding="UTF-8" ?><foo>bar</foo>'
    end

    it 'should read the schema file at the correct path' do
      REXML::Document.stub(:new)
      File.should_receive(:open).with(@schema_path, 'r').
                                 and_yield(@doc_contents)
      subject.schema_document
    end

    it 'should return the schema' do
      File.stub(:open).and_yield(@doc_contents)
      subject.schema_document.should be_a REXML::Document
    end
  end

  describe 'config_document' do
    before do
      @solr_config_path = '/opt/chef/solr/conf/solrconfig.xml'
      subject.stub :solr_config_file_path => @solr_config_path
      @doc_contents = '<?xml version="1.0" encoding="UTF-8" ?><foo>bar</foo>'
    end

    it 'should read the config file at the correct path' do
      REXML::Document.stub(:new)
      File.should_receive(:open).with(@solr_config_path, 'r').
                                 and_yield(@doc_contents)
      subject.config_document
    end

    it 'should return an REXML document' do
      File.stub(:open).and_yield(@doc_contents)
      subject.config_document.should be_a REXML::Document
    end
  end

  describe 'schema_attributes' do
    it 'should return the attributes of the schema element' do
      schema_doc_contents = '<?xml version="1.0" encoding="UTF-8" ?>'
      schema_doc_contents << '<schema name="chef" version="1.2"></schema>'
      subject.stub(:schema_document).
              and_return(REXML::Document.new(schema_doc_contents))

      subject.schema_attributes["name"].should == 'chef'
      subject.schema_attributes["version"].should == '1.2'
    end
  end

  describe 'solr_main_index_elements' do
    before do
      doc_contents = '<?xml version="1.0" encoding="UTF-8" ?>'
      doc_contents << '<config><mainIndex>'
      doc_contents << '<maxFieldLength>10000</maxFieldLength>'
      doc_contents << '</mainIndex></config>'
      subject.stub(:config_document).
              and_return(REXML::Document.new(doc_contents))
    end

    it 'should return a collection of the REXML elements' do
      subject.solr_main_index_elements.each { |e| e.should be_a REXML::Element }
    end

    it 'should return the correct elements' do
      subject.solr_main_index_elements.first.name.should == 'maxFieldLength'
      subject.solr_main_index_elements.first.text.should == '10000'
    end
  end

  describe 'solr_schema_name' do
    it 'should return the schema name' do
      subject.stub :schema_attributes => { 'name' => 'chef' }
      subject.solr_schema_name.should == 'chef'
    end
  end

  describe 'solr_schema_version' do
    it 'should return the schema version' do
      subject.stub :schema_attributes => { 'version' => '1.2' }
      subject.solr_schema_version.should == '1.2'
    end
  end

  describe 'solr_main_index_max_field_length' do
    before do
      @elements = [ REXML::Element.new('useCompoundFile').add_text('false'),
                    REXML::Element.new('ramBufferSizeMB').add_text('32'),
                    REXML::Element.new('maxFieldLength').add_text('10000') ]
      subject.stub :solr_main_index_elements => @elements
    end

    it 'should return the value of maxFieldLimit as an integer' do
      subject.solr_main_index_max_field_length.should == 10000
    end

    context 'if unable to find the maxFieldLimit' do
      before do
        elements = @elements.select { |e| e.name != 'maxFieldLength' }
        subject.stub :solr_main_index_elements => elements
      end

      it 'should return nil' do
        subject.solr_main_index_max_field_length.should be_nil
      end
    end

  end

  describe 'valid_schema_name?' do
    it 'should return true if the schema name matches' do
      subject.stub :solr_schema_name => Chef::Solr::SCHEMA_NAME
      subject.valid_schema_name?.should be_true
    end

    it 'should return false if the schema name does not match' do
      subject.stub :solr_schema_name => 'foo'
      subject.valid_schema_name?.should be_false
    end
  end

  describe 'valid_schema_version?' do
    it 'should return true if the version name matches' do
      subject.stub :solr_schema_version => Chef::Solr::SCHEMA_VERSION
      subject.valid_schema_version?.should be_true
    end

    it 'should return false if the version name does not match' do
      subject.stub :solr_schema_version => '-1.0'
      subject.valid_schema_version?.should be_false
    end
  end

  describe 'check_value_of_main_index_max_field_length' do
    it 'should log a warning if it is set to <= 10000' do
      subject.stub :solr_main_index_max_field_length => 10000
      pattern = /maxFieldLimit.+set to.+recommended to increase this value/
      Chef::Log.should_receive(:warn).with(pattern)
      subject.check_value_of_main_index_max_field_length
    end

    it 'should not log a warning if it is set to > 10000' do
      subject.stub :solr_main_index_max_field_length => 10001
      Chef::Log.should_not_receive(:warn)
      subject.check_value_of_main_index_max_field_length
    end

    context 'if it is not set' do
      it 'should log a warning if it is not set' do
        subject.stub :solr_main_index_max_field_length => nil
        Chef::Log.should_receive(:warn).
                  with(/Unable to determine the maxFieldLimit for the mainIndex/)
        subject.check_value_of_main_index_max_field_length
      end
    end

  end

  describe 'solr_home_exists?' do
    before do
      Chef::Config.stub(:[]).with(:solr_home_path).
                             and_return('/opt/chef/solr')
    end

    it 'should return true if the solr home exists' do
      File.stub(:directory?).with('/opt/chef/solr').
                             and_return(true)
      subject.solr_home_exist?.should be_true
    end

    it 'should return false if the solr home does not exist' do
      File.stub(:directory?).with('/opt/chef/solr').
                             and_return(false)
      subject.solr_home_exist?.should be_false
    end
  end

  describe 'solr_data_dir_exists?' do
    before do
      Chef::Config.stub(:[]).with(:solr_data_path).
                             and_return('/opt/chef/solr')
    end

    it 'should return true if the solr data dir exists' do
      File.stub(:directory?).with('/opt/chef/solr').
                             and_return(true)
      subject.solr_data_dir_exist?.should be_true
    end

    it 'should return false if the solr data dir does not exist' do
      File.stub(:directory?).with('/opt/chef/solr').
                             and_return(false)
      subject.solr_data_dir_exist?.should be_false
    end
  end

  describe 'solr_jetty_home_exists?' do
    before do
      Chef::Config.stub(:[]).with(:solr_jetty_path).
                             and_return('/opt/chef/solr')
    end

    it 'should return true if the solr jetty dir exists' do
      File.stub(:directory?).with('/opt/chef/solr').
                             and_return(true)
      subject.solr_jetty_home_exist?.should be_true
    end

    it 'should return false if the solr jetty dir does not exist' do
      File.stub(:directory?).with('/opt/chef/solr').
                             and_return(false)
      subject.solr_jetty_home_exist?.should be_false
    end
  end

  describe 'assert_solr_installed!' do

    context 'when unsuccessful' do
      before do
        message = /chef solr is not installed.+home.+data.+jetty.+misconfigured/i
        Chef::Log.should_receive(:fatal).with(message).and_return(true)
        Chef::Log.stub(:fatal)
      end

      context 'because the solr home does not exist' do
        before do
          subject.stub :solr_home_exist? => false
          subject.stub :solr_data_dir_exist => true
          subject.stub :solr_jetty_home_exist => true
        end

        it 'should log messages and exit' do
          lambda {
            subject.assert_solr_installed!
          }.should raise_error SystemExit
        end
      end

      context 'because the solr data dir does not exist' do
        before do
          subject.stub :solr_home_exist? => true
          subject.stub :solr_data_dir_exist => false
          subject.stub :solr_jetty_home_exist => true
        end

        it 'should log messages and exit' do
          lambda {
            subject.assert_solr_installed!
          }.should raise_error SystemExit
        end
      end

      context 'because the solr jetty home does not exist' do
        before do
          subject.stub :solr_home_exist? => true
          subject.stub :solr_data_dir_exist => true
          subject.stub :solr_jetty_home_exist => false
        end

        it 'should log messages and exit' do
          lambda {
            subject.assert_solr_installed!
          }.should raise_error SystemExit
        end
      end

    end

    context 'when solr home, data dir, and jetty home exist' do
      before do
        ['home', 'data_dir', 'jetty_home'].each do |item|
          subject.stub "solr_#{item}_exist?".to_sym => true
        end
      end

      it 'should not exit' do
        subject.assert_solr_installed!.should_not raise_error SystemExit
      end
    end

  end

  describe 'assert_valid_schema!' do
    context 'when unsuccessful' do
      before do
        message = /chef solr installation.+upgraded.+/i
        Chef::Log.should_receive(:fatal).with(message).and_return(true)
        Chef::Log.stub(:fatal)
        subject.stub :solr_schema_version => ''
      end

      context 'because the schema name is not valid' do
        before do
          subject.stub :valid_schema_name? => false
          subject.stub :valid_schema_version => true
        end

        it 'should log messages and exit' do
          lambda {
            subject.assert_valid_schema!
          }.should raise_error SystemExit
        end
      end

      context 'because the schema version is not valid' do
        before do
          subject.stub :valid_schema_name? => true
          subject.stub :valid_schema_version => false
        end

        it 'should log messages and exit' do
          lambda {
            subject.assert_valid_schema!
          }.should raise_error SystemExit
        end
      end

    end

    context 'when the schema name and version are valid' do
      before do
        ['name', 'version'].each do |item|
          subject.stub "valid_schema_#{item}?".to_sym => true
        end
      end

      it 'should not exit' do
        subject.assert_valid_schema!.should_not raise_error SystemExit
      end
    end

  end

  describe 'setup_application' do
    before do
      Chef::Daemon.should_receive :change_privilege
    end

    it 'should see if solr is installed' do
      subject.stub :assert_valid_schema!
      subject.stub :check_value_of_main_index_max_field_length
      subject.should_receive :assert_solr_installed!
      subject.setup_application
    end

    it 'should see if the schema is valid' do
      subject.stub :assert_solr_installed!
      subject.stub :check_value_of_main_index_max_field_length
      subject.should_receive :assert_valid_schema!
      subject.setup_application
    end

    it 'should check the maxFieldLimit setting' do
      subject.stub :assert_solr_installed!
      subject.stub :assert_valid_schema!
      subject.should_receive :check_value_of_main_index_max_field_length
      subject.setup_application
    end

    context 'with solr installed and a valid schema' do
      before do
        subject.stub :assert_solr_installed!
        subject.stub :assert_valid_schema!
        subject.stub :check_value_of_main_index_max_field_length
      end

      context 'with -L or --logfile' do
        before do
          @log_location = '/var/log/chef_solr.log'
          Chef::Config.stub(:[]).with(:log_location).and_return(@log_location)
          Chef::Config.stub(:[]).with(:log_level).and_return(:info)
        end

        it 'should open the log file for appending' do
          File.should_receive(:new).with(@log_location, 'a')
          subject.setup_application
        end
      end

      it 'should set the log level' do
        Chef::Config.stub(:[]).with(:log_location).and_return(nil)
        Chef::Config.stub(:[]).with(:log_level).and_return(:info)
        Chef::Log.should_receive(:level=).with(:info)
        subject.setup_application
      end
    end

  end

  describe 'run_application' do
    context 'with -d or --daemonize' do
      before do
        Chef::Config[:daemonize] = true
        Kernel.stub :exec
        Dir.stub :chdir
      end

      it 'should daemonize' do
        Chef::Daemon.should_receive(:daemonize).with('chef-solr')
        subject.run_application
      end
    end

    it 'should change to the jetty home dir' do
      Kernel.stub :exec
      Dir.should_receive(:chdir).with(Chef::Config[:solr_jetty_path])
      subject.run_application
    end

    context 'after changing to the jetty home dir' do
      before do
        Dir.should_receive(:chdir).and_yield
        Chef::Daemon.stub :daemonize
        Chef::Log.stub :info
      end

      it 'should start the process with the default settings' do
        cmd = "java -Xmx#{Chef::Config[:solr_heap_size]} "
        cmd << "-Xms#{Chef::Config[:solr_heap_size]} "
        cmd << "-Dsolr.data.dir=#{Chef::Config[:solr_data_path]} "
        cmd << "-Dsolr.solr.home=#{Chef::Config[:solr_home_path]} "
        cmd << "-jar #{File.join(Chef::Config[:solr_jetty_path], 'start.jar')}"

        Kernel.should_receive(:exec).with(cmd)
        subject.run_application
      end

      it 'should log the command that solr is started with' do
        cmd = /java.+solr.+jar.+start\.jar/
        Chef::Log.should_receive(:info).with(cmd)
        Kernel.stub :exec
        subject.run_application
      end

      context 'with custom heap' do
        it 'should start the process with the custom setting' do
          Chef::Config[:solr_heap_size] = '2048M'
          cmd_fragment = /-Xmx2048M -Xms2048M/
          Kernel.should_receive(:exec).with(cmd_fragment)
          subject.run_application
        end
      end

      context 'with custom data path' do
        it 'should start the process with the custom setting' do
          Chef::Config[:solr_data_path] = '/opt/chef/solr_data'
          cmd_fragment = /-Dsolr\.data\.dir=\/opt\/chef\/solr_data/
          Kernel.should_receive(:exec).with(cmd_fragment)
          subject.run_application
        end
      end

      context 'with custom home path' do
        it 'should start the process with the custom setting' do
          Chef::Config[:solr_home_path] = '/opt/chef/solr/'
          cmd_fragment = /-Dsolr\.solr\.home=\/opt\/chef\/solr/
          Kernel.should_receive(:exec).with(cmd_fragment)
          subject.run_application
        end
      end

      context 'with custom jetty path' do
        it 'should start the process with the custom setting' do
          Chef::Config[:solr_jetty_path] = '/opt/chef/solr_jetty/'
          cmd_fragment = /-jar \/opt\/chef\/solr_jetty\/start.jar/
          Kernel.should_receive(:exec).with(cmd_fragment)
          subject.run_application
        end
      end

      context 'with custom java opts' do
        it 'should start the java process with the custom setting' do
          Chef::Config[:solr_java_opts] = '-XX:UseLargePages'
          cmd_fragment = /-XX:UseLargePages/
          Kernel.should_receive(:exec).with(cmd_fragment)
          subject.run_application
        end
      end

      context 'with -L or --logfile' do
        it 'should close the previously opened log file and reopen it' do
          Kernel.stub :exec
          subject.logfile = StringIO.new
          subject.should_receive(:close_and_reopen_log_file)
          subject.run_application
        end
      end

    end

  end

  describe 'close_and_reopen_log_file' do
    it 'should close the log and reopen it' do
      log = StringIO.new
      Chef::Log.should_receive :close
      STDOUT.should_receive(:reopen).with log
      STDERR.should_receive(:reopen).with log
      subject.logfile = log
      subject.close_and_reopen_log_file
    end
  end

  describe 'run' do
    it { should respond_to :run}
  end

end
