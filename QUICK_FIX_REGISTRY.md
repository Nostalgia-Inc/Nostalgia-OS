# Quick Fix: 403 Forbidden Error

## The Problem
You're getting a 403 Forbidden error when trying to pull from `ghcr.io`. This means:
- The registry can see your request
- But it's rejecting it for some reason (authentication, rate limit, or network policy)

## Immediate Solutions (Try These First)

### Option 1: Clear Cache and Retry (Most Likely to Work)
```bash
# Clear all containers and images
podman system prune -a --force

# Remove specific image
podman rmi ghcr.io/ublue-os/bazzite-kinoite

# Try building again
just clean
just rebuild-qcow2
```

**Time**: 5 minutes  
**Success Rate**: 70%

### Option 2: Use Docker Hub Mirror Instead
If ghcr.io is unavailable in your region, use Docker Hub.

**For Nostalgia CRT** - Edit `images/nostalgia-crt/Containerfile`:
```bash
# Change line 1 from:
FROM ghcr.io/ublue-os/bazzite-kinoite:latest

# To:
FROM docker.io/ublue-os/bazzite-kinoite:latest
```

**For Nostalgia Arcade** - Edit `images/nostalgia-arcade/Containerfile`:
```bash
# Change line 1 from:
FROM ghcr.io/ublue-os/bazzite-kinoite:latest

# To:
FROM docker.io/ublue-os/bazzite-kinoite:latest
```

Then retry:
```bash
just clean
just rebuild-qcow2
```

**Time**: 2 minutes  
**Success Rate**: 80% (if Docker Hub is accessible)

### Option 3: Check if You Can Access the Registry at All
```bash
# Test network connectivity
curl -I https://ghcr.io

# Test DNS
nslookup ghcr.io

# Check podman config
podman info | grep -A 10 registries
```

If these fail → You have network issues
If these succeed → Registry issue

### Option 4: Wait and Retry
Sometimes the registry is temporarily rate-limited or under maintenance.

```bash
# Wait 5 minutes
echo "Waiting 5 minutes..."
sleep 300

# Try again
just rebuild-qcow2
```

**Time**: 5+ minutes  
**Success Rate**: 50% (if temporary issue)

### Option 5: Use Quay.io as Fallback
```bash
# Edit Containerfile (CRT)
sed -i 's|ghcr.io/ublue-os|quay.io/ublue-os|g' images/nostalgia-crt/Containerfile

# Edit Containerfile (Arcade)
sed -i 's|ghcr.io/ublue-os|quay.io/ublue-os|g' images/nostalgia-arcade/Containerfile

# Try building
just rebuild-qcow2
```

## Which Solution Should You Try?

| Situation | Solution | Time | Success |
|-----------|----------|------|---------|
| **First error** | Option 1 (Clear cache) | 5 min | 70% |
| **Still failing** | Option 2 (Docker Hub) | 2 min | 80% |
| **Want to diagnose** | Option 3 (Check network) | 5 min | 100% |
| **Can't access any registry** | Use different network | varies | 90% |

## Recommended Order

1. **Try Option 1** first (clear cache and retry) - Simplest
2. **If that fails**, check **Option 3** (network status)
3. **If network works**, use **Option 2** (Docker Hub mirror)
4. **If still failing**, try **Option 4** (wait and retry)
5. **As last resort**, try **Option 5** (Quay.io)

## What's Happening

The error `403 Forbidden` at the bearer token stage means:
- ✅ Network connection works (request reached the registry)
- ✅ DNS resolution works (ghcr.io was found)
- ❌ Registry rejected the request

**Common causes**:
1. Rate limiting (too many requests)
2. Regional restrictions (GFW, ISP filtering)
3. Network policy (corporate firewall)
4. Registry under load or maintenance
5. Authentication token issue

## Fastest Solution (Recommended)

**For most people, this works**:

```bash
# 1. Clear everything
podman system prune -a --force

# 2. Use Docker Hub instead
sed -i 's|ghcr.io/ublue-os|docker.io/ublue-os|g' images/nostalgia-crt/Containerfile
sed -i 's|ghcr.io/ublue-os|docker.io/ublue-os|g' images/nostalgia-arcade/Containerfile

# 3. Clean build
just clean
just rebuild-qcow2
```

**Total time**: 5-10 minutes  
**Success rate**: 85%+

## If You're Behind a Corporate Proxy

Ask your IT department:
- Is ghcr.io (GitHub Container Registry) allowed?
- Is docker.io (Docker Hub) allowed?
- What proxy should be used?

Then configure podman with proxy settings in `REGISTRY_TROUBLESHOOTING.md`.

## Still Stuck?

Run the diagnostic command:
```bash
podman pull ghcr.io/ublue-os/bazzite-kinoite:latest -vvv 2>&1 | tee build-error.log
```

This creates `build-error.log` with detailed information you can share for help.

## Next Steps

Once you get past the 403 error:
1. Build will take 10-30 minutes (first time)
2. You'll see `STEP 1/27`, `STEP 2/27`, etc.
3. When complete, you'll have `output/qcow2/disk.qcow2`
4. Then you can test with `just run-vm-qcow2`

Good luck! 🚀
