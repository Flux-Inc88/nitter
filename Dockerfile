FROM nimlang/nim:2.2.0-alpine-regular as nim
LABEL maintainer="fluxops"

RUN apk --no-cache add libsass-dev pcre git

WORKDIR /src/nitter

COPY nitter.nimble .
RUN nimble install -y --depsOnly

COPY . .
RUN nimble build -d:danger -d:lto -d:strip --mm:refc \
    && nimble scss \
    && nimble md

FROM alpine:latest
WORKDIR /src/

RUN apk --no-cache add pcre ca-certificates

# Copy Nitter binary and assets
COPY --from=nim /src/nitter/nitter ./
COPY --from=nim /src/nitter/public ./public
COPY --from=nim /src/nitter/nitter.conf ./nitter.conf

# ✅ Copy sessions.jsonl into the container
COPY sessions.jsonl ./sessions.jsonl

EXPOSE 8080

RUN adduser -h /src/ -D -s /bin/sh nitter
USER nitter

CMD ["./nitter"]
