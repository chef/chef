name "erchef"
version "master"

dependencies ["erlang", "rsync"]

source :git => "git@github.com:opscode/erchef"

relative_path "erchef"

env = {
  "PATH" => "#{install_dir}/embedded/bin:#{ENV["PATH"]}",
  "LD_FLAGS" => "-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include",
  "LD_RUN_PATH" => "#{install_dir}/embedded/lib"
}

build do
  command "make distclean", :env => env
  command "make rel", :env => env
  command "mkdir -p #{install_dir}/embedded/service/erchef"
  command "#{install_dir}/embedded/bin/rsync -a --delete --exclude=.git/*** --exclude=.gitignore ./rel/erchef/ #{install_dir}/embedded/service/erchef/"
  command "rm -rf #{install_dir}/embedded/service/erchef/log"
end
