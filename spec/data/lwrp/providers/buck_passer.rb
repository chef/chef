provides :buck_passer

def without_deprecation_warnings(&block)
  old_treat_deprecation_warnings_as_errors = Chef::Config[:treat_deprecation_warnings_as_errors]
  Chef::Config[:treat_deprecation_warnings_as_errors] = false
  begin
    yield
  ensure
    Chef::Config[:treat_deprecation_warnings_as_errors] = old_treat_deprecation_warnings_as_errors
  end
end

def action_pass_buck
  lwrp_foo :prepared_thumbs do
    action :prepare_thumbs
    # We know there will be a deprecation error here; head it off
    without_deprecation_warnings do
      provider :lwrp_thumb_twiddler
    end
  end
  lwrp_foo :twiddled_thumbs do
    action :twiddle_thumbs
    # We know there will be a deprecation error here; head it off
    without_deprecation_warnings do
      provider :lwrp_thumb_twiddler
    end
  end
end
