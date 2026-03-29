FROM alpine/terragrunt:1.11.3

RUN apk add --no-cache \
    age \
    sops \
    bash \
    curl \
    git \
    jq \
    openssl \
    make

WORKDIR /repo

ENTRYPOINT ["/bin/bash"]
