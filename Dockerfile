# Build stage
FROM golang:1.20-alpine AS builder

WORKDIR /app

# 安装编译 go-sqlite3 需要的依赖
RUN apk add --no-cache gcc musl-dev

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download && go mod tidy && go get github.com/mattn/go-sqlite3 && go get golang.org/x/crypto/bcrypt

# Copy source code
COPY . .

# Set version and build datetime
ARG VERSION=0.1.0-dev
ARG BUILD_DATETIME
ENV VERSION=$VERSION
ENV BUILD_DATETIME=$BUILD_DATETIME

# Build the application
RUN go build -a -o auth ./cmd/auth && \
    go build -a -o seeder ./cmd/seeder && \
    go build -a -o token-decoder ./cmd/token-decoder

# Create VERSION file
RUN echo "$VERSION" > /app/VERSION

# Create build-info.json
RUN echo "{\"version\":\"$VERSION\",\"buildDateTime\":\"$BUILD_DATETIME\",\"buildTimestamp\":$(date +%s),\"environment\":\"production\",\"service\":\"brick-x-auth-service\",\"description\":\"Authentication Service\"}" > /app/build-info.json

# Final stage
FROM alpine:latest

RUN apk --no-cache add ca-certificates wget

WORKDIR /app

# 二进制
COPY --from=builder /app/auth /app/
COPY --from=builder /app/seeder /app/
COPY --from=builder /app/token-decoder /app/

# 配置和数据
RUN mkdir -p /etc/brick-x-auth /var/lib/brick-x-auth/data /var/log/brick-x-auth /app/init
COPY config.json /etc/brick-x-auth/config.json
COPY data/ /app/init/

# 密钥
COPY private.pem /app/
COPY public.pem /app/

# 版本和构建信息
COPY --from=builder /app/VERSION /app/VERSION
COPY --from=builder /app/build-info.json /app/build-info.json

# entrypoint
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

VOLUME /var/lib/brick-x-auth /var/log/brick-x-auth
EXPOSE 17101
CMD ["/app/entrypoint.sh"] 