# Container Registry Troubleshooting

## Error: 403 Forbidden from ghcr.io

### Symptoms
```
Error: creating build container: initializing source docker://ghcr.io/ublue-os/bazzite-kinoite:latest: 
Requesting bearer token: invalid status code from registry 403 (Forbidden)
```

### Causes
1. **Network connectivity issue** - Can't reach GitHub Container Registry
2. **Rate limiting** - Too many requests to the registry
3. **Authentication timeout** - Registry credentials expired or incorrect
4. **DNS issues** - Can't resolve ghcr.io hostname
5. **Firewall/Proxy** - Network blocking the registry

### Solutions

#### Solution 1: Check Network Connectivity

```bash
# Test if you can reach the registry
curl -I https://ghcr.io

# Test DNS resolution
nslookup ghcr.io
dig ghcr.io

# Ping the registry (may be blocked)
ping ghcr.io
```

If these fail, you have a network connectivity issue. Check:
- Internet connection
- Firewall rules
- VPN/Proxy settings

#### Solution 2: Clear Podman Cache and Retry

```bash
# Clear podman/buildah cache
podman system prune -a

# Remove any partial images
podman rmi ghcr.io/ublue-os/bazzite-kinoite

# Try building again
just rebuild-qcow2
```

#### Solution 3: Wait and Retry

Sometimes the registry is temporarily unavailable or rate-limited.

```bash
# Wait a few minutes, then try again
sleep 300
just rebuild-qcow2
```

#### Solution 4: Use an Alternative Mirror

If ghcr.io is consistently unavailable, you may need to use a mirror or alternative registry.

**Option A: Use Docker Hub instead** (if available in your region)
Edit `images/nostalgia-crt/Containerfile`:
```dockerfile
# Change from:
FROM ghcr.io/ublue-os/bazzite-kinoite:latest

# To:
FROM docker.io/ublue-os/bazzite-kinoite:latest
```

**Option B: Use Quay.io mirror**
```dockerfile
FROM quay.io/ublue-os/bazzite-kinoite:latest
```

#### Solution 5: Configure Podman to Use Mirrors

Create/edit `~/.config/containers/registries.conf`:

```toml
[[registry]]
prefix = "ghcr.io"
location = "ghcr.io"

# Add fallback
[[registry.mirror]]
location = "mirror.example.com"

# Configure authentication if needed
[[registry]]
prefix = "ghcr.io"
username = "your-username"
password = "your-token"
```

#### Solution 6: Check Podman Configuration

```bash
# Check podman version
podman version

# Check system connectivity
podman info | grep -A 20 "registries"

# Verify registries are configured
cat ~/.config/containers/registries.conf

# Check for proxy settings
podman info | grep -i proxy
```

#### Solution 7: Restart Podman Daemon

```bash
# Stop podman
systemctl --user stop podman

# Clear cache
podman system prune -a --force

# Restart
systemctl --user start podman

# Try again
just rebuild-qcow2
```

### If You're Behind a Proxy

Configure podman to use your proxy:

```bash
# Create/edit ~/.config/systemd/user/podman.socket.d/proxy.conf
mkdir -p ~/.config/systemd/user/podman.socket.d/

cat > ~/.config/systemd/user/podman.socket.d/proxy.conf << 'EOF'
[Service]
Environment="HTTP_PROXY=http://proxy.example.com:8080"
Environment="HTTPS_PROXY=http://proxy.example.com:8080"
Environment="NO_PROXY=localhost,127.0.0.1"
EOF

# Reload and restart
systemctl --user daemon-reload
systemctl --user restart podman
```

### If You're in a Restricted Network

If your network blocks container registries entirely:

1. **Use a different network** - Try on a personal WiFi or mobile hotspot
2. **Pre-download the base image** on a different network
3. **Use a local mirror** - If your organization has one
4. **Contact your network administrator** - Request access to container registries

### Checking Registry Status

```bash
# Check if ghcr.io is up
curl -v https://ghcr.io

# Check what token is being requested
podman pull ghcr.io/ublue-os/bazzite-kinoite:latest -vvv

# Check podman's authentication
podman login --help
podman logout ghcr.io
```

### Regional Issues

Some regions may have:
- GFW (Great Firewall) blocking
- Local ISP filtering
- Regional registry restrictions
- Different authentication requirements

**Solutions**:
- Use VPN to access registry
- Use regional mirrors if available
- Contact registry for regional access

### If All Else Fails

Contact the Bazzite/UBlue project:
- GitHub Issues: https://github.com/ublue-os/bazzite
- Discord: https://discord.gg/ublue

Provide them with:
- Full error message
- Your location/region
- Network configuration (proxy, firewall, etc.)
- Podman version

### Quick Reference

```bash
# Diagnose connectivity
curl -I https://ghcr.io
podman info
podman pull --help

# Fix most common issues
podman system prune -a
just clean
just rebuild-qcow2

# Check if registry is accessible
podman inspect ghcr.io/ublue-os/bazzite-kinoite:latest
```

---

## Common Errors and Solutions

### Error 401 Unauthorized
**Cause**: Need to authenticate to the registry
**Solution**: Run `podman login ghcr.io` (may not be needed for public images)

### Error 429 Too Many Requests
**Cause**: Rate limited
**Solution**: Wait 5-10 minutes and try again

### Error 502 Bad Gateway
**Cause**: Registry server issue
**Solution**: Wait and retry, or check status page

### Error 503 Service Unavailable
**Cause**: Registry is down for maintenance
**Solution**: Wait for registry to come back online

### Timeout Error
**Cause**: Network too slow or registry too far away
**Solution**: Check network speed, try a mirror, or increase timeout

---

## Prevention

### Keep Things Updated
```bash
podman version  # Should be recent
buildah version
```

### Monitor Registry Health
- Subscribe to GitHub status page
- Check registry status before starting builds
- Have a backup plan if registry is down

### Use Specific Tags
Instead of `latest`, use specific versions:
```dockerfile
FROM ghcr.io/ublue-os/bazzite-kinoite:38.20240115
```

This prevents version mismatches and rebuilds.
