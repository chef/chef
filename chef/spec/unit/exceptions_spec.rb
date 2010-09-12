#
# Author:: Thomas Bishop (<bishop.thomas@gmail.com>)
# Copyright:: Copyright (c) 2010 Thomas Bishop
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

require File.expand_path(File.join(File.dirname(__FILE__), "..", "spec_helper"))

describe Chef::Exceptions do
  exceptions = [ { 'Application' => 'RuntimeError' },
                 { 'Cron' => 'RuntimeError' },
                 { 'Env' => 'RuntimeError' },
                 { 'Exec' => 'RuntimeError' },
                 { 'FileNotFound' => 'RuntimeError' },
                 { 'Package' => 'RuntimeError' },
                 { 'Service' => 'RuntimeError' },
                 { 'Route' => 'RuntimeError' },
                 { 'SearchIndex' => 'RuntimeError' },
                 { 'Override' => 'RuntimeError' },
                 { 'UnsupportedAction' => 'RuntimeError' },
                 { 'MissingLibrary' => 'RuntimeError' },
                 { 'MissingRole' => 'RuntimeError' },
                 { 'CannotDetermineNodeName' => 'RuntimeError' },
                 { 'User' => 'RuntimeError' },
                 { 'Group' => 'RuntimeError' },
                 { 'Link' => 'RuntimeError' },
                 { 'Mount' => 'RuntimeError' },
                 { 'CouchDBNotFound' => 'RuntimeError' },
                 { 'PrivateKeyMissing' => 'RuntimeError' },
                 { 'CannotWritePrivateKey' => 'RuntimeError' },
                 { 'RoleNotFound' => 'RuntimeError' },
                 { 'ValidationFailed' => 'ArgumentError' },
                 { 'InvalidPrivateKey' => 'ArgumentError' },
                 { 'ConfigurationError' => 'ArgumentError' },
                 { 'RedirectLimitExceeded' => 'RuntimeError' },
                 { 'AmbiguousRunlistSpecification' => 'ArgumentError' },
                 { 'CookbookNotFound' => 'RuntimeError' },
                 { 'AttributeNotFound' => 'RuntimeError' },
                 { 'InvalidCommandOption' => 'RuntimeError' },
                 { 'CommandTimeout' => 'RuntimeError' },
                 { 'ShellCommandFailed' => 'RuntimeError' },
                 { 'RequestedUIDUnavailable' => 'RuntimeError' },
                 { 'InvalidHomeDirectory' => 'ArgumentError' },
                 { 'DsclCommandFailed' => 'RuntimeError' },
                 { 'UserIDNotFound' => 'ArgumentError' },
                 { 'GroupIDNotFound' => 'ArgumentError' },
                 { 'SolrConnectionError' => 'RuntimeError' } ]

  exceptions.each do |exception|
    it "should have an exception class of #{exception.keys.first} which inherits from #{exception.values.first}" do
      Chef::Exceptions.constants.should include(exception.keys.first)
      Chef::Exceptions.const_get(exception.keys.first).ancestors.should include(Kernel.const_get(exception.values.first))
    end
  end
end
