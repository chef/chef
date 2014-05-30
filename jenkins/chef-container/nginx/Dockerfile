FROM tduffield/ubuntu_12.04
ADD chef/ /chef/
RUN chef-init --bootstrap
ENTRYPOINT ["chef-init"]
CMD ["--onboot"]

