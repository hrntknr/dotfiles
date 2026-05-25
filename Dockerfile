# syntax=docker/dockerfile:1.4
FROM ubuntu:24.04
ARG DOTFILES_PROFILE=full

RUN apt-get update \
  && apt-get install -y \
    zsh iproute2 iptables nftables openssh-server netcat-traditional socat nmap \
    build-essential ca-certificates curl wget dnsutils git unzip file locales \
    gnupg htop iotop iperf iperf3 net-tools strace tree vim less \
  && rm -rf /var/lib/apt/lists/* \
  && chsh -s /usr/bin/zsh root \
  && mkdir -p /root/.ssh \
  && curl -fsSL https://github.com/hrntknr.keys > /root/.ssh/authorized_keys \
  && chmod 700 /root/.ssh \
  && chmod 600 /root/.ssh/authorized_keys \
  && rm /etc/ssh/ssh_host_* \
  && locale-gen en_US.UTF-8

COPY docker/nmcore-setup.sh /opt/nmcore-setup.sh
COPY docker/entrypoint.sh /usr/local/bin/entrypoint.sh
COPY docker/sshd_config.conf /etc/ssh/sshd_config.d/override.conf
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY . /root/.dotfiles
RUN --mount=type=secret,id=github_token \
    case "$DOTFILES_PROFILE" in \
      full) setup_args="--full" ;; \
      mini) setup_args="--mini" ;; \
      *) echo "invalid DOTFILES_PROFILE: $DOTFILES_PROFILE" >&2; exit 1 ;; \
    esac \
    && GITHUB_TOKEN="$(cat /run/secrets/github_token)" \
    /root/.dotfiles/setup.sh $setup_args

WORKDIR /root

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
