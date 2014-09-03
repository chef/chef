#
# Author:: Bryan McLellan <btm@loftninjas.org>
# Copyright:: Copyright (c) 2014 Chef Software, Inc.
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
#

require 'chef/util/dsc/lcm_output_parser'

describe Chef::Util::DSC::LocalConfigurationManager::Parser do
  context 'empty input parameter' do
    it 'returns an empty array for a 0 length string' do
      Chef::Util::DSC::LocalConfigurationManager::Parser::parse('').should be_empty
    end

    it 'returns an empty array for a nil input' do
      Chef::Util::DSC::LocalConfigurationManager::Parser::parse('').should be_empty
    end
  end

  context 'correctly formatted output from lcm' do
    it 'returns an empty array for a log with no resources' do
      str = <<EOF
logtype: [machinename]: LCM:  [ Start  Set      ]
logtype: [machinename]: LCM:  [ End    Set      ]
EOF
      Chef::Util::DSC::LocalConfigurationManager::Parser::parse(str).should be_empty
    end

    it 'returns a single resource when only 1 logged with the correct name' do
      str = <<EOF
logtype: [machinename]: LCM:  [ Start  Set      ]
logtype: [machinename]: LCM:  [ Start  Resource ] [name]
logtype: [machinename]: LCM:  [ End    Resource ] [name]
logtype: [machinename]: LCM:  [ End    Set      ]
EOF
      resources = Chef::Util::DSC::LocalConfigurationManager::Parser::parse(str)
      resources.length.should eq(1)
      resources[0].name.should eq('[name]')
    end

    it 'identifies when a resource changes the state of the system' do
      str = <<EOF
logtype: [machinename]: LCM:  [ Start  Set      ]
logtype: [machinename]: LCM:  [ Start  Resource ] [name]
logtype: [machinename]: LCM:  [ Start  Set      ] [name]
logtype: [machinename]: LCM:  [ End    Set      ] [name]
logtype: [machinename]: LCM:  [ End    Resource ] [name]
logtype: [machinename]: LCM:  [ End    Set      ]
EOF
      resources = Chef::Util::DSC::LocalConfigurationManager::Parser::parse(str)
      resources[0].changes_state?.should be_true
    end

    it 'preserves the log provided for how the system changed the state' do
      str = <<EOF
logtype: [machinename]: LCM:  [ Start  Set      ]
logtype: [machinename]: LCM:  [ Start  Resource ] [name]
logtype: [machinename]: LCM:  [ Start  Set      ] [name]
logtype: [machinename]:                           [message]
logtype: [machinename]: LCM:  [ End    Set      ] [name]
logtype: [machinename]: LCM:  [ End    Resource ] [name]
logtype: [machinename]: LCM:  [ End    Set      ]
EOF
      resources = Chef::Util::DSC::LocalConfigurationManager::Parser::parse(str)
      resources[0].change_log.should match_array(["[name]","[message]","[name]"])
    end

    it 'should return false for changes_state?' do
      str = <<EOF
logtype: [machinename]: LCM:  [ Start  Set      ]
logtype: [machinename]: LCM:  [ Start  Resource ] [name]
logtype: [machinename]: LCM:  [ Skip   Set      ] [name]
logtype: [machinename]: LCM:  [ End    Resource ] [name]
logtype: [machinename]: LCM:  [ End    Set      ]
EOF
      resources = Chef::Util::DSC::LocalConfigurationManager::Parser::parse(str)
      resources[0].changes_state?.should be_false
    end

    it 'should return an empty array for change_log if changes_state? is false' do
      str = <<EOF
logtype: [machinename]: LCM:  [ Start  Set      ]
logtype: [machinename]: LCM:  [ Start  Resource ] [name]
logtype: [machinename]: LCM:  [ Skip   Set      ] [name]
logtype: [machinename]: LCM:  [ End    Resource ] [name]
logtype: [machinename]: LCM:  [ End    Set      ]
EOF
      resources = Chef::Util::DSC::LocalConfigurationManager::Parser::parse(str)
      resources[0].change_log.should be_empty
    end
  end

  context 'Incorrectly formatted output from LCM' do
    it 'should allow missing a [End Resource] when its the last one and still find all the resource' do
      str = <<-EOF
logtype: [machinename]: LCM:  [ Start  Set      ]
logtype: [machinename]: LCM:  [ Start  Resource ]  [name]
logtype: [machinename]: LCM:  [ Start  Test     ]
logtype: [machinename]: LCM:  [ End    Test     ]
logtype: [machinename]: LCM:  [ Skip   Set      ]
logtype: [machinename]: LCM:  [ End    Resource ]
logtype: [machinename]: LCM:  [ Start  Resource ]  [name2]
logtype: [machinename]: LCM:  [ Start  Test     ]
logtype: [machinename]: LCM:  [ End    Test     ]
logtype: [machinename]: LCM:  [ Start  Set      ]
logtype: [machinename]: LCM:  [ End    Set      ]
logtype: [machinename]: LCM:  [ End    Set      ]
EOF

      resources = Chef::Util::DSC::LocalConfigurationManager::Parser::parse(str)
      resources[0].changes_state?.should be_false
      resources[1].changes_state?.should be_true
    end

    it 'should allow missing a [End Resource] when its the first one and still find all the resource' do
      str = <<-EOF
logtype: [machinename]: LCM:  [ Start  Set      ]
logtype: [machinename]: LCM:  [ Start  Resource ]  [name]
logtype: [machinename]: LCM:  [ Start  Test     ]
logtype: [machinename]: LCM:  [ End    Test     ]
logtype: [machinename]: LCM:  [ Skip   Set      ]
logtype: [machinename]: LCM:  [ Start  Resource ]  [name2]
logtype: [machinename]: LCM:  [ Start  Test     ]
logtype: [machinename]: LCM:  [ End    Test     ]
logtype: [machinename]: LCM:  [ Start  Set      ]
logtype: [machinename]: LCM:  [ End    Set      ]
logtype: [machinename]: LCM:  [ End    Resource ]
logtype: [machinename]: LCM:  [ End    Set      ]
EOF

      resources = Chef::Util::DSC::LocalConfigurationManager::Parser::parse(str)
      resources[0].changes_state?.should be_false
      resources[1].changes_state?.should be_true
    end

    it 'should allow missing set and end resource and assume an unconverged resource in this case' do
      str = <<-EOF
logtype: [machinename]: LCM:  [ Start  Set      ]
logtype: [machinename]: LCM:  [ Start  Resource ]  [name]
logtype: [machinename]: LCM:  [ Start  Test     ]
logtype: [machinename]: LCM:  [ End    Test     ]
logtype: [machinename]: LCM:  [ Start  Resource ]  [name2]
logtype: [machinename]: LCM:  [ Start  Test     ]
logtype: [machinename]: LCM:  [ End    Test     ]
logtype: [machinename]: LCM:  [ Start  Set      ]
logtype: [machinename]: LCM:  [ End    Set      ]
logtype: [machinename]: LCM:  [ End    Resource ]
logtype: [machinename]: LCM:  [ End    Set      ]
EOF
      resources = Chef::Util::DSC::LocalConfigurationManager::Parser::parse(str)
      resources[0].changes_state?.should be_true
      resources[0].name.should eql('[name]')
      resources[1].changes_state?.should be_true
      resources[1].name.should eql('[name2]')
    end
  end
end
