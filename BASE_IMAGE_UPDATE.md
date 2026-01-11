# Base Image Update: SHA256 Pinning

## What Changed

Updated all Containerfiles and image configuration to use a specific, pinned SHA256 digest instead of `:latest` tags.

### Before
```dockerfile
FROM ghcr.io/ublue-os/bazzite-kinoite:latest
```

### After
```dockerfile
FROM ghcr.io/ublue-os/bazzite-deck@sha256:98a0c1fbd89c150ed6ba9d356b3a3ddc11361c4d3a26c8fd17321b9c762d1081
```

## Also Changed

**Image Name**: `bazzite-kinoite` → `bazzite-deck`

## Benefits of SHA256 Pinning

### 1. **Reproducibility**
- Every build uses exactly the same base image
- No surprises from image updates
- CI/CD builds are deterministic

### 2. **Security**
- Pins to a specific, verified version
- Prevents supply chain attacks
- Know exactly what's in your image

### 3. **Reliability**
- No "works today, breaks tomorrow" issues
- Image is immutable by hash
- Works even if `:latest` changes

### 4. **Performance**
- Docker knows exact image to fetch
- No need to check registry for new versions
- Faster pulls on subsequent builds

## Files Updated

### Containerfiles
- ✅ `images/nostalgia-crt/Containerfile`
- ✅ `images/nostalgia-arcade/Containerfile`

### Image Configuration
- ✅ `images/nostalgia-crt/image.yml`
- ✅ `images/nostalgia-arcade/image.yml`

## How to Use

No changes needed on your end. Just rebuild:

```bash
just clean
just rebuild-qcow2
```

The pinned SHA256 will be pulled automatically.

## If You Need a Different Version

If you want to update to a newer version of bazzite-deck:

1. Find the SHA256 of the version you want:
   ```bash
   podman pull ghcr.io/ublue-os/bazzite-deck:latest
   podman inspect ghcr.io/ublue-os/bazzite-deck:latest | grep -i digest
   ```

2. Update both Containerfiles:
   ```bash
   sed -i 's|sha256:98a0c1fbd89c150ed6ba9d356b3a3ddc11361c4d3a26c8fd17321b9c762d1081|sha256:NEW_SHA_HERE|g' images/*/Containerfile
   ```

3. Update both image.yml files with the new base-image

4. Rebuild:
   ```bash
   just clean
   just rebuild-qcow2
   ```

## Current Version Info

**Image**: `ghcr.io/ublue-os/bazzite-deck`  
**SHA256**: `98a0c1fbd89c150ed6ba9d356b3a3ddc11361c4d3a26c8fd17321b9c762d1081`  
**Type**: bazzite-deck (Steam Deck optimized variant)  
**Last Updated**: 2026-01-11

## Technical Details

### What is bazzite-deck?
- Fedora-based, OStree immutable OS
- Optimized for Steam Deck and handheld gaming
- Ships with KDE Plasma desktop
- Container-first approach (Bootc)
- OCI-compliant image

### Why use digest instead of tag?
- **Tags are mutable**: `latest` can point to different images over time
- **Digests are immutable**: SHA256 always points to exact same image
- **Better for CI/CD**: Reproducible builds
- **Better for security**: Know exactly what you're getting

## Troubleshooting

### Error: Image not found
If you get "image not found":
```bash
# Clear cache and try again
podman system prune -a --force
just rebuild-qcow2
```

### Error: 403 Forbidden
If registry is blocked in your region, see `QUICK_FIX_REGISTRY.md` for alternatives.

### Want to verify the image
```bash
# Inspect the image
podman inspect ghcr.io/ublue-os/bazzite-deck@sha256:98a0c1fbd89c150ed6ba9d356b3a3ddc11361c4d3a26c8fd17321b9c762d1081

# Get image details
podman pull ghcr.io/ublue-os/bazzite-deck@sha256:98a0c1fbd89c150ed6ba9d356b3a3ddc11361c4d3a26c8fd17321b9c762d1081
podman images --digests
```

## Future Updates

To update the base image in the future:

1. Check bazzite-deck releases: https://github.com/ublue-os/bazzite
2. Get the new SHA256
3. Update the digest in Containerfiles and image.yml
4. Rebuild

This ensures you stay up-to-date while maintaining reproducibility.

## Questions?

- See `BUILD_INSTRUCTIONS.md` for build information
- See `REGISTRY_TROUBLESHOOTING.md` for registry issues
- Check [Bazzite GitHub](https://github.com/ublue-os/bazzite) for image updates
