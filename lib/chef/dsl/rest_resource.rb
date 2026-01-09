#
# Copyright (c) 2009-2026 Progress Software Corporation and/or its subsidiaries or affiliates. All Rights Reserved.
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
    #
    # DSL methods for configuring REST resource behavior. These methods are available
    # when a custom resource uses the 'core::rest_resource' partial.
    #
    module RestResource
      # Define property mapping between resource properties and JSON API fields
      #
      # Maps resource properties to their corresponding locations in the JSON
      # API payload. Supports both simple 1:1 mappings and complex transformations.
      #
      # @param rest_property_map [Hash, Array, NOT_PASSED] The property mapping configuration
      #   - Hash: Keys are property symbols, values are JMESPath strings or symbol references
      #   - Array: Simple 1:1 mapping (property name matches JSON field name)
      #   - NOT_PASSED: Acts as getter, returns current mapping
      #
      # @return [Hash] The current property mapping
      #
      # @example Simple 1:1 mapping
      #   rest_property_map [:username, :email, :role]
      #   # Equivalent to: { username: 'username', email: 'email', role: 'role' }
      #
      # @example Nested JSON paths
      #   rest_property_map({
      #     username: 'user.name',
      #     email: 'user.contact.email',
      #     role: 'permissions.role'
      #   })
      #
      # @example Custom mapping functions
      #   rest_property_map({
      #     username: 'username',
      #     tags: :tags_mapping  # Calls tags_from_json and tags_to_json methods
      #   })
      #
      # @see #json_to_property Method that uses this mapping to extract values
      # @see #property_to_json Method that uses this mapping to create JSON
      def rest_property_map(rest_property_map = NOT_PASSED)
        if rest_property_map != NOT_PASSED
          rest_property_map = rest_property_map.to_h { |k| [k.to_sym, k] } if rest_property_map.is_a? Array

          @rest_property_map = rest_property_map
        end
        @rest_property_map
      end

      # Define the REST API collection URL
      #
      # Sets the base URL for the collection of resources. This URL is used for:
      # - GET requests to list all resources
      # - POST requests to create new resources
      #
      # @param rest_api_collection [String, NOT_PASSED] The collection URL path
      #   - String: Must be an absolute path starting with '/'
      #   - NOT_PASSED: Acts as getter, returns current collection URL
      #
      # @return [String] The current collection URL
      #
      # @raise [ArgumentError] If the path doesn't start with '/'
      #
      # @example
      #   rest_api_collection '/api/v1/users'
      #   # GET  /api/v1/users      # List all users
      #   # POST /api/v1/users      # Create new user
      def rest_api_collection(rest_api_collection = NOT_PASSED)
        if rest_api_collection != NOT_PASSED
          raise ArgumentError, "You must pass an absolute path to rest_api_collection" unless rest_api_collection.start_with? "/"

          @rest_api_collection = rest_api_collection
        end

        @rest_api_collection
      end

      # Define the REST API document URL with RFC 6570 template support
      #
      # Sets the URL pattern for individual resource documents. The URL can include
      # RFC 6570 URI templates that will be expanded using property values. This URL
      # is used for:
      # - GET requests to retrieve a specific resource
      # - PATCH/PUT requests to update a resource
      # - DELETE requests to remove a resource
      #
      # @param rest_api_document [String, NOT_PASSED] The document URL pattern
      #   - String: Must be an absolute path starting with '/'
      #   - Can include RFC 6570 templates like {property_name}
      #   - NOT_PASSED: Acts as getter, returns current document URL
      #
      # @param first_element_only [Boolean] If true and API returns array, extract first element only
      #
      # @return [String] The current document URL pattern
      #
      # @raise [ArgumentError] If the path doesn't start with '/'
      #
      # @example Path-based URL
      #   rest_api_document '/api/v1/users/{username}'
      #   # With username='john':
      #   # GET    /api/v1/users/john
      #   # PATCH  /api/v1/users/john
      #   # DELETE /api/v1/users/john
      #
      # @example Query-based URL
      #   rest_api_document '/api/v1/users?name={username}&email={email}'
      #   # With username='john', email='john@example.com':
      #   # GET /api/v1/users?name=john&email=john@example.com
      #
      # @example With first_element_only
      #   rest_api_document '/api/v1/users?name={username}', first_element_only: true
      #   # API returns: [{"name": "john", ...}]
      #   # Resource sees: {"name": "john", ...}
      #
      # @see https://tools.ietf.org/html/rfc6570 RFC 6570 URI Template specification
      def rest_api_document(rest_api_document = NOT_PASSED, first_element_only: false)
        if rest_api_document != NOT_PASSED
          raise ArgumentError, "You must pass an absolute path to rest_api_document" unless rest_api_document.start_with? "/"

          @rest_api_document = rest_api_document
          @rest_api_document_first_element_only = first_element_only
        end
        @rest_api_document
      end

      # Define explicit identity mapping for resource identification
      #
      # Explicitly specifies which JSON fields and resource properties uniquely
      # identify a resource. Use this when automatic identity inference from the
      # document URL is insufficient or when dealing with composite keys.
      #
      # If not specified, the identity is automatically inferred from RFC 6570
      # templates in the document URL.
      #
      # @param rest_identity_map [Hash, NOT_PASSED] Mapping of JSON paths to properties
      #   - Hash: Keys are JMESPath-like strings, values are property symbols
      #   - NOT_PASSED: Acts as getter, returns current identity mapping
      #
      # @return [Hash, nil] The current identity mapping or nil if using auto-inference
      #
      # @example Simple identity
      #   property :username, String, identity: true
      #   rest_identity_map({ 'username' => :username })
      #
      # @example Composite identity
      #   property :name, String
      #   property :namespace, String
      #
      #   rest_identity_map({
      #     'name' => :name,
      #     'namespace' => :namespace
      #   })
      #
      # @example Nested identity fields
      #   property :user_id, String
      #   property :org_id, String
      #
      #   rest_identity_map({
      #     'user.id' => :user_id,
      #     'organization.id' => :org_id
      #   })
      def rest_identity_map(rest_identity_map = NOT_PASSED)
        @rest_identity_map = rest_identity_map if rest_identity_map != NOT_PASSED
        @rest_identity_map
      end

      # Declare properties that should only be sent during resource creation
      #
      # Specifies which properties should only be included in POST (create) requests
      # and excluded from PATCH/PUT (update) requests. This is useful for properties
      # that can only be set during initial creation or would cause errors if
      # included in updates.
      #
      # @param rest_post_only_properties [Symbol, Array<Symbol>, NOT_PASSED] Properties to mark
      #   - Symbol: Single property name
      #   - Array<Symbol>: Multiple property names
      #   - NOT_PASSED: Acts as getter, returns current post-only properties
      #
      # @return [Array<Symbol>] Current list of post-only properties (empty array if none)
      #
      # @example Single property
      #   property :password, String, sensitive: true
      #   property :username, String
      #
      #   rest_post_only_properties :password
      #   # Password only sent when creating user, not when updating
      #
      # @example Multiple properties
      #   property :password, String, sensitive: true
      #   property :initial_role, String
      #   property :username, String
      #
      #   rest_post_only_properties [:password, :initial_role]
      #
      # @example Common use cases
      #   # Passwords that can't be updated via API
      #   rest_post_only_properties :admin_password
      #
      #   # Resource size that can't be changed after creation
      #   rest_post_only_properties :disk_size_gb
      #
      #   # Initialization parameters
      #   rest_post_only_properties [:template_id, :source_snapshot]
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
