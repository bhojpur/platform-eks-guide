ARG BHOJPUR_VERSION="main.1973"

FROM us-west2-docker.pkg.dev/bhojpur/platform/build/installer:$BHOJPUR_VERSION as installer

FROM alpine:edge

RUN apk add --no-cache \
    bash \
    curl \
    nodejs \
    python3 \
    py3-pip \
    yarn \
    jq \
    npm \
    yq \
    openssl \
  && pip3 install --upgrade pip \
  && pip3 install \
    awscli \
  && rm -rf /root/.cache

RUN curl -fsSL https://github.com/mikefarah/yq/releases/download/v4.16.0/yq_linux_amd64 -o /usr/local/bin/yq \
  && chmod +x /usr/local/bin/yq

RUN curl -fsSL https://github.com/weaveworks/eksctl/releases/download/v0.76.0/eksctl_Linux_amd64.tar.gz | tar -xz -C /usr/local/bin

RUN curl -fsSL "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl

RUN curl -fsSL https://github.com/kubernetes-sigs/aws-iam-authenticator/releases/download/v0.5.3/aws-iam-authenticator_0.5.3_linux_amd64 -o /usr/local/bin/aws-iam-authenticator \
  && chmod +x /usr/local/bin/aws-iam-authenticator

COPY --from=installer /app/installer /usr/local/bin/bhojpur-installer

WORKDIR /bhojpur

COPY . /bhojpur

RUN yarn --pure-lockfile --non-interactive \
  && rm -rf /usr/local/share/.cache/yarn

RUN npm install -g aws-cdk ts-node

ENTRYPOINT ["/bhojpur/setup.sh"]
