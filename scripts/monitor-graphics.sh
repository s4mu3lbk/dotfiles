#!/usr/bin/env bash

# Graphics and video system monitoring script
echo "=== Graphics System Health Check ==="
echo "Date: $(date)"
echo

echo "1. GPU Status:"
lspci | grep -E "(VGA|3D|Display)" || echo "No GPU info available"
echo

echo "2. Intel Graphics Driver Status:"
lsmod | grep i915 || echo "i915 module not loaded"
echo

echo "3. VA-API Status:"
vainfo 2>/dev/null | head -10 || echo "VA-API not available"
echo

echo "4. Memory Usage:"
free -h
echo

echo "5. Graphics Memory Usage:"
if [ -f /sys/kernel/debug/dri/0/i915_gem_objects ]; then
    echo "Intel GPU memory usage available in debugfs"
else
    echo "Intel GPU memory info not available (debugfs not mounted)"
fi
echo

echo "6. Recent Graphics-Related Errors:"
journalctl --since "1 hour ago" | grep -E "(i915|drm|gpu|chrome|vivaldi)" | tail -5 || echo "No recent graphics errors"
echo

echo "7. Browser Process Status:"
pgrep -f "(chrome|vivaldi|firefox)" | wc -l | xargs echo "Active browser processes:"
echo

echo "8. System Load:"
uptime
echo

echo "=== Health Check Complete ==="
echo "Run this script regularly to monitor system stability."
echo "If you see repeated errors, consider:"
echo "- Updating graphics drivers"
echo "- Checking for overheating"
echo "- Running memtest86+ for memory issues"
