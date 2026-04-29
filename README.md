# 📦 LPM — Lua Package Manager (Exploit Version)

LPM is a lightweight Lua package manager designed for exploit environments.
It installs and loads packages directly from GitHub using local file storage.

---

# 🚀 How It Works

LPM works in 2 parts:

1. **Installer (run once)**
   → Downloads the core into `lpm/init.lua`

2. **Core (auto-updating)**
   → Handles install, require, update, remove

All scripts then load LPM using:

```lua
local lpm = loadstring(readfile("lpm/init.lua"))()
```

---

# 🛠️ Installation (One-Time Setup)

~~Run this once:~~

```lua
```

Updated installer:
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/Zeroevience/LPM/refs/heads/main/uiinstaller.js",true))()
```
---

# ⚡ Loading LPM

In ANY script:

```lua
local lpm = loadstring(readfile("lpm/init.lua"))()
```

### What happens:

* LPM loads into memory
* It checks GitHub for updates
* Updates itself if needed
* Returns the `lpm` function

---

# 📥 Installing Packages

```lua
lpm("install", "user/repo")
```

### Process:

1. Fetches `pkg.json` from GitHub
2. Creates folder in:

   ```
   lpm/packages/user_repo/
   ```
3. Downloads all files listed in `pkg.json`
4. Installs dependencies recursively

---

# 📦 Using Packages

```lua
local pkg = lpm("require", "user/repo")
```

### Behavior:

* Reads local files
* Executes entry file (`init.lua` by default)
* Returns module
* Caches result (only loads once)

---

# 🔄 Updating Packages

```lua
lpm("update", "user/repo")
```

### Process:

* Deletes package folder
* Reinstalls from GitHub

---

# 🗑️ Removing Packages

```lua
lpm("remove", "user/repo")
```

Deletes:

```
lpm/packages/user_repo/
```

---

# 🔄 Core Auto-Update System

Every time LPM is loaded:

```lua
loadstring(readfile("lpm/init.lua"))()
```

It will:

* Download latest version from GitHub
* Compare with local version
* Overwrite if changed

---

## Force update manually

```lua
writefile(
    "lpm/init.lua",
    request({
        Url = "https://raw.githubusercontent.com/Zeroevience/LPM/refs/heads/main/init.lua",
        Method = "GET"
    }).Body
)
```

---

# 📦 Package Structure

Each package MUST follow this format:

```
repo/
  pkg.json
  init.lua
```

---

## pkg.json

```json
{
  "name": "example",
  "entry": "init.lua",
  "files": ["init.lua"],
  "dependencies": {}
}
```

---

## init.lua

```lua
local M = {}

function M.hello()
    print("Hello!")
end

return M
```

---

# 🔗 Dependencies

Example:

```json
"dependencies": {
  "user/otherrepo": "latest"
}
```

Usage:

```lua
local dep = lpm("require", "user/otherrepo")
```

---

# 📁 File Storage

```
lpm/
  init.lua
  packages/
    user_repo/
      pkg.json
      init.lua
      ...
```

---

# ⚠️ Important Notes

### Correct format:

```lua
"user/repo"
```

### ❌ Incorrect:

```lua
"user/repo.lua"
"user/repo/file.lua"
```

---

### Requirements:

* Repo must contain `pkg.json`
* All files must be listed
* Entry file must exist

---

### Security:

LPM executes remote code using `loadstring`.

👉 Only install trusted repositories.

---

# 🧪 Example

```lua
local lpm = loadstring(readfile("lpm/init.lua"))()

lpm("install", "yourname/test")

local test = lpm("require", "yourname/test")
test.hello()
```

---

# 🧠 Summary

LPM provides:

* GitHub-based package installation
* dependency management
* local caching
* auto-updating core
* reusable module system

---

# 🚀 Future Improvements

* Versioning (`repo@v1.0.0`)
* Lockfile system
* Package registry
* UI browser
* Private packages

---

# 📜 License

Free to use and modify.
