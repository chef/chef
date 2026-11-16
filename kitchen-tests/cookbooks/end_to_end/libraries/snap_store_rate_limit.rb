module EndToEndSnapStoreRateLimit
  def run_action(action, notification_type = nil, notifying_resource = nil)
    super
  rescue RuntimeError => e
    reason = if e.is_a?(Chef::Exceptions::Package) && e.message.match?(/\{"message" ?=> ?"too many requests"\}\z/)
               "Snap repository issues: too many requests"
             elsif e.is_a?(Chef::Exceptions::Package) && e.message.match?(%r{\{"message" ?=> ?"Get \\"https://api\.snapcraft\.io/[^"\\]+\\": context deadline exceeded"\}\z})
               "Snap repository issues: Snap Store request timed out (context deadline exceeded)"
             elsif e.instance_of?(RuntimeError) && e.message.match?(/(?:\A|: )Snap operating timed out after 300 seconds\.\z/)
               "Snap operation timeout: Snap operating timed out after 300 seconds"
             end
    raise unless reason

    # ponytail: clearing updated stops this recipe's immediate notification chain.
    updated_by_last_action(false)
    Chef::Log.warn("Skipping remaining Snap end-to-end checks due to #{reason}. Snap coverage was not completed.")
  end
end
