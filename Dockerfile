FROM ubuntu:22.04

ARG RUNNER_VERSION="2.335.1"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    curl jq git tar sudo ca-certificates gnupg \
    && install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y docker-ce-cli docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m runner \
    && echo "runner ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers \
    && groupadd -f docker \
    && usermod -aG docker runner

WORKDIR /home/runner/actions-runner

RUN ARCH=$(dpkg --print-architecture) \
    && case "$ARCH" in \
        amd64) RUNNER_ARCH="x64" ;; \
        arm64) RUNNER_ARCH="arm64" ;; \
        armhf) RUNNER_ARCH="arm" ;; \
        *) echo "Unsupported arch: $ARCH" && exit 1 ;; \
    esac \
    && curl -O -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" \
    && tar xzf "actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" \
    && rm "actions-runner-linux-${RUNNER_ARCH}-${RUNNER_VERSION}.tar.gz" \
    && ./bin/installdependencies.sh

COPY start.sh .
RUN chmod +x start.sh \
    && mkdir -p _work \
    && chown -R runner:runner /home/runner/actions-runner

USER runner

ENTRYPOINT ["./start.sh"]