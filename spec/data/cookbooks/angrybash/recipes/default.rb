bash "go off the rails" do
  code <<-END
    for i in localhost 127.0.0.1 #{Socket.gethostname()}
    do
      echo "grant all on *.* to root@'$i' identified by 'a_password'; flush privileges;" | mysql -u root -h 127.0.0.1
    done
   END
end
