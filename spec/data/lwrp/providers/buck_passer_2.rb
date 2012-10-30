action :pass_buck do
  lwrp_bar :prepared_eyes do
    action :prepare_eyes
    provider :lwrp_paint_drying_watcher
  end
  lwrp_bar :dried_paint_watched do
    action :watch_paint_dry
    provider :lwrp_paint_drying_watcher
  end
end
