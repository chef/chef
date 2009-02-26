###
# Company and SSL Details
###

# The company name - used for SSL certificates, and in various other places
COMPANY_NAME = "Opscode"

# The Country Name to use for SSL Certificates
SSL_COUNTRY_NAME = "US"

# The State Name to use for SSL Certificates
SSL_STATE_NAME = "Washington"

# The Locality Name for SSL - typically, the city
SSL_LOCALITY_NAME = "Seattle"

# What department?
SSL_ORGANIZATIONAL_UNIT_NAME = "Operations"

# The SSL contact email address
SSL_EMAIL_ADDRESS = "do_not_reply@opscode.com"

# License for new Cookbooks
# Can be :apachev2 or :none
NEW_COOKBOOK_LICENSE = :apachev2

##########################
# Chef Repository Layout #
##########################

supportdir = File.expand_path(File.join(File.dirname(__FILE__), ".."))
tmpdir = File.expand_path(File.join(File.dirname(__FILE__), "..", "tmp"))

# Where to find upstream cookbooks
COOKBOOK_PATH = File.join(supportdir, "cookbooks")

# Where to find site-local modifications to upstream cookbooks
SITE_COOKBOOK_PATH = File.join(supportdir, "site-cookbooks")

# Chef Config Path
CHEF_CONFIG_PATH = File.join(supportdir, "config")

# The location of the Chef Server Config file (on the server)
CHEF_SERVER_CONFIG = File.join(CHEF_CONFIG_PATH, "server.rb")

# The location of the Chef Client Config file (on the client)
CHEF_CLIENT_CONFIG = File.join(CHEF_CONFIG_PATH, "client.rb")

###
# Useful Extras (which you probably don't need to change)
###

# The top of the repository checkout
TOPDIR = File.expand_path(File.join(File.dirname(__FILE__), ".."))

# Where to store certificates generated with ssl_cert
CADIR = File.expand_path(File.join(TOPDIR, "certificates"))
