# AWS API MCP Server - Windows Compatibility Issue

## Bug Report for: awslabs/aws-api-mcp-server

### Summary
AWS API MCP Server fails to start on Windows due to bundled Python packages containing macOS/Linux-only compiled binaries and missing Windows-specific dependencies.

---

### Environment
- **OS:** Windows 11 Pro (Build 22631)
- **Python:** 3.13.x (standard installation)
- **Claude Desktop:** Latest version
- **Extension Path:** `%APPDATA%\Claude\Claude Extensions\ant.dir.gh.awslabs.aws-api-mcp-server`

---

### Error Message
```
ModuleNotFoundError: No module named 'win32_setctime'
```

### Full Stack Trace
```python
Traceback (most recent call last):
  File "<frozen runpy>", line 198, in _run_module_as_main
  File "<frozen runpy>", line 88, in _run_code
  File "...\server\awslabs\aws_api_mcp_server\server.py", line 17, in <module>
    from .core.agent_scripts.manager import AGENT_SCRIPTS_MANAGER
  File "...\server\awslabs\aws_api_mcp_server\core\__init__.py", line 17, in <module>
    from . import aws, common, data, metadata, parser
  File "...\server\awslabs\aws_api_mcp_server\core\aws\__init__.py", line 17, in <module>
    from .driver import translate_cli_to_ir, get_local_credentials
  File "...\server\awslabs\aws_api_mcp_server\core\aws\driver.py", line 17, in <module>
    from ..common.errors import (...)
  File "...\server\awslabs\aws_api_mcp_server\core\common\__init__.py", line 18, in <module>
    from .helpers import as_json
  File "...\server\awslabs\aws_api_mcp_server\core\common\helpers.py", line 23, in <module>
    from loguru import logger
  File "...\server\loguru\__init__.py", line 11, in <module>
    from ._logger import Core as _Core
  File "...\server\loguru\_logger.py", line 108, in <module>
    from ._file_sink import FileSink
  File "...\server\loguru\_file_sink.py", line 12, in <module>
    from ._ctime_functions import get_ctime, set_ctime
  File "...\server\loguru\_ctime_functions.py", line 57, in <module>
    get_ctime, set_ctime = load_ctime_functions()
  File "...\server\loguru\_ctime_functions.py", line 6, in load_ctime_functions
    import win32_setctime
ModuleNotFoundError: No module named 'win32_setctime'
```

---

### Root Cause Analysis

The extension bundles Python packages in the `server/` directory. Several issues:

#### 1. Missing Windows Dependency
The bundled `loguru` package requires `win32_setctime` on Windows (for file creation time manipulation), but this dependency is not bundled.

#### 2. Platform-Specific Binaries
Multiple bundled packages contain compiled binaries for macOS only:

| Package | Bundled Binary | Issue |
|---------|---------------|-------|
| `cffi` | `_cffi_backend.cpython-312-darwin.so` | macOS-only, no Windows .pyd |
| `pydantic_core` | `.so` files | macOS-only binaries |
| `lxml` | `.so` files | macOS-only binaries |
| `rpds` | `.so` files | macOS-only binaries |
| `cryptography` | `.so` files | macOS-only binaries |

#### 3. Evidence
```
server/_cffi_backend.cpython-312-darwin.so  # Darwin = macOS, not Windows
```

---

### Suggested Fix (for maintainers)

#### Option A: Don't Bundle Platform-Specific Packages
Remove bundled packages with compiled components. Let users' system Python provide them:
- `loguru`
- `pydantic` / `pydantic_core`
- `lxml`
- `cffi`
- `cryptography`
- `rpds`

#### Option B: Bundle Windows Binaries
If bundling is required, include Windows `.pyd` files alongside `.so` files.

#### Option C: Use Pure-Python Alternatives
Where possible, use pure-Python packages that don't require compiled binaries.

---

### Workaround (for users)

```powershell
# 1. Install system dependencies
pip install win32-setctime loguru pydantic lxml cffi cryptography --break-system-packages

# 2. Disable bundled packages (rename to .disabled)
$server = "$env:APPDATA\Claude\Claude Extensions\ant.dir.gh.awslabs.aws-api-mcp-server\server"
@("loguru","pydantic","pydantic_core","lxml","rpds","cffi","cryptography","referencing","annotated_types") | ForEach-Object {
    $p = Join-Path $server $_
    if (Test-Path $p) { Rename-Item $p "$p.disabled" }
}

# 3. Restart Claude Desktop
```

---

### Additional Context

- This affects all Windows users with standard Python installations
- The server works correctly on macOS where the bundled `.so` files are compatible
- No code changes are needed to the MCP server itself - only the bundled dependencies

---

### Checklist
- [x] I have searched existing issues
- [x] I have included all relevant error messages
- [x] I have provided environment details
- [x] I have included a workaround
