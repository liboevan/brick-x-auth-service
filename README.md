# Brick X Auth Service

Brick X 认证服务，提供 JWT 令牌生成和验证功能。

## 🏗️ 架构

### 功能特性
- **JWT 令牌生成** - 用户登录后生成访问令牌
- **RSA 密钥管理** - 使用 RSA 密钥对进行令牌签名
- **用户认证** - 验证用户名和密码
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

### 完整开发工作流
```bash
# 方式一：一键完成
./scripts/build.sh && ./scripts/start.sh && ./scripts/test.sh all

# 方式二：分步执行
./scripts/build.sh             # 构建
./scripts/start.sh             # 启动
./scripts/test.sh all          # 测试
./scripts/stop.sh --remove     # 停止并删除容器
./scripts/clean.sh             # 清理镜像
```

### 容器管理
```bash
# 启动服务
./scripts/start.sh

# 强制重启
./scripts/start.sh --force

# 查看状态
docker ps --filter name=el-brick-x-auth

# 查看日志
docker logs el-brick-x-auth

# 停止服务
./scripts/stop.sh              # 停止服务
./scripts/stop.sh --remove     # 停止并删除容器

# 清理容器和镜像
./scripts/clean.sh                    # 清理容器和最新镜像
./scripts/clean.sh --container        # 仅清理容器
./scripts/clean.sh --image v1.0.0     # 清理特定版本镜像
./scripts/clean.sh --all --force      # 强制清理所有
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
- `POST /login` - 用户登录
- `GET /build-info.json` - 构建信息
- `GET /VERSION` - 版本信息

## 🔐 认证

### 登录请求
```bash
curl -X POST http://localhost:17101/login \
  -H "Content-Type: application/json" \
  -d '{"username":"x-admin","password":"admin123"}'
```

### 响应格式
```json
{
  "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600
}
```

## 🔒 安全

### RSA 密钥
- **私钥**: `private.pem` - 用于令牌签名
- **公钥**: `public.pem` - 用于令牌验证
- **格式**: PKCS8/PKCS1 自动检测

### 用户管理
- 默认用户: `x-admin` / `admin123`
- 密码验证: bcrypt (临时使用简单字符串比较)

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

### 测试覆盖
- ✅ **健康检查** - `/health` 端点
- ✅ **构建信息** - `/build-info.json` 端点
- ✅ **版本信息** - `/VERSION` 端点
- ✅ **登录功能** - `/login` 端点（成功/失败/无效JSON）
- ✅ **错误处理** - 404、405 等错误响应

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
docker inspect el-brick-x-auth
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