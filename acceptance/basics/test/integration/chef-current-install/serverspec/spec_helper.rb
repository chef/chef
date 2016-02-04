require 'serverspec'
require 'pathname'

set :backend, :exec

set :path, '/bin:/usr/local/bin:$PATH'
