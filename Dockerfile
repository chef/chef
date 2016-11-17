FROM centos:5
MAINTAINER Chef Software, Inc. <docker@chef.io>

ARG CHANNEL=stable
ARG VERSION=12.16.42
ENV PATH=/opt/chef/bin:/opt/chef/embedded/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN yum install -y wget && \
    wget --content-disposition --no-check-certificate "https://packages.chef.io/files/${CHANNEL}/chef/${VERSION}/el/5/chef-${VERSION}-1.el5.x86_64.rpm" -O /tmp/chef-client.rpm && \
    rpm -i /tmp/chef-client.rpm && \
    rm -rf /tmp/chef-client.rpm

VOLUME [ "/opt/chef" ]
