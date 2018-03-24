# encoding: utf-8
# override for unf_ext until
# https://github.com/knu/ruby-unf_ext/pull/39
# is merged and released

name "unf_ext"

dependency "ruby"
dependency "rubygems"
dependency "bundler"
dependency "appbundler"

license :project_license
default_version "c0b3bd922214a172976f6f368c0b4e4fbf91ed78"
source git: "https://github.com/jquick/ruby-unf_ext.git"
skip_transitive_dependency_licensing true

build do
  env = with_standard_compiler_flags(with_embedded_path)
  delete "#{name}-*.gem"
  gem "build #{name}.gemspec", env: env
  gem "install #{name}-*.gem --no-document", env: env
end
