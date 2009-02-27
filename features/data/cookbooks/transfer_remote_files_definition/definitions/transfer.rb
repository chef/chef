define :transfer_cookbook do
  remote_file "#{node[:tmpdir]}/#{params[:name]}" do
    source "easy.txt"
    cookbook "transfer_remote_files_definition"
  end
end