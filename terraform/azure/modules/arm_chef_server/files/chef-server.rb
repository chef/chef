opscode_erchef['keygen_start_size'] = 30

opscode_erchef['keygen_cache_size']=60

nginx['ssl_dhparam']='/etc/opscode/dhparam.pem'

insecure_addon_compat false

data_collector['token'] = 'foobar' unless data_collector.nil?

profiles['root_url'] = 'http://localhost:9998' unless profiles.nil?
