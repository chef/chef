#
# Author:: Richard Manyanza (<liseki@nyikacraftsmen.com>)
# Copyright:: Copyright (c) 2014 Richard Manyanza.
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

class Chef
  class ProviderResolver

    attr_reader :node
    attr_reader :providers

    def initialize(node)
      @node = node
      @providers = []
      @loaded = false
    end

    def load(reload = false)
      return if loaded? && !reload

      @providers = [] if reload

      Chef::Provider.each do |provider|
        @providers << provider if provider.supports_platform?(@node[:platform])
      end

      @loaded = true
    end

    def loaded?
      !!@loaded
    end

    def resolve(resource)
      self.load if !loaded?

      providers = @providers.find_all do |provider|
        provider.enabled?(node) && provider.implements?(resource)
      end

      resource.evaluate_providers(providers)
    end
  end
end
