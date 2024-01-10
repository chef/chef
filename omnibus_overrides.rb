# THIS IS NOW HAND MANAGED, JUST EDIT THE THING
# keep it machine-parsable since CI uses it
#
# NOTE: You MUST update omnibus-software when adding new versions of
# software here: bundle exec rake dependencies:update_omnibus_gemfile_lock
#override "ruby", version: "3.0.3"
override :ruby, version: aix? ? "3.0.3" : "3.1.2"
