name "erlang"
version "R15B01"

dependencies ["zlib", "openssl", "ncurses"]

source :url => "http://www.erlang.org/download/otp_src_R15B01.tar.gz",
       :md5 => "f12d00f6e62b36ad027d6c0c08905fad"

relative_path "otp_src_R15B01"

env = {
  "CFLAGS" => "-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/erlang/include",
  "LDFLAGS" => "-Wl,-rpath #{install_dir}/embedded/lib -L#{install_dir}/embedded/lib -I#{install_dir}/embedded/erlang/include"
}

build do
  # set up the erlang include dir
  command "mkdir -p #{install_dir}/embedded/erlang/include"
  %w{ncurses openssl zlib.h zconf.h}.each do |link|
    command "ln -fs #{install_dir}/embedded/include/#{link} #{install_dir}/embedded/erlang/include/#{link}"
  end

  # TODO: build cross-platform. this is for linux
  command(["./configure",
           "--prefix=#{install_dir}/embedded",
           "--enable-threads",
           "--enable-smp-support",
           "--enable-kernel-poll",
           "--enable-dynamic-ssl-lib",
           "--enable-shared-zlib",
           "--enable-hipe",
           "--without-javac",
           "--with-ssl=#{install_dir}/embedded",
           "--disable-debug"].join(" "),
          :env => env)

  command "make", :env => env
  command "make install"
end
