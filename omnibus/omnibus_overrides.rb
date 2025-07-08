override :libffi,
  version: "3.4.2",
  source: {
    url: "#{ENV['ARTIFACTORY_BASE_URL'] || 'https://artifactory-internal.ps.chef.co/artifactory'}/omnibus-software-local/libffi/libffi-3.4.2.tar.gz",
    sha256: "540fb721619a6aba3bdeef7d940d8e9e0e6d2c193595bc243241b77ff9e93620 "
  }

# Keep Ruby override for now but comment it out since we're not using custom Ruby yet
# override :ruby, version: "3.3.1"