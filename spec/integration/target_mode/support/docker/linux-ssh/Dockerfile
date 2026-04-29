# Minimal Ubuntu image with OpenSSH server for target-mode transport integration tests.
# An SSH public key is injected at build time via the SSH_PUB_KEY build argument.
FROM ubuntu:22.04

ARG SSH_PUB_KEY

RUN apt-get update -qq && \
    apt-get install -y -qq --no-install-recommends openssh-server && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir -p /run/sshd /root/.ssh && \
    chmod 700 /root/.ssh

RUN echo "$SSH_PUB_KEY" > /root/.ssh/authorized_keys && \
    chmod 600 /root/.ssh/authorized_keys

# Allow root login and disable PAM (not available in containers)
RUN sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed -i 's/^UsePAM yes/UsePAM no/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D", "-e"]
