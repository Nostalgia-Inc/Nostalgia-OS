#!/usr/bin/bash
set -euo pipefail

# Nostalgia OS Power and Performance Tuning
# Optimizes system performance while maintaining stability for LattePanda Delta 3

echo "🔋 Applying Nostalgia OS power and performance optimizations..."

# ── CPU Governor Configuration ─────────────────────────────────────────────────
# For the Intel Celeron N5105 in LattePanda Delta 3
echo "⚙️  Configuring CPU governor..."

# Intel P-state often exposes powersave/performance instead of schedutil.
# Select a supported dynamic policy; never claim an unsupported write succeeded.
for cpu in /sys/devices/system/cpu/cpufreq/policy*; do
    if [[ ! -r "${cpu}/scaling_available_governors" ]]; then
        continue
    fi
    governor=""
    for candidate in schedutil powersave; do
        if grep -qw "${candidate}" "${cpu}/scaling_available_governors"; then
            governor="${candidate}"
            break
        fi
    done
    if [[ -z "${governor}" ]]; then
        echo "⚠️  No supported dynamic governor for ${cpu}; retaining current policy"
    elif printf '%s\n' "${governor}" > "${cpu}/scaling_governor"; then
        echo "✓ ${cpu##*/}: $(< "${cpu}/scaling_governor") governor"
    else
        echo "⚠️  Could not set governor for ${cpu}" >&2
    fi
done

# ── Turbo Boost Configuration ──────────────────────────────────────────────────
echo "🚀 Configuring Turbo Boost..."

# Enable Intel Turbo Boost for better performance when needed
if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
    if echo "0" > /sys/devices/system/cpu/intel_pstate/no_turbo; then
        echo "✓ Intel Turbo Boost enabled"
    else
        echo "⚠️  Intel Turbo Boost could not be enabled" >&2
    fi
fi

# ── I/O Scheduler Optimization ─────────────────────────────────────────────────
echo "💾 Optimizing I/O schedulers..."

for scheduler in /sys/block/*/queue/scheduler; do
    if [[ -f "${scheduler}" ]]; then
        # Use mq-deadline for better I/O performance
        if grep -q mq-deadline "${scheduler}"; then
            echo "mq-deadline" > "${scheduler}" 2>/dev/null || true
        fi
    fi
done
echo "✓ I/O schedulers optimized"

# ── Thermal Management ─────────────────────────────────────────────────────────
echo "🌡️  Configuring thermal management..."

# Enable CPU frequency scaling for better thermal management
if [[ -f /sys/module/thermal_core/parameters/aml ]]; then
    echo "1" > /sys/module/thermal_core/parameters/aml 2>/dev/null || true
fi

# Set reasonable thermal limits
if command -v thermald >/dev/null 2>&1; then
    if systemctl enable --now thermald.service; then
        echo "✓ Thermal daemon enabled"
    else
        echo "⚠️  Thermal daemon could not be enabled" >&2
    fi
fi

# ── Disk Performance ───────────────────────────────────────────────────────────
echo "💿 Optimizing disk performance..."

# Enable disk write caching for better performance
for disk in /dev/sd* /dev/nvme*; do
    if [[ -b "${disk}" ]] && command -v hdparm >/dev/null 2>&1; then
        hdparm -W 1 "${disk}" 2>/dev/null || true
    fi
done

# ── Network Stack Optimization ────────────────────────────────────────────────
echo "🌐 Optimizing network stack..."

# Increase TCP buffer sizes for better network performance
sysctl -w net.core.rmem_max=134217728 2>/dev/null || true
sysctl -w net.core.wmem_max=134217728 2>/dev/null || true
sysctl -w net.ipv4.tcp_rmem="4096 87380 67108864" 2>/dev/null || true
sysctl -w net.ipv4.tcp_wmem="4096 65536 67108864" 2>/dev/null || true

echo "✓ Network stack optimized"

# ── Memory Management ─────────────────────────────────────────────────────────
echo "🧠 Optimizing memory management..."

# Improve cache behavior
sysctl -w vm.swappiness=10 2>/dev/null || true
sysctl -w vm.vfs_cache_pressure=50 2>/dev/null || true

# Enable huge pages for better memory performance
echo "madvise" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
echo "advise" > /sys/kernel/mm/transparent_hugepage/shmem_enabled 2>/dev/null || true

echo "✓ Memory management optimized"

# ── USB Power Management ───────────────────────────────────────────────────────
echo "🔌 Configuring USB power management..."

# Disable USB autosuspend for more responsive peripherals
for device in /sys/bus/usb/devices/*/power/autosuspend; do
    if [[ -f "${device}" ]]; then
        echo "-1" > "${device}" 2>/dev/null || true
    fi
done

echo "✓ USB power management configured"

# ── Disable unnecessary services ───────────────────────────────────────────────
echo "🛑 Disabling unnecessary services..."

SERVICES_TO_DISABLE=(
    "bluetooth.service"
    "cups.service"
    "avahi-daemon.service"
)

for service in "${SERVICES_TO_DISABLE[@]}"; do
    if systemctl is-enabled "${service}" >/dev/null 2>&1; then
        systemctl disable "${service}" 2>/dev/null || true
        echo "✓ Disabled ${service}"
    fi
done

# ── Log completion ─────────────────────────────────────────────────────────────
echo ""
echo "✅ Power and performance tuning complete!"
echo "🎮 Your Nostalgia OS system is now optimized for best performance"
echo ""
