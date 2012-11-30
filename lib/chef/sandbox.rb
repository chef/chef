class Chef
  class Sandbox
    # I DO NOTHING!!

    # So, the reason we have a completely empty class here is so that
    # Chef 11 clients do not choke when interacting with Chef 10
    # servers.  The original Chef::Sandbox class (that actually did
    # things) has been removed since its functionality is no longer
    # needed for Chef 11.  However, since we still use the JSON gem
    # and make use of its "auto-inflation" of classes (driven by the
    # contents of the 'json_class' key in all of our JSON), any
    # sandbox responses from a Chef 10 server to a Chef 11 client
    # would cause knife to crash.  The JSON gem would attempt to
    # auto-inflate based on a "json_class": "Chef::Sandbox" hash
    # entry, but would not be able to find a Chef::Sandbox class!
    #
    # This is a workaround until such time as we can completely remove
    # the reliance on the "json_class" field.
  end
end
