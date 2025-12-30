# Claude MCP Windows Fixes

Fixes for Claude Desktop MCP (Model Context Protocol) servers that fail on Windows due to bundled packages containing macOS/Linux compiled binaries.

## 🎯 Quick Fix

Run PowerShell as Administrator:

```powershell
powershell -ExecutionPolicy Bypass -File fix-all-mcp-servers.ps1
```

Then restart Claude Desktop.

## 📋 Affected Servers

| Server | Issue | Status |
|--------|-------|--------|
| AWS API MCP Server | Bundled macOS binaries | ✅ Fixed |
| Zscaler MCP Server | Bundled macOS binaries + missing deps | ✅ Fixed |
| MCP Docker | Requires Docker Desktop | N/A |

## 🔍 Root Cause

Both AWS API MCP Server and Zscaler MCP Server bundle Python packages with pre-compiled binaries built for macOS/Linux:

```
server/lib/
├── rpds/
│   └── rpds.cpython-311-darwin.so  ← macOS binary, won't load on Windows
├── pydantic_core/
│   └── _pydantic_core.cpython-311-darwin.so
├── orjson/
│   └── orjson.cpython-311-darwin.so
└── ... (many more)
```

Windows requires `.pyd` binaries instead of `.so` files.

## 🛠️ Solution

1. **Disable bundled packages** with platform-specific binaries
2. **Install Windows-native versions** via pip
3. **Restart Claude Desktop**

## 📁 Repository Structure

```
claude-mcp-windows-fixes/
├── README.md                    # This file
├── LICENSE                      # MIT License
├── fix-all-mcp-servers.ps1      # Main fix script
├── issues/
│   ├── aws-api-mcp-server.md    # Detailed AWS issue documentation
│   └── zscaler-mcp-server.md    # Detailed Zscaler issue documentation
├── scripts/
│   └── fix-zscaler-mcp-windows.ps1  # Standalone Zscaler fix
└── logs/
    ├── before/                  # Error logs before fix
    └── after/                   # Success logs after fix
```

## 📦 Packages That Need Windows Binaries

These bundled packages contain compiled binaries and need to be replaced with system-installed versions:

- `rpds-py` - Rust persistent data structures
- `pydantic-core` - Pydantic core (Rust)
- `orjson` - Fast JSON (Rust)
- `jiter` - JSON iterator
- `charset-normalizer` - Character encoding
- `markupsafe` - HTML escaping
- `PyYAML` - YAML parser
- `websockets` - WebSocket library
- `zstandard` - Zstd compression
- `cffi` - C Foreign Function Interface
- `cryptography` - Cryptographic operations
- `lazy-object-proxy` - Lazy loading

## 🔧 Manual Fix Steps

### AWS API MCP Server

```powershell
$server = "$env:APPDATA\Claude\Claude Extensions\ant.dir.gh.awslabs.aws-api-mcp-server\server"
@("loguru", "pydantic", "pydantic_core", "lxml", "rpds", "cffi", "cryptography") | 
  ForEach-Object { Rename-Item "$server\$_" "$_`.disabled" -ErrorAction SilentlyContinue }
```

### Zscaler MCP Server

```powershell
$lib = "$env:APPDATA\Claude\Claude Extensions\ant.dir.gh.zscaler.zscaler-mcp-server\server\lib"
@("rpds*", "pydantic*", "orjson*", "mcp*", "fastmcp*") | ForEach-Object {
  Get-ChildItem $lib -Directory | Where-Object { $_.Name -like $_ } | 
    ForEach-Object { Rename-Item $_.FullName "$($_.Name).disabled" }
}
pip install rpds-py pydantic mcp fastmcp pycountry zscaler-sdk-python --break-system-packages
```

## ⚠️ Upstream Issues

These issues should be reported to the respective repositories:

- **awslabs/aws-api-mcp-server** - Bundle Windows binaries or don't bundle compiled packages
- **zscaler/zscaler-mcp-server** - Bundle Windows binaries or document pip installation

## 🧪 Verification

After running the fix, verify with:

```python
import rpds, pydantic, pycountry
from mcp.server.fastmcp import FastMCP
from zscaler import ZscalerClient
print("All imports successful!")
```

## 📝 License

MIT License - See [LICENSE](LICENSE)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request
