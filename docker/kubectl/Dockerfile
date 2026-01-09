# syntax=docker/dockerfile:1
# see https://medium.com/@ryanjjacobs/kubernetes-monitoring-a-complete-solution-part-11-de-bitnamify-a7daa1a86a4f

# set default version
ARG KUBECTL_VERSION="latest"

FROM debian:13-slim AS downloader

# ingest args from global scope
ARG KUBECTL_VERSION
ARG TARGETARCH
# although a common pattern, not recommended to use an ENV var for this so using an ARG
ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /app/bin

# we later want to be run this as a no-root user, but we need a /etc/passwd file to do that.
# see: https://medium.com/@lizrice/non-privileged-containers-based-on-the-scratch-image-a80105d6d341
RUN useradd -u 60 kubeuser

# this seems a bit silly but we need curl and ca-certificates at a minimum. Could probably clean up the final image a bit
# more by uninstalling things we don't need too, but debian slim is pretty slim.
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# download and verify the binary per https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/
RUN if [ "$KUBECTL_VERSION" = "latest" ] ; then \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl" -w "%{http_code}\n" && \
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/${TARGETARCH}/kubectl.sha256" -w "%{http_code}\n"; \
    else \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl" -w "%{http_code}\n" && \
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl.sha256" -w "%{http_code}\n" ; \
    fi && \
    echo "$(cat kubectl.sha256) kubectl" | sha256sum --check && \
    chown kubeuser ./kubectl && \
    chmod +x ./kubectl && \
    ./kubectl version --client

# switch to the correct user now that everything is installed
USER kubeuser
ENV PATH="$PATH:/app/bin"

CMD [ "kubectl", "version", "--client"]
