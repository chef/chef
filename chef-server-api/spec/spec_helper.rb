#
# Author:: Tim Hinderliter (<tim@opscode.com>)
# Copyright:: Copyright (c) 2011 Opscode, Inc.
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

require "rubygems"
require "merb-core"
require "rspec"

Merb.push_path(:spec_helpers, "spec" / "spec_helpers", "**/*.rb")
Merb.push_path(:spec_fixtures, "spec" / "fixtures", "**/*.rb")

$:.unshift(File.expand_path('../../app/', __FILE__))

Merb.start_environment(:testing => true, :adapter => 'runner', :environment => ENV['MERB_ENV'] || 'test')

RSpec.configure do |config|
  config.include(Merb::Test::RouteHelper)
  config.include(Merb::Test::ControllerHelper)
end

def get_json(path, params = {}, env = {}, &block)
  request_json("GET", path, params, env, &block)
end

def post_json(path, post_body, env = {}, &block)
  request_json("POST", path, {}, env) do |controller|
    # Merb FakeRequest allows me no way to pass JSON across the
    # FakeRequest/StringIO boundary, so we hack it here.
    if post_body.is_a?(Hash)
      controller.params.merge!(post_body)
    else
      controller.params['inflated_object'] = post_body
    end
    block.call if block
  end
end

# Make an HTTP call of <method>, assign the accept header to
# application/json, and return the JSON-parsed output.
#
# Side effects:
#  Raw textual output available in @response_raw
#  Controller used available in @controller
def request_json(method, path, params, env, &block)
  @controller = mock_request(path, params, env.merge({'HTTP_ACCEPT' => "application/json", :request_method => method})) do |controller|
    stub_authentication(controller)
    block.call(controller) if block
  end

  @response_raw = @controller.body
  @response_json = Chef::JSONCompat.from_json(@response_raw)
end

def stub_authentication(controller)
  username = "tester"

  user = Chef::ApiClient.new
  user.name(username)
  user.admin(true)

  # authenticate_every has a side-effect of setting @auth_user
  controller.stub!(:authenticate_every).and_return(true)
  controller.instance_variable_set(:@auth_user, user)
end

def root_url
  # include organization name to run these tests in the platform
  "http://localhost"
end


