# ============================================================================
# Zscaler MCP Server Windows Fix Script - VERIFIED WORKING
# ============================================================================
# Problem: Bundled packages contain macOS/Linux binaries (.so, .dylib)
#          that don't work on Windows (requires .pyd binaries)
#
# Solution: Disable ALL bundled packages with compiled binaries or version
#           conflicts and install Windows-native versions via pip
#
# Last Updated: 2025-12-30
# ============================================================================

$ErrorActionPreference = "Continue"

$serverDir = "C:\Users\Falco\AppData\Roaming\Claude\Claude Extensions\ant.dir.gh.zscaler.zscaler-mcp-server\server"
$libDir = "$serverDir\lib"
$pythonExe = "C:\Users\Falco\AppData\Local\Programs\Python\Python313\python.exe"

Write-Host "=" * 80 -ForegroundColor Cyan
Write-Host "ZSCALER MCP SERVER WINDOWS FIX" -ForegroundColor Cyan
Write-Host "=" * 80 -ForegroundColor Cyan

# ============================================================================
# PHASE 1: Disable bundled packages with platform-specific or version issues
# ============================================================================
Write-Host "`n[PHASE 1] Disabling bundled packages..." -ForegroundColor Yellow

# Comprehensive list of packages to disable
$packagesToDisable = @(
    # Packages with compiled binaries (macOS/Linux .so files)
    "rpds", "rpds_py*",
    "pydantic_core", "pydantic_core-*",
    "orjson", "orjson-*",
    "jiter", "jiter-*",
    "charset_normalizer", "charset_normalizer-*",
    "markupsafe", "markupsafe-*",
    "yaml", "PyYAML-*",
    "websockets", "websockets-*",
    "zstandard", "zstandard-*",
    "lazy_object_proxy", "lazy_object_proxy-*",
    "hf_xet", "hf_xet-*",
    "box", "python_box-*",
    "cffi", "cffi-*",
    "cryptography", "cryptography-*",
    
    # Packages with version conflicts
    "pydantic", "pydantic-*",
    "pydantic_settings", "pydantic_settings-*",
    
    # Core framework packages (use system versions)
    "mcp", "mcp-*",
    "fastmcp", "fastmcp-*",
    "starlette", "starlette-*",
    "uvicorn", "uvicorn-*",
    "anyio", "anyio-*",
    "httpx", "httpx-*",
    "httpx_sse", "httpx_sse-*",
    "httpcore", "httpcore-*",
    "sniffio", "sniffio-*",
    "h11", "h11-*",
    "sse_starlette", "sse_starlette-*"
)

$disabledCount = 0
foreach ($pattern in $packagesToDisable) {
    Get-ChildItem -Path $libDir -Directory -ErrorAction SilentlyContinue | 
        Where-Object { $_.Name -like $pattern -and $_.Name -notlike "*.disabled" } | 
        ForEach-Object {
            $newName = "$($_.Name).disabled"
            if (Test-Path "$libDir\$newName") {
                Remove-Item -Path "$libDir\$newName" -Recurse -Force -ErrorAction SilentlyContinue
            }
            Rename-Item -Path $_.FullName -NewName $newName -Force -ErrorAction SilentlyContinue
            Write-Host "  Disabled: $($_.Name)" -ForegroundColor DarkGray
            $disabledCount++
        }
}
Write-Host "  Total disabled: $disabledCount directories" -ForegroundColor Green

# ============================================================================
# PHASE 2: Install Windows-compatible packages via pip
# ============================================================================
Write-Host "`n[PHASE 2] Installing Windows-compatible packages..." -ForegroundColor Yellow

$pipPackages = @(
    # Core dependencies with compiled binaries
    "rpds-py",
    "pydantic-core",
    "pydantic",
    "pydantic-settings",
    "orjson",
    "jiter",
    "charset-normalizer",
    "markupsafe",
    "PyYAML",
    "websockets",
    "zstandard",
    "lazy-object-proxy",
    "cffi",
    "cryptography",
    "python-box",
    
    # MCP framework
    "mcp",
    "fastmcp",
    "starlette",
    "uvicorn",
    "anyio",
    "httpx",
    "httpx-sse",
    "httpcore",
    "sniffio",
    "h11",
    "sse-starlette",
    
    # Zscaler dependencies
    "pycountry",
    "referencing",
    "jsonschema",
    "zscaler-sdk-python"
)

& $pythonExe -m pip install $pipPackages --break-system-packages --quiet 2>&1 | Out-Null
Write-Host "  Package installation complete" -ForegroundColor Green

# ============================================================================
# PHASE 3: Verify the fix
# ============================================================================
Write-Host "`n[PHASE 3] Verifying installation..." -ForegroundColor Yellow

$testScript = @'
import sys
sys.path.insert(0, r'%LIBDIR%')
sys.path.insert(0, r'%SERVERDIR%')

errors = []
tests = [
    ("rpds", "import rpds"),
    ("pydantic_core", "import pydantic_core"),
    ("pydantic", "import pydantic"),
    ("referencing", "import referencing"),
    ("jsonschema", "import jsonschema"),
    ("mcp.server.fastmcp", "from mcp.server.fastmcp import FastMCP"),
    ("pycountry", "import pycountry"),
    ("zscaler SDK", "from zscaler import ZscalerClient"),
    ("zscaler_mcp.server", "from zscaler_mcp.server import ZscalerMCPServer"),
]

for name, code in tests:
    try:
        exec(code)
        print(f"  {name}: OK")
    except Exception as e:
        errors.append(f"{name}: {e}")
        print(f"  {name}: FAILED - {e}")

if errors:
    print(f"\n  VERIFICATION FAILED: {len(errors)} errors")
    sys.exit(1)
else:
    print(f"\n  ALL CHECKS PASSED")
    sys.exit(0)
'@

$testScript = $testScript.Replace('%LIBDIR%', $libDir).Replace('%SERVERDIR%', $serverDir)
$testScript | & $pythonExe -

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n" + "=" * 80 -ForegroundColor Green
    Write-Host "SUCCESS! Zscaler MCP Server should now work on Windows." -ForegroundColor Green
    Write-Host "Please restart Claude Desktop to apply changes." -ForegroundColor Green
    Write-Host "=" * 80 -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n" + "=" * 80 -ForegroundColor Red
    Write-Host "VERIFICATION FAILED - See errors above" -ForegroundColor Red
    Write-Host "=" * 80 -ForegroundColor Red
    exit 1
}
