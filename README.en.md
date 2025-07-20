[中文](README.md) | English

# Brick X Auth Service

Brick X authentication service providing JWT token generation and validation functionality.

## 🏗️ Architecture

### Features
- **JWT Token Generation** - Generate access tokens after user login
- **RSA Key Management** - Use RSA key pairs for token signing
- **User Authentication** - Validate username and password
- **User Management** - Support user information (name, email, etc.)
- **Health Checks** - Provide `/health` endpoint
- **Containerized Deployment** - Complete Docker support

### Technology Stack
- **Language**: Go 1.20
- **Framework**: Standard library HTTP
- **Authentication**: JWT + RSA
- **Container**: Docker + Alpine Linux
- **Port**: 17101

## 🚀 Quick Start

### Build Image
```bash
./scripts/build.sh
```

### Start Service
```bash
./scripts/start.sh
```

### Check Status
```bash
./scripts/run.sh status
```

### View Logs
```bash
./scripts/run.sh logs
```

### Stop Service
```bash
./scripts/run.sh stop
```

## 📋 Scripts

### Build Scripts
- **`scripts/build.sh`** - Build Docker image
- **`scripts/gen-go-sum.sh`** - Generate go.sum file

### Runtime Scripts
- **`scripts/start.sh`** - Start service
- **`scripts/stop.sh`** - Stop service
- **`scripts/clean.sh`** - Clean containers and images
- **`scripts/test.sh`** - API testing script

## 🔧 Configuration

### Environment Variables
- `TZ=UTC` - Timezone setting

### Ports
- **17101** - HTTP API port

### Endpoints
- `GET /health` - Health check
- `POST /auth/login` - User login
- `GET /auth/me` - Get current user information
- `GET /build-info.json` - Build information
- `GET /VERSION` - Version information

## 🔐 Authentication

### Login Request
```bash
curl -X POST http://localhost:17101/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"x-operator","password":"x-operator"}'
```

### Get User Information
```bash
curl -X GET http://localhost:17101/auth/me \
  -H "Authorization: Bearer YOUR_TOKEN"
```

### Response Format
```json
{
  "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "type": "Bearer"
}
```

## 🔒 Security

### RSA Keys
- **Private Key**: `private.pem` - For token signing
- **Public Key**: `public.pem` - For token verification
- **Format**: PKCS8/PKCS1 auto-detection

### User Management
- Default users: `x-operator`, `x-observer`, `x-guest`, `x-superadmin`
- User information: Includes name, email and other details
- Password verification: bcrypt

## 📊 Monitoring

### Health Check
```bash
curl http://localhost:17101/health
```

### Build Information
```bash
curl http://localhost:17101/build-info.json
```

### Version Information
```bash
curl http://localhost:17101/VERSION
```

## 🧪 Testing

### API Testing
```bash
# Run all tests
./scripts/test.sh all

# Individual tests
./scripts/test.sh health   # Health check
./scripts/test.sh build    # Build info
./scripts/test.sh version  # Version info
./scripts/test.sh login    # Login functionality
./scripts/test.sh invalid  # Invalid endpoints
```

## 🐛 Troubleshooting

### Common Issues

1. **Private Key Parsing Error**
   ```bash
   # Regenerate keys
   cd ../brick-x-webapp && ./scripts/generate_keys.sh
   cd ../brick-x-auth-service && ./scripts/build.sh
   ```

2. **Port Already in Use**
   ```bash
   # Check port usage
   sudo lsof -i :17101
   
   # Stop existing container
   ./scripts/run.sh stop
   ```

3. **Container Won't Start**
   ```bash
   # Check image
   docker images | grep brick-x-auth
   
   # View logs
   ./scripts/run.sh logs
   ```

### Debug Commands
```bash
# Check container status
./scripts/run.sh status

# View detailed logs
./scripts/run.sh logs -f

# Test health check
curl http://localhost:17101/health

# Check container details
docker inspect el-brick-x-auth
```

## 🎯 Best Practices

1. **Build before running** - Ensure image exists
2. **Check health status** - Verify service is healthy after startup
3. **Monitor logs** - Use `./scripts/run.sh logs` to view output
4. **Update keys regularly** - Periodically regenerate RSA key pairs
5. **Backup configuration** - Backup `config.json` and key files

## 📞 Support

For issues or questions:
1. Check service status: `./scripts/run.sh status`
2. View service logs: `./scripts/run.sh logs`
3. Verify configuration: Check `config.json`
4. Confirm key files: Check `private.pem` and `public.pem`
5. Test endpoints: Use curl to test API endpoints 