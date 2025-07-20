# Brick X Auth Service

Brick X authentication service providing JWT token generation and validation functionality.

## 🏗️ Architecture

### Features
- **JWT Token Generation** - Generate access tokens after user login
- **RSA Key Management** - Use RSA key pairs for token signing
- **User Authentication** - Validate username and password
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
./scripts/run.sh start
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

### Complete Development Workflow
```bash
# Method 1: One-liner
./scripts/build.sh && ./scripts/start.sh && ./scripts/test.sh all

# Method 2: Step by step
./scripts/build.sh             # Build
./scripts/start.sh             # Start
./scripts/test.sh all          # Test
./scripts/stop.sh --remove     # Stop and remove container
./scripts/clean.sh             # Clean images
```

### Container Management
```bash
# Start service
./scripts/start.sh

# Force restart
./scripts/start.sh --force

# Check status
docker ps --filter name=el-brick-x-auth

# View logs
docker logs el-brick-x-auth

# Stop service
./scripts/stop.sh              # Stop service
./scripts/stop.sh --remove     # Stop and remove container

# Clean containers and images
./scripts/clean.sh                    # Clean container and latest image
./scripts/clean.sh --container        # Clean container only
./scripts/clean.sh --image v1.0.0     # Clean specific image version
./scripts/clean.sh --all --force      # Force clean everything
```

## 📋 Scripts

### Build Scripts
- **`scripts/build.sh`** - Build Docker image
- **`scripts/gen-go-sum.sh`** - Generate go.sum file

### Runtime Scripts
- **`scripts/run.sh`** - Container lifecycle management
- **`scripts/test.sh`** - API testing script
- **`scripts/dev.sh`** - Complete development workflow

## 🔧 Configuration

### Environment Variables
- `TZ=UTC` - Timezone setting

### Ports
- **17101** - HTTP API port

### Endpoints
- `GET /health` - Health check
- `POST /login` - User login
- `GET /build-info.json` - Build information
- `GET /VERSION` - Version information

## 🔐 Authentication

### Login Request
```bash
curl -X POST http://localhost:17101/login \
  -H "Content-Type: application/json" \
  -d '{"username":"x-admin","password":"admin123"}'
```

### Response Format
```json
{
  "token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 3600
}
```

## 🔒 Security

### RSA Keys
- **Private Key**: `private.pem` - For token signing
- **Public Key**: `public.pem` - For token verification
- **Format**: PKCS8/PKCS1 auto-detection

### User Management
- Default user: `x-admin` / `admin123`
- Password verification: bcrypt (temporarily using simple string comparison)

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

### Test Coverage
- ✅ **Health Check** - `/health` endpoint
- ✅ **Build Info** - `/build-info.json` endpoint
- ✅ **Version Info** - `/VERSION` endpoint
- ✅ **Login Functionality** - `/login` endpoint (success/failure/invalid JSON)
- ✅ **Error Handling** - 404, 405 error responses

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