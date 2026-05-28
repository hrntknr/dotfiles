# syntax=docker/dockerfile:1.4
FROM ubuntu:24.04
ARG DOTFILES_PROFILE=full
ARG USER=hrntknr

RUN apt-get update \
  && apt-get install -y \
    zsh iproute2 iptables nftables openssh-server netcat-traditional socat nmap \
    build-essential ca-certificates curl wget dnsutils git unzip file locales \
    gnupg htop iotop iperf iperf3 net-tools strace tree vim less jq fzf sudo \
  && rm -rf /var/lib/apt/lists/* \
  && useradd -m -s /usr/bin/zsh $USER \
  && echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER \
  && mkdir -p /home/$USER/.ssh \
  && curl -fsSL https://github.com/hrntknr.keys > /home/$USER/.ssh/authorized_keys \
  && chmod 700 /home/$USER/.ssh \
  && chmod 600 /home/$USER/.ssh/authorized_keys \
  && chown -R $USER:$USER /home/$USER \
  && rm /etc/ssh/ssh_host_* \
  && locale-gen en_US.UTF-8

COPY docker/nmcore-setup.sh /opt/nmcore-setup.sh
COPY docker/sshd_config.conf /etc/ssh/sshd_config.d/override.conf
COPY docker/start-sshd /usr/local/bin/start-sshd
RUN chmod +x /usr/local/bin/start-sshd

USER $USER
WORKDIR /home/$USER
ENV TERM=xterm-256color
COPY --chown=$USER:$USER . /home/$USER/.dotfiles
RUN --mount=type=secret,id=github_token,mode=0444 \
    case "$DOTFILES_PROFILE" in \
      full) setup_args="" ;; \
      mini) setup_args="--skip-mise" ;; \
      *) echo "invalid DOTFILES_PROFILE: $DOTFILES_PROFILE" >&2; exit 1 ;; \
    esac \
    && GITHUB_TOKEN="$(cat /run/secrets/github_token)" \
    /home/$USER/.dotfiles/setup.sh $setup_args

CMD ["/usr/bin/zsh", "-l"]
