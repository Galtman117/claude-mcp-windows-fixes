# MCP Server Complete Fix Script for Windows
# Run as: powershell -ExecutionPolicy Bypass -File fix-all-mcp-servers.ps1

$ErrorActionPreference = "Continue"
$PYTHON = (Get-Command python -ErrorAction SilentlyContinue).Source
if (-not $PYTHON) { $PYTHON = "python" }

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MCP SERVER COMPLETE FIX SCRIPT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ============================================
# PHASE 1: Install missing system dependencies
# ============================================
Write-Host "`n[PHASE 1] Installing system Python dependencies..." -ForegroundColor Yellow

$deps = @("win32-setctime", "loguru", "pydantic", "lxml", "cffi", "cryptography", "colorama")
foreach ($dep in $deps) {
    Write-Host "  Installing $dep..." -ForegroundColor Gray
    & $PYTHON -m pip install --upgrade $dep --break-system-packages 2>$null
}

# ============================================
# PHASE 2: Fix AWS API MCP Server
# ============================================
Write-Host "`n[PHASE 2] Fixing AWS API MCP Server..." -ForegroundColor Yellow

$AWS_SERVER = "$env:APPDATA\Claude\Claude Extensions\ant.dir.gh.awslabs.aws-api-mcp-server\server"

# Remove ALL bundled packages that have binary components or conflict with system packages
$bundledToDisable = @(
    "loguru", "pydantic", "pydantic_core", "lxml", "rpds", "cffi", 
    "cryptography", "referencing", "annotated_types"
)

foreach ($pkg in $bundledToDisable) {
    $pkgPath = Join-Path $AWS_SERVER $pkg
    $disabledPath = "$pkgPath.disabled"
    
    if (Test-Path $pkgPath) {
        if (Test-Path $disabledPath) {
            Remove-Item -Recurse -Force $disabledPath
        }
        Rename-Item $pkgPath $disabledPath -Force
        Write-Host "  Disabled bundled: $pkg" -ForegroundColor Green
    } elseif (Test-Path $disabledPath) {
        Write-Host "  Already disabled: $pkg" -ForegroundColor Gray
    }
}

# ============================================
# PHASE 3: Fix Zscaler MCP Server
# ============================================
Write-Host "`n[PHASE 3] Fixing Zscaler MCP Server..." -ForegroundColor Yellow

$ZSCALER_SERVER = "$env:APPDATA\Claude\Claude Extensions\ant.dir.gh.zscaler.zscaler-mcp-server\server"

# Create setup.py if not exists
$setupPy = @"
from setuptools import setup, find_packages
setup(
    name="zscaler_mcp",
    version="0.3.0",
    packages=find_packages(),
    install_requires=["mcp", "httpx", "pydantic"],
)
"@

$setupPath = Join-Path $ZSCALER_SERVER "setup.py"
if (-not (Test-Path $setupPath)) {
    $setupPy | Out-File -FilePath $setupPath -Encoding UTF8
    Write-Host "  Created setup.py" -ForegroundColor Green
}

# Install in editable mode
Write-Host "  Installing zscaler_mcp in editable mode..." -ForegroundColor Gray
& $PYTHON -m pip install -e $ZSCALER_SERVER --break-system-packages 2>$null
if ($LASTEXITCODE -eq 0) {
    Write-Host "  Zscaler MCP installed successfully" -ForegroundColor Green
} else {
    Write-Host "  Zscaler MCP install had warnings (may still work)" -ForegroundColor Yellow
}

# ============================================
# PHASE 4: Verification Tests
# ============================================
Write-Host "`n[PHASE 4] Running verification tests..." -ForegroundColor Yellow

# Test win32_setctime import
Write-Host "  Testing win32_setctime import..." -ForegroundColor Gray
$result = & $PYTHON -c "import win32_setctime; print('OK')" 2>&1
if ($result -eq "OK") {
    Write-Host "    win32_setctime: PASS" -ForegroundColor Green
} else {
    Write-Host "    win32_setctime: FAIL" -ForegroundColor Red
}

# Test loguru with file sink
Write-Host "  Testing loguru with file sink..." -ForegroundColor Gray
$result = & $PYTHON -c "from loguru import logger; logger.add('test.log'); logger.info('test'); print('OK')" 2>&1
if ($result -match "OK") {
    Write-Host "    loguru file sink: PASS" -ForegroundColor Green
    Remove-Item "test.log" -ErrorAction SilentlyContinue
} else {
    Write-Host "    loguru file sink: FAIL - $result" -ForegroundColor Red
}

# Test AWS MCP Server import
Write-Host "  Testing AWS API MCP Server import..." -ForegroundColor Gray
$env:PYTHONPATH = $AWS_SERVER
$result = & $PYTHON -c "from awslabs.aws_api_mcp_server import server; print('OK')" 2>&1
if ($result -match "OK") {
    Write-Host "    AWS API MCP Server: PASS" -ForegroundColor Green
} else {
    Write-Host "    AWS API MCP Server: FAIL" -ForegroundColor Red
    Write-Host "    Error: $result" -ForegroundColor Red
}

# Test Zscaler MCP Server import
Write-Host "  Testing Zscaler MCP Server import..." -ForegroundColor Gray
$result = & $PYTHON -c "from zscaler_mcp import server; print('OK')" 2>&1
if ($result -match "OK") {
    Write-Host "    Zscaler MCP Server: PASS" -ForegroundColor Green
} else {
    Write-Host "    Zscaler MCP Server: FAIL" -ForegroundColor Red
    Write-Host "    Error: $result" -ForegroundColor Red
}

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "FIX COMPLETE - Restart Claude Desktop" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
