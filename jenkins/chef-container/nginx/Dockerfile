FROM chef/ubuntu_12.04
ADD chef/ /etc/chef/
RUN chef-init --bootstrap
ENTRYPOINT ["chef-init"]
CMD ["--onboot"]
