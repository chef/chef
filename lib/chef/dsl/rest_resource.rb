#
# Copyright:: Copyright 2008-2016, Chef, Inc.
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

require "chef/constants" unless defined?(NOT_PASSED)

class Chef
  module DSL
    module RestResource
      def rest_property_map(rest_property_map = NOT_PASSED)
        if rest_property_map != NOT_PASSED
          rest_property_map = rest_property_map.to_h { |k| [k.to_sym, k] } if rest_property_map.is_a? Array

          @rest_property_map = rest_property_map
        end
        @rest_property_map
      end

      # URL to collection
      def rest_api_collection(rest_api_collection = NOT_PASSED)
        @rest_api_collection = rest_api_collection if rest_api_collection != NOT_PASSED
        @rest_api_collection
      end

      # RFC6570-Templated URL to document
      def rest_api_document(rest_api_document = NOT_PASSED, first_element_only: false)
        if rest_api_document != NOT_PASSED
          @rest_api_document = rest_api_document
          @rest_api_document_first_element_only = first_element_only
        end
        @rest_api_document
      end

      # Explicit REST document identity mapping
      def rest_identity_map(rest_identity_map = NOT_PASSED)
        @rest_identity_map = rest_identity_map if rest_identity_map != NOT_PASSED
        @rest_identity_map
      end

      # Mark up properties for POST only, not PATCH/PUT
      def rest_post_only_properties(rest_post_only_properties = NOT_PASSED)
        if rest_post_only_properties != NOT_PASSED
          @rest_post_only_properties = Array(rest_post_only_properties).map(&:to_sym)
        end
        @rest_post_only_properties || []
      end

      def rest_api_document_first_element_only(rest_api_document_first_element_only = NOT_PASSED)
        if rest_api_document_first_element_only != NOT_PASSED
          @rest_api_document_first_element_only = rest_api_document_first_element_only
        end
        @rest_api_document_first_element_only
      end

    end
  end
end
