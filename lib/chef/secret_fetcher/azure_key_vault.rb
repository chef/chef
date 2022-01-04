require_relative "base"
require_relative "../exceptions"
require "json" unless defined?(JSON)
require "net/http" unless defined?(Net::HTTP)
require "uri" unless defined?(URI)

class Chef
  class SecretFetcher
    # == Chef::SecretFetcher::AzureKeyVault
    # A fetcher that fetches a secret from Azure Key Vault. Supports fetching with version.
    #
    # In this initial iteration this authenticates via token obtained from the OAuth2  /token
    # endpoint.
    #
    # Validation of required configuration (vault name) is not performed until
    # `fetch` time, to allow for embedding the vault name in with the secret
    # name, such as "my_vault/secretkey1".
    #
    # @example
    #
    # fetcher = SecretFetcher.for_service(:azure_key_vault, { vault: "my_vault" }, run_context)
    # fetcher.fetch("secretkey1", "v1")
    #
    # @example
    #
    # fetcher = SecretFetcher.for_service(:azure_key_vault, {}, run_context)
    # fetcher.fetch("my_vault/secretkey1", "v1")
    #
    # @example
    #
    # fetcher = SecretFetcher.for_service(:azure_key_vault, { client_id: "540d76b6-7f76-456c-b68b-ccae4dc9d99d" }, run_context)
    # fetcher.fetch("my_vault/secretkey1", "v1")
    #
    class AzureKeyVault < Base

      def do_fetch(name, version)
        token = fetch_token
        vault, name = resolve_vault_and_secret_name(name)
        if vault.nil?
          raise Chef::Exceptions::Secret::ConfigurationInvalid.new("You must provide a vault name to fetcher options as vault: 'vault_name' or in the secret name as 'vault_name/secret_name'")
        end

        # Note that `version` is optional after the final `/`. If nil/"", the latest secret version will be fetched.
        secret_uri = URI.parse("https://#{vault}.vault.azure.net/secrets/#{name}/#{version}?api-version=7.2")
        http = Net::HTTP.new(secret_uri.host, secret_uri.port)
        http.use_ssl = true

        response = http.get(secret_uri, { "Authorization" => "Bearer #{token}",
                                          "Content-Type" => "application/json" })

        # If an exception is not raised, we can be reasonably confident of the
        # shape of the result.
        result = JSON.parse(response.body)
        if result.key? "value"
          result["value"]
        else
          raise Chef::Exceptions::Secret::FetchFailed.new("#{result["error"]["code"]}: #{result["error"]["message"]}")
        end
      end

      def validate!
        raise Chef::Exceptions::Secret::ConfigurationInvalid, "You may only specify one (these are mutually exclusive): :object_id, :client_id, or :mi_res_id" if [object_id, client_id, mi_res_id].count { |x| !x.nil? } > 1
      end

      private

      # Determine the vault name and secret name from the provided name.
      # If it is not in the provided name in the form "vault_name/secret_name"
      # it will determine the vault name from `config[:vault]`.
      # @param name [String] the secret name or vault and secret name in the form "vault_name/secret_name"
      # @return Array[String, String] vault and secret name respectively
      def resolve_vault_and_secret_name(name)
        # We support a simplified approach where the vault name is not passed i
        # into configuration, but
        if name.include?("/")
          name.split("/", 2)
        else
          [config[:vault], name]
        end
      end

      def api_version
        "2018-02-01"
      end

      def resource
        "https://vault.azure.net"
      end

      def object_id
        config[:object_id]
      end

      def client_id
        config[:client_id]
      end

      def mi_res_id
        config[:mi_res_id]
      end

      def token_query
        @token_query ||= begin
          p = {}
          p["api-version"] = api_version
          p["resource"] = resource
          p["object_id"] = object_id if object_id
          p["client_id"] = client_id if client_id
          p["mi_res_id"] = mi_res_id if mi_res_id
          URI.encode_www_form(p)
        end
      end

      def fetch_token
        token_uri = URI.parse("http://169.254.169.254/metadata/identity/oauth2/token")
        token_uri.query = token_query
        http = Net::HTTP.new(token_uri.host, token_uri.port)
        response = http.get(token_uri, { "Metadata" => "true" })

        case response
        when Net::HTTPSuccess
          body = JSON.parse(response.body)
          body["access_token"]
        when Net::HTTPBadRequest
          body = JSON.parse(response.body)
          raise Chef::Exceptions::Secret::Azure::IdentityNotFound if /identity not found/i.match?(body["error_description"])
        else
          body = JSON.parse(response.body)
          body["access_token"]
        end
      end
    end
  end
end
