name "bookshelf"
version "master"

dependencies ["erlang", "rebar", "rsync"]

source :git => "git@github.com:opscode/bookshelf.git"

relative_path "bookshelf"

env = {
  "PATH" => "#{install_dir}/embedded/bin:#{ENV["PATH"]}",
  "LD_FLAGS" => "-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include",
  "LD_RUN_PATH" => "#{install_dir}/embedded/lib"
}

build do
  command "make distclean", :env => env
  command "make rel", :env => env
  command "mkdir -p #{install_dir}/embedded/service/bookshelf"
  command "#{install_dir}/embedded/bin/rsync -a --delete ./rel/bookshelf/ #{install_dir}/embedded/service/bookshelf/"
  command "rm -rf #{install_dir}/embedded/service/bookshelf/log"
end
