
ARG _GOLANG_VERSION="1.24.4"
ARG _DOCKER_VERSION="28.3.0"
ARG _UBUNTU_VERSION="24.04"

FROM golang:${_GOLANG_VERSION} AS go-builder
ARG _TRIVY_VERSION="0.63.0"
ARG _ORAS_VERSION="1.2.3"
ARG _NEKTOS_ACT_VERSION="0.2.78"
ARG _KUBECONFORM_VERSION="0.7.0"
ARG _YQ_VERSION="4.45.4"
ARG _UPX_VERSION="5.0.1"
ARG _SNAPCHART="37eb1fe" # v0.5.0
ARG _TERRAFORM_CONFIG_INSPECT="d2d12f9" # latest
ARG _HCL2JSON="0.6.7"
# COPY go.mod ./
# RUN go mod download

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV GOPROXY='https://proxy.golang.org,https://goproxy.cn,direct'
# ENV GODEBUG=http2debug=1
# Add all ca/*.crt to CA store
COPY ca /usr/local/share/ca-certificates
# hadolint ignore=DL3008,SC2086
RUN set -ex ;\
    apt-get update ;\
    apt-get install -y --no-install-recommends \
    ca-certificates git wget xz-utils ;\
    update-ca-certificates ;\
    go install github.com/nektos/act@v${_NEKTOS_ACT_VERSION} ;\
    go install github.com/mikefarah/yq/v4@v${_YQ_VERSION} ;\
    go install github.com/jlandowner/helm-chartsnap@${_SNAPCHART};\
    go install github.com/hashicorp/terraform-config-inspect@${_TERRAFORM_CONFIG_INSPECT};\
    go install github.com/tmccombs/hcl2json@v${_HCL2JSON};\
    wget --progress=dot:giga https://github.com/upx/upx/releases/download/v${_UPX_VERSION}/upx-${_UPX_VERSION}-amd64_linux.tar.xz ;\
    tar -xf upx-*-amd64_linux.tar.xz ;\
    mv upx-*/upx /usr/local/bin/ ;\
    git clone --depth 1 --branch v${_TRIVY_VERSION} https://github.com/aquasecurity/trivy ;\
    CGO_ENABLED=0  go build -C trivy -ldflags="-s -w"  -o /go/bin/trivy  ./cmd/trivy ;\
    upx --best --lzma /go/bin/trivy ;\
    git clone --depth 1 --branch v${_KUBECONFORM_VERSION} https://github.com/yannh/kubeconform ;\
    go build -C kubeconform -ldflags="-s -w"  -o /go/bin/kubeconform  ./cmd/kubeconform ;\
    upx --best --lzma /go/bin/kubeconform ;\
    git clone --depth 1 --branch v${_ORAS_VERSION} https://github.com/oras-project/oras ;\
    go build -C oras -ldflags="-s -w" -o /go/bin/oras  ./cmd/oras ;\
    rm -rf /var/lib/apt/lists/*

FROM docker:${_DOCKER_VERSION}-dind AS dind-stage
# Create a directory for Docker binaries
RUN mkdir -p /docker

# Copy Docker binaries and libraries to a temporary location
RUN set -ex ;\
    mkdir -p /docker/bin /docker/libexec/ ;\
    cp /usr/local/bin/docker /docker/bin/ ;\
    cp -r /usr/local/libexec/docker /docker/libexec/docker/

# Final stage

FROM ubuntu:${_UBUNTU_VERSION}
ARG _NODE_VERSION="24.3.0"
ENV _NVM_VERSION="0.40.3"
# Copy all build artifacts from go-builder to ./bin dir
COPY --from=go-builder /go/bin /usr/local/bin/

# Copy Docker binaries and libraries from the dind-stage
RUN mkdir -p /usr/local/bin
COPY --from=dind-stage /docker /usr/local
COPY ca /usr/local/share/ca-certificates

ENV NVM_DIR=/usr/local/nvm
ENV NODE_VERSION=${_NODE_VERSION}


# hadolint ignore=DL3008,DL3009,DL4006,SC1091
RUN set -ex ;\
    apt-get update ;\
    apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    openssl ;\
    mkdir -p $NVM_DIR ;\
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v${_NVM_VERSION}/install.sh | bash ;\
    . $NVM_DIR/nvm.sh ;\
    nvm install $NODE_VERSION ;\
    nvm cache clear ;\
    nvm alias default $NODE_VERSION ;\
    nvm use default

# RUN update-ca-certificates
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
# hadolint ignore=DL3008
RUN set -ex ;\
    chmod +x /usr/local/bin/docker ;\
    mkdir -p /var/lib/docker ;\
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | tee /usr/share/keyrings/helm.gpg > /dev/null ;\
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | tee /etc/apt/sources.list.d/helm-stable-debian.list ;\
    apt-get update ;\
    apt-get upgrade -y ;\
    apt-get install -y --no-install-recommends \
    openssl \
    jq \
    lsb-release \
    unzip \
    git \
    openssh-client \
    python3 \
    helm  ;\
    rm -rf /var/lib/apt/lists/*

RUN set -x ;\
    groupadd -g 2375  docker ;\
    mkdir -p ~/bin

# Install dond-shim to /usr/local/bin/dond
# original file https://github.com/felipecrs/docker-on-docker-shim/blob/main/dond
ARG _DOND_SHIM_VERSION="d3f4b04" #"0.7.1"
ENV _DOND_SHIM_PATH="/usr/local/bin/dond"
ENV _DOCKER_PATH="/usr/local/bin/docker"
RUN mv -f "${_DOCKER_PATH}" "${_DOCKER_PATH}.orig"
ADD  --chmod=755 "https://github.com/felipecrs/docker-on-docker-shim/raw/${_DOND_SHIM_VERSION}/dond" "${_DOCKER_PATH}"
# COPY --chmod=755 dond "${DOCKER_PATH}"

ENV REQUESTS_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
ENV NODE_EXTRA_CA_CERTS=/etc/ssl/certs/ca-certificates.crt
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV PATH=~/bin:$PATH:/usr/local/nvm/versions/node/v$NODE_VERSION/bin
