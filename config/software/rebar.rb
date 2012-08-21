# TODO: move this to omnibus-software
name "rebar"
version "2.0.0"

dependencies ["erlang"]

source :git => "https://github.com/basho/rebar.git"

relative_path "rebar"

env = {
  "PATH" => "#{install_dir}/embedded/bin:#{ENV["PATH"]}",
  "LD_FLAGS" => "-L#{install_dir}/embedded/lib -I#{install_dir}/embedded/include",
  "LD_RUN_PATH" => "#{install_dir}/embedded/lib"
}

build do
  command "./bootstrap", :env => env
  command "cp ./rebar #{install_dir}/embedded/bin/"
end
