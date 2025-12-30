# Claude MCP Windows Fixes

Fixes for Claude Desktop MCP (Model Context Protocol) servers and related Windows issues.

## 🎯 Quick Fix - MCP Servers

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
| VPN/Network disconnects (port exhaustion) | `fix-ephemeral-port-exhaustion.ps1` | **Yes** | **Yes** |
| Docker MCP timeout on startup | `diagnose-docker-mcp-timeout.ps1` | No | No |

---

## 🔌 MCP Server Fixes

### Root Cause

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

### Solution

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

## 🌐 Ephemeral Port Exhaustion Fix

### Symptoms

- Browser randomly disconnects while using VPN
- Only way to resume is refreshing/reconnecting VPN
- Network timeouts under heavy load
- Windows Event Log shows:
  ```
  A request to allocate an ephemeral port number from the global TCP/UDP 
  port space has failed due to all such ports being in use.
  ```

### Root Cause

Windows default ephemeral port range is ~16,384 ports with a 240-second TIME_WAIT. Heavy users with VPNs, Docker, WSL, Hyper-V, and many concurrent connections exhaust this pool.

### Solution

Run as Administrator:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\fix-ephemeral-port-exhaustion.ps1
```

Or manually:

```powershell
# Expand port range from ~16K to ~64K
netsh int ipv4 set dynamicport tcp start=1025 num=64510
netsh int ipv4 set dynamicport udp start=1025 num=64510

# Reduce TIME_WAIT from 240s to 30s
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "TcpTimedWaitDelay" -Value 30 -Type DWord
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" -Name "MaxUserPort" -Value 65534 -Type DWord
```

**Reboot required after applying.**

---

## 🐳 Docker MCP Timeout Fix

### Symptoms

- Claude Desktop hangs on "Initializing..."
- Docker MCP servers fail to connect
- Works after disabling some Docker MCP servers

### Root Cause

Docker MCP has a 120-second initialization timeout. Too many enabled servers, especially those with missing API keys or network issues, cause timeouts.

### Solution

Run the diagnostic:

```powershell
powershell -ExecutionPolicy Bypass -File scripts\diagnose-docker-mcp-timeout.ps1
```

Then edit `%USERPROFILE%\.docker\mcp\registry.yaml` and set `enabled: false` for servers you don't need:

- Servers requiring API keys you haven't configured
- Servers duplicating Claude's built-in extensions
- Servers you don't actively use

Recommended to keep **4 or fewer** servers enabled.

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
    ├── fix-zscaler-mcp-windows.ps1  # Standalone Zscaler fix
    ├── fix-ephemeral-port-exhaustion.ps1  # Network/VPN fix
    └── diagnose-docker-mcp-timeout.ps1    # Docker MCP diagnostic
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
