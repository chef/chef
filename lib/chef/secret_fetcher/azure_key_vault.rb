require_relative "base"

class Chef
  class SecretFetcher
    # == Chef::SecretFetcher::AWSSecretsManager
    # A fetcher that fetches a secret from Azure Key Vault. Supports fetching with version.
    #
    # In this initial iteration this authenticates via token obtained from the OAuth2  /token
    # endpoint.
    #
    # Usage Example:
    #
    # fetcher = SecretFetcher.for_service(:azure_key_vault)
    # fetcher.fetch("secretkey1", "v1")
    class AzureKeyVault < Base
      def validate!
        @vault = config[:vault]
        if @vault.nil?
          raise Chef::Exceptions::Secret::MissingVaultName.new("You must provide a vault name to service options as vault: 'vault_name'")
        end
      end

      def do_fetch(name, version)
        token = fetch_token

        # Note that `version` is optional after the final `/`. If nil/"", the latest secret version will be fetched.
        secret_uri = URI.parse("https://#{@vault}.vault.azure.net/secrets/#{name}/#{version}?api-version=7.2")
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

      def fetch_token
        token_uri = URI.parse("http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fvault.azure.net")
        http = Net::HTTP.new(token_uri.host, token_uri.port)
        response = http.get(token_uri, { "Metadata" => "true" })
        body = JSON.parse(response.body)
        body["access_token"]
      end
    end
  end
end



