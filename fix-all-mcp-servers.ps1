# MCP Server Complete Fix Script for Windows
# Run as: powershell -ExecutionPolicy Bypass -File fix-all-mcp-servers.ps1
# Updated: 2025-12-30

$ErrorActionPreference = "Continue"
$PYTHON = "C:\Users\Falco\AppData\Local\Programs\Python\Python313\python.exe"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MCP SERVER COMPLETE FIX SCRIPT" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

# ============================================
# PHASE 1: Install ALL system Python dependencies
# ============================================
Write-Host "`n[PHASE 1] Installing system Python dependencies..." -ForegroundColor Yellow

$deps = @(
    # Core system dependencies
    "win32-setctime", "loguru", "colorama",
    
    # Packages with compiled binaries (need Windows versions)
    "rpds-py", "pydantic-core", "pydantic", "pydantic-settings",
    "orjson", "jiter", "charset-normalizer", "markupsafe",
    "PyYAML", "websockets", "zstandard", "lazy-object-proxy",
    "cffi", "cryptography", "python-box", "lxml",
    
    # MCP framework
    "mcp", "fastmcp", "starlette", "uvicorn", "anyio",
    "httpx", "httpx-sse", "httpcore", "sniffio", "h11", "sse-starlette",
    
    # Zscaler dependencies
    "pycountry", "referencing", "jsonschema", "zscaler-sdk-python"
)

Write-Host "  Installing $($deps.Count) packages..." -ForegroundColor Gray
& $PYTHON -m pip install $deps --break-system-packages --quiet 2>$null
Write-Host "  System dependencies installed" -ForegroundColor Green

# ============================================
# PHASE 2: Fix AWS API MCP Server
# ============================================
Write-Host "`n[PHASE 2] Fixing AWS API MCP Server..." -ForegroundColor Yellow

$AWS_SERVER = "C:\Users\Falco\AppData\Roaming\Claude\Claude Extensions\ant.dir.gh.awslabs.aws-api-mcp-server\server"

if (Test-Path $AWS_SERVER) {
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
            Write-Host "  Disabled: $pkg" -ForegroundColor DarkGray
        }
    }
    Write-Host "  AWS API MCP Server fixed" -ForegroundColor Green
} else {
    Write-Host "  AWS API MCP Server not found, skipping" -ForegroundColor Yellow
}

# ============================================
# PHASE 3: Fix Zscaler MCP Server
# ============================================
Write-Host "`n[PHASE 3] Fixing Zscaler MCP Server..." -ForegroundColor Yellow

$ZSCALER_SERVER = "C:\Users\Falco\AppData\Roaming\Claude\Claude Extensions\ant.dir.gh.zscaler.zscaler-mcp-server\server"
$ZSCALER_LIB = "$ZSCALER_SERVER\lib"

if (Test-Path $ZSCALER_LIB) {
    # Comprehensive list of packages to disable
    $zscalerBundledToDisable = @(
        # Packages with compiled binaries
        "rpds*", "pydantic_core*", "orjson*", "jiter*", "charset_normalizer*",
        "markupsafe*", "yaml*", "PyYAML*", "websockets*", "zstandard*",
        "lazy_object_proxy*", "hf_xet*", "box*", "python_box*", "cffi*", "cryptography*",
        
        # Packages with version conflicts
        "pydantic*", "pydantic_settings*",
        
        # MCP framework (use system versions)
        "mcp*", "fastmcp*", "starlette*", "uvicorn*", "anyio*",
        "httpx*", "httpcore*", "sniffio*", "h11*", "sse_starlette*"
    )

    foreach ($pattern in $zscalerBundledToDisable) {
        Get-ChildItem -Path $ZSCALER_LIB -Directory -ErrorAction SilentlyContinue | 
            Where-Object { $_.Name -like $pattern -and $_.Name -notlike "*.disabled" } | 
            ForEach-Object {
                $newName = "$($_.Name).disabled"
                if (Test-Path "$ZSCALER_LIB\$newName") {
                    Remove-Item -Path "$ZSCALER_LIB\$newName" -Recurse -Force -ErrorAction SilentlyContinue
                }
                Rename-Item -Path $_.FullName -NewName $newName -Force -ErrorAction SilentlyContinue
                Write-Host "  Disabled: $($_.Name)" -ForegroundColor DarkGray
            }
    }

    # Create setup.py if not exists
    $setupPy = @"
from setuptools import setup, find_packages
setup(
    name="zscaler_mcp",
    version="0.3.0",
    packages=find_packages(),
    install_requires=["mcp", "httpx", "pydantic", "zscaler-sdk-python"],
)
"@
    $setupPath = Join-Path $ZSCALER_SERVER "setup.py"
    if (-not (Test-Path $setupPath)) {
        $setupPy | Out-File -FilePath $setupPath -Encoding UTF8
        Write-Host "  Created setup.py" -ForegroundColor DarkGray
    }

    # Install in editable mode
    & $PYTHON -m pip install -e $ZSCALER_SERVER --break-system-packages --quiet 2>$null
    Write-Host "  Zscaler MCP Server fixed" -ForegroundColor Green
} else {
    Write-Host "  Zscaler MCP Server not found, skipping" -ForegroundColor Yellow
}

# ============================================
# PHASE 4: Verification Tests
# ============================================
Write-Host "`n[PHASE 4] Running verification tests..." -ForegroundColor Yellow

$tests = @(
    @{Name="win32_setctime"; Code="import win32_setctime"},
    @{Name="loguru"; Code="from loguru import logger"},
    @{Name="rpds"; Code="import rpds"},
    @{Name="pydantic"; Code="import pydantic"},
    @{Name="mcp"; Code="from mcp.server.fastmcp import FastMCP"},
    @{Name="pycountry"; Code="import pycountry"},
    @{Name="zscaler SDK"; Code="from zscaler import ZscalerClient"}
)

$passed = 0
$failed = 0

foreach ($test in $tests) {
    $result = & $PYTHON -c $test.Code 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  $($test.Name): PASS" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  $($test.Name): FAIL" -ForegroundColor Red
        $failed++
    }
}

# ============================================
# Summary
# ============================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "SUMMARY" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Tests passed: $passed / $($tests.Count)" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })

if ($failed -eq 0) {
    Write-Host "`nSUCCESS! Please restart Claude Desktop to apply changes." -ForegroundColor Green
} else {
    Write-Host "`nSome tests failed. Check errors above." -ForegroundColor Yellow
}
