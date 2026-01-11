#!/usr/bin/bash
set -euo pipefail

# Nostalgia Arcade: Hardware-Agnostic Performance Tuning
# Optimizes system performance for generic x86-64 hardware
# Includes auto-detection for Intel/AMD processors

echo "⚡ Arcade: Starting hardware detection and tuning..."

# Detect CPU type
detect_cpu() {
    if grep -q "Intel" /proc/cpuinfo; then
        echo "intel"
    elif grep -q "AMD" /proc/cpuinfo; then
        echo "amd"
    else
        echo "generic"
    fi
}

CPU_TYPE=$(detect_cpu)
echo "🎮 Detected CPU type: $CPU_TYPE"

# ── CPU Governor Configuration ─────────────────────────────────────────────────
echo "⚙️  Configuring CPU governor..."

if command -v cpupower >/dev/null 2>&1; then
    cpupower frequency-set --governor schedutil 2>/dev/null || true
else
    for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
        if [[ -f "${cpu}/scaling_governor" ]]; then
            echo "schedutil" > "${cpu}/scaling_governor" 2>/dev/null || true
        fi
    done
fi

echo "✓ CPU governor configured"

# ── Intel-specific Turbo Boost ────────────────────────────────────────────────
if [[ "$CPU_TYPE" == "intel" ]]; then
    echo "🚀 Enabling Intel Turbo Boost..."
    if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
        echo "0" > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
        echo "✓ Turbo Boost enabled"
    fi
fi

# ── AMD-specific Power Management ──────────────────────────────────────────────
if [[ "$CPU_TYPE" == "amd" ]]; then
    echo "🔧 Configuring AMD power management..."
    # Enable CPU frequency scaling
    if [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
        echo "1" > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || true
        echo "✓ Boost enabled"
    fi
fi

# ── I/O Scheduler Optimization ─────────────────────────────────────────────────
echo "💾 Optimizing I/O scheduler..."

for scheduler in /sys/block/*/queue/scheduler; do
    if [[ -f "${scheduler}" ]]; then
        if grep -q mq-deadline "${scheduler}"; then
            echo "mq-deadline" > "${scheduler}" 2>/dev/null || true
        elif grep -q bfq "${scheduler}"; then
            echo "bfq" > "${scheduler}" 2>/dev/null || true
        fi
    fi
done

echo "✓ I/O scheduler optimized"

# ── Thermal Management ─────────────────────────────────────────────────────────
echo "🌡️  Configuring thermal management..."

if command -v thermald >/dev/null 2>&1; then
    systemctl enable thermald 2>/dev/null || true
    systemctl start thermald 2>/dev/null || true
    echo "✓ Thermal daemon enabled"
fi

# ── Memory Management ─────────────────────────────────────────────────────────
echo "🧠 Optimizing memory management..."

sysctl -w vm.swappiness=10 2>/dev/null || true
sysctl -w vm.vfs_cache_pressure=50 2>/dev/null || true

# Enable transparent huge pages
echo "1" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null || true
echo "madvise" > /sys/kernel/mm/transparent_hugepage/shmem_enabled 2>/dev/null || true

echo "✓ Memory management optimized"

# ── Network Stack Optimization ────────────────────────────────────────────────
echo "🌐 Optimizing network stack..."

sysctl -w net.core.rmem_max=134217728 2>/dev/null || true
sysctl -w net.core.wmem_max=134217728 2>/dev/null || true
sysctl -w net.ipv4.tcp_rmem="4096 87380 67108864" 2>/dev/null || true
sysctl -w net.ipv4.tcp_wmem="4096 65536 67108864" 2>/dev/null || true

echo "✓ Network stack optimized"

# ── USB Power Management ───────────────────────────────────────────────────────
echo "🔌 Configuring USB power management..."

for device in /sys/bus/usb/devices/*/power/autosuspend; do
    if [[ -f "${device}" ]]; then
        echo "-1" > "${device}" 2>/dev/null || true
    fi
done

echo "✓ USB power management configured"

# ── Service Configuration ──────────────────────────────────────────────────────
echo "🛑 Configuring services for generic hardware..."

# Optional: Disable services not needed on desktop
SERVICES_TO_DISABLE=(
    "bluetooth.service"
)

for service in "${SERVICES_TO_DISABLE[@]}"; do
    if systemctl is-enabled "${service}" >/dev/null 2>&1; then
        systemctl disable "${service}" 2>/dev/null || true
    fi
done

echo "✓ Services configured"

# ── Summary ────────────────────────────────────────────────────────────────────
echo ""
echo "✅ Arcade hardware tuning complete!"
echo "🎮 System optimized for generic x86-64 hardware"
echo "🔍 CPU Type: $CPU_TYPE"
echo ""
