FROM alpine:latest

RUN	apk add --no-cache \
  bash \
  ca-certificates \
  curl \
  jq

COPY src/deploy.sh /deploy.sh
RUN chmod +x /deploy.sh
ENTRYPOINT ["/deploy.sh"]
