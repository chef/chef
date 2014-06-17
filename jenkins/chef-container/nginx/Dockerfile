FROM chef/centos_6.4
ADD chef/ /etc/chef/
RUN chef-init --bootstrap
ENTRYPOINT ["chef-init"]
CMD ["--onboot"]
