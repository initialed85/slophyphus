FROM ubuntu:26.04

SHELL ["/bin/bash", "-lic"]

RUN apt update && \
    apt install -y tmux ttyd curl unzip ca-certificates ripgrep fd-find libatomic1 locales software-properties-common && \
        locale-gen en_US.UTF-8 && \
        update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN add-apt-repository ppa:trzsz/ppa
RUN apt update && apt install -y trzsz libsixel-bin

RUN install -m 0755 -d /etc/apt/keyrings
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
RUN chmod a+r /etc/apt/keyrings/docker.asc

RUN echo "Types: deb" >> /etc/apt/sources.list.d/docker.sources
RUN echo "URIs: https://download.docker.com/linux/ubuntu" >> /etc/apt/sources.list.d/docker.sources
RUN echo "Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")" >> /etc/apt/sources.list.d/docker.sources
RUN echo "Components: stable" >> /etc/apt/sources.list.d/docker.sources
RUN echo "Architectures: $(dpkg --print-architecture)" >> /etc/apt/sources.list.d/docker.sources
RUN echo "Signed-By: /etc/apt/keyrings/docker.asc" >> /etc/apt/sources.list.d/docker.sources

RUN apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

RUN curl -LsSf https://astral.sh/uv/install.sh | sh
RUN echo 'export PATH=$PATH:/root/.local/bin' >> /root/.bashrc
RUN . /root/.bashrc && uv python install --default python3.12

RUN curl -fsSL https://bun.sh/install | bash

RUN curl -L https://go.dev/dl/go1.27.3.linux-amd64.tar.gz -O

RUN tar -C /usr/local -xzf go1.27.3.linux-amd64.tar.gz
RUN echo 'export PATH=$PATH:/usr/local/go/bin' >> /root/.bashrc

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.8/install.sh | PROFILE="${BASH_ENV}" bash
RUN . /root/.nvm/nvm.sh && nvm install --lts
RUN . /root/.nvm/nvm.sh && npm install -g typescript

RUN . /root/.nvm/nvm.sh && yes | curl -fsSL https://pi.dev/install.sh | sh

RUN echo 'export PATH=$PATH:/root/.pi/agent/bin' >> /root/.bashrc
RUN echo 'export PATH=$PATH:/usr/bin/versions/node/v24.22.1/bin' >> /root/.bashrc
# RUN echo '. /root/.nvm/nvm.sh' >> /root/.bashrc

RUN pi install npm:@monotykamary/pi-tps
RUN pi install npm:@narumitw/pi-stamp
RUN pi install https://github.com/initialed85/pi-team-room

RUN bash -c 'curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" && mv kubectl /usr/local/bin/ && chmod +x /usr/local/bin/kubectl'

COPY .tmux.conf /root/.tmux.conf
COPY docker-entrypoint.sh /docker-entrypoint.sh

RUN mkdir -p /root/.pi/agent/extensions
COPY compaction-summary-guard.ts loop-guard.ts queue-reload.ts session-commands.ts /root/.pi/agent/extensions/

WORKDIR /workspace

ENTRYPOINT [ "/docker-entrypoint.sh" ]
CMD []
