#!/bin/bash
clear
echo "=== ALIS F-35 SHIPBOARD STATUS ==="
echo "Time: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""
echo "Web Repo: $(ls /var/www/html/repos/alis-shipboard-packages/Packages/*.rpm 2>/dev/null | wc -l) RPMs"
echo "USB Bundle: $(ls -lh /tmp/alis-usb-200mb.img | awk '{print $5}' || echo 'N/A')"
echo "HTTP: $(systemctl is-active httpd)"
echo ""
echo "Filesystem:"
df -h /var/www/html 2>/dev/null | tail -1
echo ""
echo "Recent HTTP Access:"
sudo tail -5 /var/log/httpd/access_log 2>/dev/null | tail -3

