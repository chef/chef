module EndToEndSnapStoreRateLimit
  def run_action(action, notification_type = nil, notifying_resource = nil)
    super
  rescue Chef::Exceptions::Package => e
    reason = if e.message.end_with?('{"message" => "too many requests"}')
               "too many requests"
             elsif e.message.match?(%r{\{"message" => "Get \\"https://api\.snapcraft\.io/[^"\\]+\\": context deadline exceeded"\}\z})
               "Snap Store request timed out (context deadline exceeded)"
             end
    raise unless reason

    # ponytail: clearing updated stops this recipe's immediate notification chain.
    updated_by_last_action(false)
    Chef::Log.warn("Skipping remaining Snap end-to-end checks due to Snap repository issues: #{reason}. Snap coverage was not completed.")
  end
end
