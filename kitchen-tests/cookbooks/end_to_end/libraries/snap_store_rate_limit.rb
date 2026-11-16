module EndToEndSnapStoreRateLimit
  def run_action(action, notification_type = nil, notifying_resource = nil)
    super
  rescue Chef::Exceptions::Package => e
    raise unless e.message.end_with?('{"message" => "too many requests"}')

    # ponytail: clearing updated stops this recipe's immediate notification chain.
    updated_by_last_action(false)
    Chef::Log.warn("Skipping remaining Snap end-to-end checks due to Snap repository issues: too many requests. Snap coverage was not completed.")
  end
end
