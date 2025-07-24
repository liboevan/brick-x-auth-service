[English](README.en.md) | 中文

# Brick X Auth Service

Brick X 认证服务，提供 JWT 令牌生成和验证功能。

## 🏗️ 架构

### 功能特性
- **JWT 令牌生成** - 用户登录后生成访问令牌
- **RSA 密钥管理** - 使用 RSA 密钥对进行令牌签名
- **用户认证** - 验证用户名和密码
- **用户管理** - 支持用户信息（姓名、邮箱等）
- **健康检查** - 提供 `/health` 端点
- **容器化部署** - 完整的 Docker 支持

### 技术栈
- **语言**: Go 1.20
- **框架**: 标准库 HTTP
- **认证**: JWT + RSA
- **容器**: Docker + Alpine Linux
- **端口**: 17101

## 🚀 快速开始

### 构建镜像
```bash
./scripts/build.sh
```

### 启动服务
```bash
./scripts/start.sh
```

### 检查状态
```bash
./scripts/run.sh status
```

### 查看日志
```bash
./scripts/run.sh logs
```

### 停止服务
```bash
./scripts/run.sh stop
```

## 📋 脚本

### 构建脚本
- **`scripts/build.sh`** - 构建 Docker 镜像
- **`scripts/gen-go-sum.sh`** - 生成 go.sum 文件

### 运行脚本
- **`scripts/start.sh`** - 启动服务
- **`scripts/stop.sh`** - 停止服务
- **`scripts/clean.sh`** - 清理容器和镜像
- **`scripts/test.sh`** - API 测试脚本

## 🔧 配置

### 环境变量
- `TZ=UTC` - 时区设置

### 端口
- **17101** - HTTP API 端口

### 端点
- `GET /health` - 健康检查
- `POST /auth/login` - 用户登录
- `GET /auth/me` - 获取当前用户信息
- `GET /build-info.json` - 构建信息
- `GET /VERSION` - 版本信息

## 🔐 认证

### 登录请求
```bash
curl -X POST http://localhost:17101/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"x-operator","password":"x-operator"}'
```

### 获取用户信息
```bash
curl -X GET http://localhost:17101/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### 响应格式
```json
{
  "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "type": "Bearer"
}
```

## 🔒 安全

### RSA 密钥
- **私钥**: `private.pem` - 用于令牌签名
- **公钥**: `public.pem` - 用于令牌验证
- **格式**: PKCS8/PKCS1 自动检测

### 用户管理
- 默认用户: `x-operator`, `x-observer`, `x-guest`, `x-superadmin`
- 用户信息: 包含姓名、邮箱等详细信息
- 密码验证: bcrypt

## 📊 监控

### 健康检查
```bash
curl http://localhost:17101/health
```

### 构建信息
```bash
curl http://localhost:17101/build-info.json
```

### 版本信息
```bash
curl http://localhost:17101/VERSION
```

## 🧪 测试

### API 测试
```bash
# 运行所有测试
./scripts/test.sh all

# 单独测试
./scripts/test.sh health   # 健康检查
./scripts/test.sh build    # 构建信息
./scripts/test.sh version  # 版本信息
./scripts/test.sh login    # 登录功能
./scripts/test.sh invalid  # 无效端点
```

## 🐛 故障排除

### 常见问题

1. **私钥解析错误**
   ```bash
   # 重新生成密钥
   cd ../brick-x-webapp && ./scripts/generate_keys.sh
   cd ../brick-x-auth-service && ./scripts/build.sh
   ```

2. **端口被占用**
   ```bash
   # 检查端口使用
   sudo lsof -i :17101
   
   # 停止现有容器
   ./scripts/run.sh stop
   ```

3. **容器无法启动**
   ```bash
   # 检查镜像
   docker images | grep brick-x-auth
   
   # 查看日志
   ./scripts/run.sh logs
   ```

### 调试命令
```bash
# 检查容器状态
./scripts/run.sh status

# 查看详细日志
./scripts/run.sh logs -f

# 测试健康检查
curl http://localhost:17101/health

# 检查容器详情
docker inspect brick-x-auth
```

## 🎯 最佳实践

1. **先构建再运行** - 确保镜像存在
2. **检查健康状态** - 启动后验证服务正常
3. **监控日志** - 使用 `./scripts/run.sh logs` 查看输出
4. **定期更新密钥** - 定期重新生成 RSA 密钥对
5. **备份配置** - 备份 `config.json` 和密钥文件

## 📞 支持

如有问题或疑问：
1. 检查服务状态: `./scripts/run.sh status`
2. 查看服务日志: `./scripts/run.sh logs`
3. 验证配置文件: 检查 `config.json`
4. 确认密钥文件: 检查 `private.pem` 和 `public.pem`
5. 测试端点: 使用 curl 测试 API 端点