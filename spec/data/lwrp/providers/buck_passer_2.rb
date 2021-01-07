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
  lwrp_bar :prepared_eyes do
    action :prepare_eyes
    # We know there will be a deprecation error here; head it off
    without_deprecation_warnings do
      provider :lwrp_paint_drying_watcher
    end
  end
  lwrp_bar :dried_paint_watched do
    action :watch_paint_dry
    # We know there will be a deprecation error here; head it off
    without_deprecation_warnings do
      provider :lwrp_paint_drying_watcher
    end
  end
end
