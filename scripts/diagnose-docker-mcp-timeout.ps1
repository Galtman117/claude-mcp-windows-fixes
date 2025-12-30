# ============================================================================
# Docker MCP Server Timeout Fix
# ============================================================================
# Problem: Claude Desktop times out during startup when too many Docker MCP
#          servers are enabled, especially if some have missing API keys or
#          are redundant with built-in Claude extensions.
#
# Symptoms:
#   - Claude Desktop hangs on "Initializing..." 
#   - Docker MCP servers fail to connect
#   - Timeout errors in Claude logs
#
# Root Cause: Docker MCP registry has a 120-second total initialization
#             timeout. Each server adds latency, and servers with missing
#             credentials or network issues compound the problem.
#
# Solution: Audit registry.yaml and disable unnecessary servers
#
# Last Updated: 2025-12-30
# ============================================================================

$ErrorActionPreference = "Continue"

$registryPath = "$env:USERPROFILE\.docker\mcp\registry.yaml"

Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "DOCKER MCP TIMEOUT DIAGNOSTIC" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan

# ============================================
# Check if registry exists
# ============================================
if (-not (Test-Path $registryPath)) {
    Write-Host "`n[ERROR] Docker MCP registry not found at:" -ForegroundColor Red
    Write-Host "  $registryPath" -ForegroundColor Gray
    Write-Host "`nDocker MCP may not be installed." -ForegroundColor Yellow
    exit 1
}

Write-Host "`n[INFO] Registry location:" -ForegroundColor Yellow
Write-Host "  $registryPath" -ForegroundColor Gray

# ============================================
# Display current configuration
# ============================================
Write-Host "`n[INFO] Current registry.yaml contents:" -ForegroundColor Yellow
Write-Host "-" * 50 -ForegroundColor Gray
Get-Content $registryPath
Write-Host "-" * 50 -ForegroundColor Gray

# ============================================
# Count enabled servers
# ============================================
$content = Get-Content $registryPath -Raw
$enabledCount = ([regex]::Matches($content, "enabled:\s*true")).Count
$disabledCount = ([regex]::Matches($content, "enabled:\s*false")).Count

Write-Host "`n[STATS]" -ForegroundColor Yellow
Write-Host "  Enabled servers:  $enabledCount" -ForegroundColor $(if ($enabledCount -gt 4) { "Red" } else { "Green" })
Write-Host "  Disabled servers: $disabledCount" -ForegroundColor Gray

# ============================================
# Recommendations
# ============================================
Write-Host "`n[RECOMMENDATIONS]" -ForegroundColor Yellow

if ($enabledCount -gt 4) {
    Write-Host "  WARNING: Too many servers enabled ($enabledCount)" -ForegroundColor Red
    Write-Host "  Consider disabling servers that:" -ForegroundColor Gray
    Write-Host "    - Require API keys you haven't configured" -ForegroundColor Gray
    Write-Host "    - Duplicate functionality in Claude extensions" -ForegroundColor Gray
    Write-Host "    - You don't actively use" -ForegroundColor Gray
}

Write-Host @"

  Common servers to DISABLE if not needed:
    - brave-search      (requires API key)
    - perplexity-ask    (requires API key)
    - dockerhub         (requires API key for private repos)
    - desktop-commander (redundant if using Claude's computer use)
    - context7          (redundant if using Claude's built-in docs)

  To disable a server, edit registry.yaml and set:
    enabled: false

  Registry location:
    $registryPath

"@ -ForegroundColor Gray

Write-Host "=" * 70 -ForegroundColor Cyan
Write-Host "Edit the file above, then restart Docker Desktop and Claude Desktop" -ForegroundColor Cyan
Write-Host "=" * 70 -ForegroundColor Cyan
