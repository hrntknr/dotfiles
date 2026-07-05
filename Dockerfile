# syntax=docker/dockerfile:1.25
FROM ubuntu:26.04
ARG DOTFILES_PROFILE=full
ARG USER=hrntknr
ARG WORKDIR=/home/hrntknr

RUN apt-get update \
  && apt-get install -y \
    zsh openssh-server ca-certificates curl wget git locales sudo tini \
    gnupg vim jq fzf netcat-traditional iproute2 iputils-ping \
  && if [ "$DOTFILES_PROFILE" = "full" ]; then \
    apt-get install -y \
      iptables nftables socat nmap build-essential dnsutils unzip file \
      htop iotop iperf iperf3 strace tree python3-venv \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc \
    && chmod a+r /etc/apt/keyrings/docker.asc \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update \
    && apt-get install -y \
      docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin; \
  fi \
  && rm -rf /var/lib/apt/lists/* \
  && rm /etc/ssh/ssh_host_* \
  && echo '%sudo ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/nopasswd \
  && chmod 0440 /etc/sudoers.d/nopasswd \
  && (userdel -r ubuntu 2>/dev/null || true) \
  && if [ "$USER" != "root" ]; then \
    groups=sudo; \
    getent group docker >/dev/null && groups="$groups,docker"; \
    useradd -m -s /usr/bin/zsh -u 1000 -U "$USER" -G "$groups"; \
  else \
    usermod -s /usr/bin/zsh root; \
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
    slim) GITHUB_TOKEN="$github_token" /tmp/dotfiles/setup.sh --skip-mise ;; \
    *) echo "invalid DOTFILES_PROFILE: $DOTFILES_PROFILE" >&2; exit 1 ;; \
    esac

ENV TERM=xterm-256color
ENV LANG=en_US.UTF-8
ENV LC_CTYPE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/bin/zsh", "-l"]
