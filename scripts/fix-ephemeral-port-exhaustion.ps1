# ============================================================================
# Windows Ephemeral Port Exhaustion Fix
# ============================================================================
# Problem: VPN disconnects, browser timeouts, network failures due to
#          ephemeral port pool exhaustion. Common with VPNs, Docker, WSL,
#          Hyper-V, and applications making many concurrent connections.
#
# Symptoms:
#   - Browser randomly disconnects, needs VPN refresh to resume
#   - Event Log shows: "A request to allocate an ephemeral port number 
#     from the global TCP/UDP port space has failed due to all such 
#     ports being in use"
#
# Solution: Expand port range from ~16K to ~64K and reduce TIME_WAIT
#
# REQUIRES: Run as Administrator
# REQUIRES: Reboot after running
#
# Last Updated: 2025-12-30
# ============================================================================

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "EPHEMERAL PORT EXHAUSTION FIX" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan

# ============================================
# Check current settings
# ============================================
Write-Host "`n[INFO] Current TCP dynamic port range:" -ForegroundColor Yellow
netsh int ipv4 show dynamicport tcp

Write-Host "`n[INFO] Current UDP dynamic port range:" -ForegroundColor Yellow
netsh int ipv4 show dynamicport udp

# ============================================
# Apply fixes
# ============================================
Write-Host "`n[FIX] Expanding TCP dynamic port range..." -ForegroundColor Green
netsh int ipv4 set dynamicport tcp start=1025 num=64510

Write-Host "[FIX] Expanding UDP dynamic port range..." -ForegroundColor Green
netsh int ipv4 set dynamicport udp start=1025 num=64510

Write-Host "[FIX] Reducing TIME_WAIT delay from 240s to 30s..." -ForegroundColor Green
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpTimedWaitDelay" -Value 30 -Type DWord

Write-Host "[FIX] Setting MaxUserPort to 65534..." -ForegroundColor Green
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "MaxUserPort" -Value 65534 -Type DWord

# ============================================
# Verify changes
# ============================================
Write-Host "`n[VERIFY] New TCP dynamic port range:" -ForegroundColor Yellow
netsh int ipv4 show dynamicport tcp

Write-Host "`n[VERIFY] New UDP dynamic port range:" -ForegroundColor Yellow
netsh int ipv4 show dynamicport udp

Write-Host "`n[VERIFY] Registry settings:" -ForegroundColor Yellow
$params = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -ErrorAction SilentlyContinue
Write-Host "  TcpTimedWaitDelay: $($params.TcpTimedWaitDelay)" -ForegroundColor Gray
Write-Host "  MaxUserPort: $($params.MaxUserPort)" -ForegroundColor Gray

Write-Host "`n" + "=" * 70 -ForegroundColor Green
Write-Host "SUCCESS! Reboot required to apply changes." -ForegroundColor Green
Write-Host "=" * 70 -ForegroundColor Green
