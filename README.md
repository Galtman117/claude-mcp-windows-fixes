# Claude MCP Windows Fixes

Fixes for Claude Desktop MCP (Model Context Protocol) servers that fail on Windows due to bundled macOS/Linux binaries.

## 🎯 Quick Fix

Run PowerShell as Administrator:

```powershell
powershell -ExecutionPolicy Bypass -File fix-all-mcp-servers.ps1
```

Then restart Claude Desktop.

## 📋 Issues Covered

| Issue | Script | Requires Admin | Requires Reboot |
|-------|--------|----------------|-----------------|
| AWS API MCP Server - macOS binaries | `fix-all-mcp-servers.ps1` | No | No |
| Zscaler MCP Server - macOS binaries | `fix-all-mcp-servers.ps1` | No | No |

---

## 🔌 Root Cause

AWS API MCP Server and Zscaler MCP Server bundle Python packages with pre-compiled binaries built for macOS/Linux:

```
server/lib/
├── rpds/
│   └── rpds.cpython-311-darwin.so  ← macOS binary, won't load on Windows
├── pydantic_core/
│   └── _pydantic_core.cpython-311-darwin.so
└── ... (many more)
```

Windows requires `.pyd` binaries instead of `.so` files.

## 🛠️ Solution

1. **Disable bundled packages** with platform-specific binaries
2. **Install Windows-native versions** via pip
3. **Restart Claude Desktop**

### Packages Requiring Windows Binaries

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

---

## 📁 Repository Structure

```
claude-mcp-windows-fixes/
├── README.md
├── LICENSE
├── fix-all-mcp-servers.ps1          # Main MCP fix script
├── issues/
│   ├── aws-api-mcp-server.md        # AWS issue documentation
│   └── zscaler-mcp-server.md        # Zscaler issue documentation
└── scripts/
    ├── fix-all-mcp-servers.ps1      # MCP server fixes
    └── fix-zscaler-mcp-windows.ps1  # Standalone Zscaler fix
```

## ⚠️ Upstream Issues

- [awslabs/mcp](https://github.com/awslabs/mcp) - AWS API MCP Server Windows compatibility
- [zscaler/zscaler-mcp-server](https://github.com/zscaler/zscaler-mcp-server) - Zscaler MCP Server Windows compatibility

## 📝 License

MIT License - See [LICENSE](LICENSE)

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request
