# syntax=docker/dockerfile:1.4
FROM ubuntu:24.04
ARG DOTFILES_PROFILE=full
ARG USER=root
ARG WORKDIR=/root

RUN apt-get update \
  && apt-get install -y \
    zsh iproute2 iputils-ping iptables nftables openssh-server netcat-traditional socat nmap \
    build-essential ca-certificates curl wget dnsutils git unzip file locales \
    gnupg htop iotop iperf iperf3 net-tools strace tree vim less jq fzf sudo \
  && rm -rf /var/lib/apt/lists/* \
  && rm /etc/ssh/ssh_host_* \
  && (userdel -r ubuntu 2>/dev/null || true) \
  && if [ "$USER" != "root" ]; then \
    useradd -m -s /usr/bin/zsh -u 1000 -U "$USER"; \
    echo "$USER ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$USER"; \
  fi \
  && locale-gen en_US.UTF-8

COPY docker/nmcore-setup.sh /opt/nmcore-setup.sh
COPY docker/sshd_config.conf /etc/ssh/sshd_config.d/override.conf
COPY docker/start-sshd /usr/local/bin/start-sshd
RUN chmod +x /usr/local/bin/start-sshd

USER $USER
WORKDIR $WORKDIR
COPY --chown=$USER:$USER . /tmp/dotfiles
RUN --mount=type=secret,id=github_token,mode=0444 github_token="$(cat /run/secrets/github_token)" \
  && install -d -m 700 "$HOME/.ssh" \
  && curl -fsSL https://github.com/hrntknr.keys > "$HOME/.ssh/authorized_keys" \
  && chmod 600 "$HOME/.ssh/authorized_keys" \
  && case "$DOTFILES_PROFILE" in \
    full) GITHUB_TOKEN="$github_token" /tmp/dotfiles/setup.sh ;; \
    mini) GITHUB_TOKEN="$github_token" /tmp/dotfiles/setup.sh --skip-mise ;; \
    *) echo "invalid DOTFILES_PROFILE: $DOTFILES_PROFILE" >&2; exit 1 ;; \
    esac

ENV TERM=xterm-256color
ENV LANG=en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
CMD ["/usr/bin/zsh", "-l"]
