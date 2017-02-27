require "shellwords"
require "pathname"
require "bundler"
require_relative "../../../version_policy"

# Common definitions and helpers (like compile environment and binary
# locations) for all software definitions.
module BuildChefGem
  PLATFORM_FAMILY_FAMILIES = {
    "linux" => %w{wrlinux debian fedora rhel suse gentoo slackware arch exherbo alpine},
    "bsd" => %w{dragonflybsd freebsd netbsd openbsd},
    "solaris" => %w{smartos omnios openindiana opensolaris solaris2 nextentacore},
    "aix" => %w{aix},
    "windows" => %w{windows},
    "mac_os_x" => %w{mac_os_x},
  }
  def platform_family_families
    PLATFORM_FAMILY_FAMILIES.keys
  end

  def platform_family_family
    PLATFORM_FAMILY_FAMILIES.
      select { |key, families| families.include?(Omnibus::Ohai["platform_family"]) }.
      first[0]
  end

  def embedded_bin(binary)
    windows_safe_path("#{install_dir}/embedded/bin/#{binary}")
  end

  def appbundler_bin
    embedded_bin("appbundler")
  end

  def bundle_bin
    embedded_bin("bundle")
  end

  def gem_bin
    embedded_bin("gem")
  end

  def rake_bin
    embedded_bin("rake")
  end

  def without_groups
    # Add --without for every known OS except the one we're in.
    exclude_os_groups = platform_family_families - [ platform_family_family ]
    (INSTALL_WITHOUT_GROUPS + exclude_os_groups).map { |g| g.to_sym }
  end

  #
  # Get the path to the top level shared Gemfile included by all individual
  # Gemfiles
  #
  def shared_gemfile
    File.join(install_dir, "Gemfile")
  end

  # A common env for building everything including nokogiri and dep-selector-libgecode
  def env
    env = with_standard_compiler_flags(with_embedded_path, bfd_flags: true)

    # From dep-selector-libgecode
    # On some RHEL-based systems, the default GCC that's installed is 4.1. We
    # need to use 4.4, which is provided by the gcc44 and gcc44-c++ packages.
    # These do not use the gcc binaries so we set the flags to point to the
    # correct version here.
    if File.exist?("/usr/bin/gcc44")
      env["CC"]  = "gcc44"
      env["CXX"] = "g++44"
    end

    # From dep-selector-libgecode
    # Ruby DevKit ships with BSD Tar
    env["PROG_TAR"] = "bsdtar" if windows?
    env["ARFLAGS"] = "rv #{env["ARFLAGS"]}" if env["ARFLAGS"]

    # Set up nokogiri environment and args
    env["NOKOGIRI_USE_SYSTEM_LIBRARIES"] = "true"
    env
  end

  #
  # Install arguments for various gems (to be passed to `gem install` or set in
  # `bundle config build.<gemname>`).
  #
  def all_install_args
    @all_install_args = {
      "nokogiri" => %W{
        --use-system-libraries
        --with-xml2-lib=#{Shellwords.escape("#{install_dir}/embedded/lib")}
        --with-xml2-include=#{Shellwords.escape("#{install_dir}/embedded/include/libxml2")}
        --with-xslt-lib=#{Shellwords.escape("#{install_dir}/embedded/lib")}
        --with-xslt-include=#{Shellwords.escape("#{install_dir}/embedded/include/libxslt")}
        --with-iconv-dir=#{Shellwords.escape("#{install_dir}/embedded")}
        --with-zlib-dir=#{Shellwords.escape("#{install_dir}/embedded")}
      }.join(" "),
    }
  end

  # gem install arguments for a particular gem. "" if no special args.
  def install_args_for(gem_name)
    all_install_args[gem_name] || ""
  end

  # Give block all the variables
  def block(*args, &block)
    super do
      extend BuildChefGem
      instance_eval(&block)
    end
  end

  # Give build all the variables
  def build(*args, &block)
    super do
      extend BuildChefGem
      instance_eval(&block)
    end
  end
end
