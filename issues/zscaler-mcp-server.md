# Zscaler MCP Server - Windows Compatibility Issue

## Issue Summary

The Zscaler MCP Server fails to start on Windows due to bundled Python packages containing platform-specific compiled binaries built for macOS/Linux.

**Repository:** https://github.com/zscaler/zscaler-mcp-server

## Error Chain

```
ModuleNotFoundError: No module named 'rpds.rpds'
```

**Full import chain:**
```
zscaler_mcp.server 
  → mcp.server.fastmcp 
    → mcp.client.session 
      → jsonschema 
        → referencing._core 
          → rpds (FAILS: rpds.cpython-311-darwin.so is macOS binary)
```

## Root Cause

The server bundles pre-compiled packages at:
```
%APPDATA%\Claude\Claude Extensions\ant.dir.gh.zscaler.zscaler-mcp-server\server\lib\
```

These packages contain `.so` (Linux) and `.dylib` (macOS) binaries that cannot load on Windows, which requires `.pyd` binaries.

### Affected Bundled Packages (with compiled binaries)

| Package | Bundled Binary | Issue |
|---------|---------------|-------|
| rpds | `rpds.cpython-311-darwin.so` | macOS binary |
| pydantic_core | `_pydantic_core.cpython-311-darwin.so` | macOS binary |
| orjson | `orjson.cpython-311-darwin.so` | macOS binary |
| jiter | `jiter.cpython-311-darwin.so` | macOS binary |
| charset_normalizer | `md.cpython-311-darwin.so` | macOS binary |
| markupsafe | `_speedups.cpython-311-darwin.so` | macOS binary |
| yaml | `_yaml.cpython-311-darwin.so` | macOS binary |
| websockets | `speedups.cpython-311-darwin.so` | macOS binary |
| zstandard | `backend_c.cpython-311-darwin.so` | macOS binary |
| cryptography | `*.so` files | macOS binaries |
| cffi | `_cffi_backend.cpython-311-darwin.so` | macOS binary |
| hf_xet | `hf_xet.cpython-311-darwin.so` | macOS binary |
| lazy_object_proxy | `cext.cpython-311-darwin.so` | macOS binary |

### Additional Issues

1. **Version Conflicts**: Bundled `pydantic 2.12.3` expects `pydantic-core 2.41.4`, but system may have newer version
2. **Missing Dependencies**: `pycountry` package not bundled but required by Zscaler SDK

## Solution

### Option 1: Automated Fix Script

Run the PowerShell fix script:
```powershell
powershell -ExecutionPolicy Bypass -File "fix-zscaler-mcp-windows.ps1"
```

### Option 2: Manual Fix

1. **Disable bundled packages with compiled binaries:**
   ```powershell
   $libDir = "$env:APPDATA\Claude\Claude Extensions\ant.dir.gh.zscaler.zscaler-mcp-server\server\lib"
   
   # Rename problematic packages to .disabled
   @("rpds", "pydantic_core", "orjson", "jiter", "charset_normalizer", 
     "markupsafe", "yaml", "websockets", "zstandard", "lazy_object_proxy",
     "hf_xet", "box", "cffi", "cryptography", "pydantic", "pydantic_settings",
     "mcp", "fastmcp", "starlette", "uvicorn", "anyio", "httpx", "httpx_sse",
     "httpcore", "sniffio", "h11", "sse_starlette") | ForEach-Object {
       Get-ChildItem -Path $libDir -Directory | Where-Object { $_.Name -like "$_*" } | 
         ForEach-Object { Rename-Item $_.FullName "$($_.Name).disabled" }
   }
   ```

2. **Install Windows-native packages:**
   ```powershell
   python -m pip install rpds-py pydantic-core pydantic pydantic-settings orjson jiter charset-normalizer markupsafe PyYAML websockets zstandard lazy-object-proxy cffi cryptography python-box pycountry referencing jsonschema mcp fastmcp starlette uvicorn anyio httpx httpx-sse httpcore sniffio h11 sse-starlette zscaler-sdk-python --break-system-packages
   ```

3. **Restart Claude Desktop**

## Verification

Test imports work correctly:
```python
import sys
sys.path.insert(0, r'%APPDATA%\Claude\Claude Extensions\ant.dir.gh.zscaler.zscaler-mcp-server\server\lib')
sys.path.insert(0, r'%APPDATA%\Claude\Claude Extensions\ant.dir.gh.zscaler.zscaler-mcp-server\server')

from zscaler_mcp.server import ZscalerMCPServer
print("SUCCESS!")
```

## Suggested Upstream Fix

The zscaler-mcp-server repository should either:

1. **Don't bundle compiled packages** - Let pip install platform-appropriate binaries
2. **Include Windows binaries** - Bundle `.pyd` files alongside `.so` files
3. **Use pure Python alternatives** where possible
4. **Document Windows installation separately** with pip install requirements

## Environment

- **OS:** Windows 10/11
- **Python:** 3.13
- **Claude Desktop:** Latest
- **Server Location:** `%APPDATA%\Claude\Claude Extensions\ant.dir.gh.zscaler.zscaler-mcp-server\`

## Related Issues

- Similar issue affects AWS API MCP Server (see aws-api-mcp-server.md)
- Root cause is identical: bundled macOS/Linux binaries don't work on Windows

## Status

✅ **FIXED** - Workaround implemented and verified working
