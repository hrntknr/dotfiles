# syntax=docker/dockerfile:1.4
ARG BASE_IMAGE=ubuntu:26.04
FROM ${BASE_IMAGE}

RUN apt-get update \
  && apt-get install -y \
    zsh iproute2 iptables nftables openssh-server netcat-traditional socat nmap \
    build-essential ca-certificates curl wget dnsutils git unzip file \
    gnupg htop iotop iperf iperf3 net-tools strace tree vim less \
  && rm -rf /var/lib/apt/lists/* \
  && chsh -s /usr/bin/zsh root \
  && mkdir -p /root/.ssh \
  && curl -fsSL https://github.com/hrntknr.keys > /root/.ssh/authorized_keys \
  && chmod 700 /root/.ssh \
  && chmod 600 /root/.ssh/authorized_keys \
  && rm /etc/ssh/ssh_host_*

COPY . /root/.dotfiles
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/sshd_config.conf /etc/ssh/sshd_config.d/mnwork.conf
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN --mount=type=secret,id=github_token \
    GITHUB_TOKEN="$(cat /run/secrets/github_token)" \
    /root/.dotfiles/setup.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
