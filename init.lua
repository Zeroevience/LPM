local HttpService = game:GetService("HttpService")

local LPM_URL = "https://raw.githubusercontent.com/Zeroevience/LPM/refs/heads/main/init.lua"
local DEFAULT_PKGS_URL = "https://raw.githubusercontent.com/Zeroevience/LPM/refs/heads/main/defaultpkgs.json"
local LOCAL_PATH = "lpm/init.lua"

if not isfolder("lpm") then makefolder("lpm") end
if not isfolder("lpm/packages") then makefolder("lpm/packages") end

local function httpGet(url)
    local res = request({Url = url, Method = "GET"})
    if not res or not res.Body then
        error("[LPM] HTTP failed: "..url)
    end
    return res.Body
end

local function githubRaw(repo, branch, path)
    return "https://raw.githubusercontent.com/"..repo.."/"..branch.."/"..path
end

local function safeName(repo)
    return repo:gsub("/", "_")
end

local function autoUpdate()
    local success, remote = pcall(httpGet, LPM_URL)
    if not success or not remote then return false end

    if isfile(LOCAL_PATH) then
        local localData = readfile(LOCAL_PATH)
        if localData ~= remote then
            writefile(LOCAL_PATH, remote)
            print("[LPM] Core updated, reloading...")
            return loadstring(remote)()
        end
    end

    return false
end

local loaded = {}

local function deleteFolder(path)
    for _, file in ipairs(listfiles(path)) do
        if isfolder(file) then
            deleteFolder(file)
        else
            delfile(file)
        end
    end
    delfolder(path)
end

local function install(repo)
    assert(repo, "[LPM] Missing repo")

    local branch = "main"
    local pkgName = safeName(repo)
    local pkgPath = "lpm/packages/"..pkgName

    if isfolder(pkgPath) then
        print("[LPM] Updating:", repo)
        deleteFolder(pkgPath)
    else
        print("[LPM] Installing:", repo)
    end

    local manifestData = httpGet(githubRaw(repo, branch, "pkg.json"))
    local manifest = HttpService:JSONDecode(manifestData)

    makefolder(pkgPath)
    writefile(pkgPath.."/pkg.json", manifestData)

    for dep, _ in pairs(manifest.dependencies or {}) do
        install(dep)
    end

    for _, file in ipairs(manifest.files or {}) do
        local content = httpGet(githubRaw(repo, branch, file))
        writefile(pkgPath.."/"..file, content)
        print("[LPM] +", file)
    end

    print("[LPM] Done:", repo)
end

local function installDefaultPackages()
    print("[LPM] Loading default packages...")

    local success, data = pcall(httpGet, DEFAULT_PKGS_URL)
    if not success then return end

    local ok, json = pcall(HttpService.JSONDecode, HttpService, data)
    if not ok then return end

    if not json.dft then return end

    for repo, _ in pairs(json.dft) do
        pcall(function()
            install(repo)
        end)
    end

    print("[LPM] Default packages done")
end

local function requirePkg(repo)
    assert(repo, "[LPM] Missing repo")

    local pkgName = safeName(repo)

    if loaded[pkgName] then
        return loaded[pkgName]
    end

    local base = "lpm/packages/"..pkgName.."/"

    if not isfolder(base) then
        error("[LPM] Package not installed: "..repo)
    end

    local manifest = HttpService:JSONDecode(readfile(base.."pkg.json"))
    local entry = manifest.entry or "init.lua"

    local source = readfile(base..entry)
    local fn, err = loadstring(source)

    if not fn then
        error("[LPM] Load error: "..err)
    end

    local result = fn()
    loaded[pkgName] = result

    return result
end

local function update(repo)
    local pkgName = safeName(repo)
    local path = "lpm/packages/"..pkgName

    if isfolder(path) then
        deleteFolder(path)
    end

    install(repo)
end
local function console()
-- LPM Console - Real Lua Package Manager Console
-- Integrates with the actual LPM system for package management

-- Initialize console
rconsolecreate()
rconsolename("LPM Console - Lua Package Manager")
rconsoleclear()

-- LPM loader - loads the actual LPM core
local function loadLPM()
    if not isfolder("lpm") then
        makefolder("lpm")
    end
    if not isfolder("lpm/packages") then
        makefolder("lpm/packages")
    end
    
    -- Check if LPM core exists
    if isfile("lpm/init.lua") then
        return loadstring(readfile("lpm/init.lua"))()
    else
        rconsolewarn("LPM core not found. Installing...")
        local url = "https://raw.githubusercontent.com/Zeroevience/LPM/refs/heads/main/init.lua"
        local response = request({
            Url = url,
            Method = "GET"
        })
        
        if response and response.Body then
            writefile("lpm/init.lua", response.Body)
            rconsoleinfo("✓ LPM core installed successfully")
            return loadstring(response.Body)()
        else
            rconsoleerr("✗ Failed to download LPM core")
            return nil
        end
    end
end

-- Display welcome message
local function displayWelcome()
    rconsoleclear()
    rconsolewarn("════════════════════════════════════════════════")
    rconsolewarn("   🚀 Welcome to LPM - Lua Package Manager")
    rconsolewarn("════════════════════════════════════════════════")
    rconsoleinfo("Type 'help' to see available commands")
    rconsoleinfo("Format: username/repository")
    rconsoleprint("")
end

-- Display help menu
local function displayHelp()
    rconsoleprint("")
    rconsoleprint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    rconsoleprint("📚 Available Commands:")
    rconsoleprint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    rconsoleinfo("  help                    - Display this help menu")
    rconsoleinfo("  install <user/repo>     - Install a package from GitHub")
    rconsoleinfo("  require <user/repo>     - Load an installed package")
    rconsoleinfo("  update <user/repo>      - Update a package to latest version")
    rconsoleinfo("  remove <user/repo>      - Uninstall a package")
    rconsoleinfo("  list                    - List all installed packages")
    rconsoleinfo("  info <user/repo>        - Show package information")
    rconsoleinfo("  reinstall-core          - Reinstall LPM core")
    rconsoleinfo("  update-core             - Update LPM core")
    rconsoleinfo("  clear                   - Clear console")
    rconsoleinfo("  version                 - Show versions")
    rconsoleinfo("  exit                    - Exit the console")
    rconsoleprint("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
    rconsoleprint("")
end
local function validatePackageFormat(pkg)
    if not pkg or pkg == "" then
        return false, "Package name cannot be empty"
    end
    if not string.match(pkg, "^[%w%-_]+/[%w%-_.]+$") then
        return false, "Invalid format. Use: username/repository"
    end
    return true, pkg
end

local function pkgToFolder(pkg)
    return string.gsub(pkg, "/", "_")
end

local function isPackageInstalled(pkg)
    local folder = "lpm/packages/" .. pkgToFolder(pkg)
    return isfolder(folder)
end


local function installPackage(lpm, pkg)
    local valid, msg = validatePackageFormat(pkg)
    if not valid then
        rconsolewarn("⚠ " .. msg)
        rconsoleprint("")
        return
    end
    
    if isPackageInstalled(pkg) then
        rconsolewarn("⚠ Package '" .. pkg .. "' is already installed")
        rconsoleinfo("  Use 'update " .. pkg .. "' to update it")
        rconsoleprint("")
        return
    end
    
    rconsoleinfo("⬇ Installing " .. pkg .. "...")
    rconsoleinfo("  Fetching from: https://github.com/" .. pkg)
    
    local success = pcall(function()
        lpm("install", pkg)
    end)
    
    if success then
        rconsoleinfo("✓ Downloaded package files")
        rconsoleinfo("✓ Resolved dependencies")
        rconsoleinfo("✅ " .. pkg .. " installed successfully!")
        rconsoleinfo("  Use: require " .. pkg .. "  (to load the package)")
    else
        rconsoleerr("✗ Failed to install " .. pkg)
        rconsolewarn("  Check the repository exists and has a valid pkg.json")
    end
    rconsoleprint("")
end

-- Require (load) a package
local function requirePackage(lpm, pkg)
    local valid, msg = validatePackageFormat(pkg)
    if not valid then
        rconsolewarn("⚠ " .. msg)
        rconsoleprint("")
        return
    end
    
    if not isPackageInstalled(pkg) then
        rconsolewarn("⚠ Package '" .. pkg .. "' is not installed")
        rconsoleinfo("  Use: install " .. pkg .. "  (to install it first)")
        rconsoleprint("")
        return
    end
    
    rconsoleinfo("📦 Loading " .. pkg .. "...")
    
    local success, result = pcall(function()
        return lpm("require", pkg)
    end)
    
    if success and result then
        rconsoleinfo("✅ Package loaded successfully!")
        rconsoleinfo("  Module cached for reuse")
        
        -- Show available functions if it's a table
        if type(result) == "table" then
            local funcCount = 0
            for k, v in pairs(result) do
                if type(v) == "function" then
                    funcCount = funcCount + 1
                end
            end
            if funcCount > 0 then
                rconsoleinfo("  Available functions: " .. funcCount)
            end
        end
    else
        rconsoleerr("✗ Failed to load " .. pkg)
    end
    rconsoleprint("")
end

-- Update a package
local function updatePackage(lpm, pkg)
    local valid, msg = validatePackageFormat(pkg)
    if not valid then
        rconsolewarn("⚠ " .. msg)
        rconsoleprint("")
        return
    end
    
    if not isPackageInstalled(pkg) then
        rconsolewarn("⚠ Package '" .. pkg .. "' is not installed")
        rconsoleinfo("  Use: install " .. pkg .. "  (to install it first)")
        rconsoleprint("")
        return
    end
    
    rconsoleinfo("🔄 Updating " .. pkg .. "...")
    rconsoleinfo("  Fetching latest version from GitHub")
    
    local success = pcall(function()
        lpm("update", pkg)
    end)
    
    if success then
        rconsoleinfo("✓ Downloaded latest files")
        rconsoleinfo("✓ Resolved dependencies")
        rconsoleinfo("✅ " .. pkg .. " updated successfully!")
    else
        rconsoleerr("✗ Failed to update " .. pkg)
    end
    rconsoleprint("")
end

-- Remove a package
local function removePackage(lpm, pkg)
    local valid, msg = validatePackageFormat(pkg)
    if not valid then
        rconsolewarn("⚠ " .. msg)
        rconsoleprint("")
        return
    end
    
    if not isPackageInstalled(pkg) then
        rconsolewarn("⚠ Package '" .. pkg .. "' is not installed")
        rconsoleprint("")
        return
    end
    
    rconsoleinfo("🗑 Removing " .. pkg .. "...")
    
    local success = pcall(function()
        lpm("remove", pkg)
    end)
    
    if success then
        rconsoleinfo("✓ Deleted package files")
        rconsoleinfo("✅ " .. pkg .. " removed successfully!")
    else
        rconsoleerr("✗ Failed to remove " .. pkg)
    end
    rconsoleprint("")
end

-- List installed packages
local function listInstalledPackages()
    rconsoleprint("")
    
    local packagesFolder = "lpm/packages"
    if not isfolder(packagesFolder) then
        rconsolewarn("No packages installed yet!")
        rconsoleprint("")
        return
    end
    
    local packages = listfiles(packagesFolder)
    if not packages or #packages == 0 then
        rconsolewarn("No packages installed yet!")
        rconsoleprint("")
        return
    end
    
    rconsoleinfo("📦 Installed Packages:")
    rconsoleprint("─────────────────────────────────────────────")
    
    for _, folder in ipairs(listfiles(packagesFolder)) do
        local folderName = string.match(folder, "([%w%-_]+)/?$")
        local displayName = string.gsub(folderName, "_", "/")
        
        -- Try to read package info
        local pkgJsonPath = packagesFolder .. "/" .. folderName .. "/pkg.json"
        if isfile(pkgJsonPath) then
            local version = "unknown"
            -- Attempt to parse version from pkg.json
            local content = readfile(pkgJsonPath)
            local versionMatch = string.match(content, '"version"%s*:%s*"([^"]+)"')
            if versionMatch then
                version = versionMatch
            end
            rconsoleinfo("  ✓ " .. displayName .. " (v" .. version .. ")")
        else
            rconsoleinfo("  ✓ " .. displayName)
        end
    end
    
    rconsoleprint("─────────────────────────────────────────────")
    rconsoleprint("")
end

-- Show package info
local function showPackageInfo(pkg)
    local valid, msg = validatePackageFormat(pkg)
    if not valid then
        rconsolewarn("⚠ " .. msg)
        rconsoleprint("")
        return
    end
    
    local folder = "lpm/packages/" .. pkgToFolder(pkg)
    local pkgJsonPath = folder .. "/pkg.json"
    
    if not isfile(pkgJsonPath) then
        rconsolewarn("⚠ Package '" .. pkg .. "' is not installed")
        rconsoleprint("")
        return
    end
    
    rconsoleprint("")
    rconsoleinfo("📦 Package Information: " .. pkg)
    rconsoleprint("─────────────────────────────────────────────")
    
    local content = readfile(pkgJsonPath)
    rconsoleinfo("  Repository: https://github.com/" .. pkg)
    rconsoleinfo("  Status: ✓ Installed")
    rconsoleinfo("  Location: " .. folder)
    
    -- Parse and show basic info from pkg.json
    local nameMatch = string.match(content, '"name"%s*:%s*"([^"]+)"')
    local entryMatch = string.match(content, '"entry"%s*:%s*"([^"]+)"')
    local versionMatch = string.match(content, '"version"%s*:%s*"([^"]+)"')
    
    if nameMatch then
        rconsoleinfo("  Name: " .. nameMatch)
    end
    if entryMatch then
        rconsoleinfo("  Entry: " .. entryMatch)
    end
    if versionMatch then
        rconsoleinfo("  Version: " .. versionMatch)
    end
    
    rconsoleprint("─────────────────────────────────────────────")
    rconsoleprint("")
end

-- Reinstall LPM core
local function reinstallCore()
    rconsoleinfo("🔧 Reinstalling LPM core...")
    
    local url = "https://raw.githubusercontent.com/Zeroevience/LPM/refs/heads/main/init.lua"
    local success = pcall(function()
        local response = request({
            Url = url,
            Method = "GET"
        })
        
        if response and response.Body then
            writefile("lpm/init.lua", response.Body)
            rconsoleinfo("✅ LPM core reinstalled successfully!")
            rconsoleinfo("  Please restart your script to load the new version")
        else
            rconsoleerr("✗ Failed to download LPM core")
        end
    end)
    
    if not success then
        rconsoleerr("✗ Network error during reinstall")
    end
    rconsoleprint("")
end

-- Update LPM core
local function updateCore()
    rconsoleinfo("🔄 Updating LPM core...")
    rconsoleinfo("  Checking for updates...")
    
    local url = "https://raw.githubusercontent.com/Zeroevience/LPM/refs/heads/main/init.lua"
    local success = pcall(function()
        local response = request({
            Url = url,
            Method = "GET"
        })
        
        if response and response.Body then
            local oldContent = isfile("lpm/init.lua") and readfile("lpm/init.lua") or ""
            
            if oldContent == response.Body then
                rconsoleinfo("✓ LPM core is already up to date")
            else
                writefile("lpm/init.lua", response.Body)
                rconsoleinfo("✓ Downloaded latest version")
                rconsoleinfo("✅ LPM core updated successfully!")
                rconsoleinfo("  Please restart your script to load the new version")
            end
        else
            rconsoleerr("✗ Failed to download LPM core")
        end
    end)
    
    if not success then
        rconsoleerr("✗ Network error during update")
    end
    rconsoleprint("")
end

-- Show versions
local function showVersions()
    rconsoleprint("")
    rconsoleinfo("📊 Version Information:")
    rconsoleprint("─────────────────────────────────────────────")
    rconsoleinfo("  LPM Console:  1.0.0")
    rconsoleinfo("  LPM Core:     auto-updating")
    rconsoleinfo("  GitHub:       Zeroevience/LPM")
    rconsoleprint("─────────────────────────────────────────────")
    rconsoleprint("")
end

-- Process commands
local function processCommand(lpm, input)
    -- Trim whitespace
    input = string.gsub(input, "^%s+", ""):gsub("%s+$", "")
    
    if input == "" then
        return true
    end
    
    -- Split command and arguments
    local parts = {}
    for part in string.gmatch(input, "%S+") do
        table.insert(parts, part)
    end
    
    local cmd = string.lower(parts[1])
    local args = table.concat(parts, " ", 2)
    
    if cmd == "help" then
        displayHelp()
    elseif cmd == "install" then
        if args == "" then
            rconsolewarn("⚠ Usage: install <username/repository>")
            rconsoleprint("")
        else
            installPackage(lpm, args)
        end
    elseif cmd == "require" then
        if args == "" then
            rconsolewarn("⚠ Usage: require <username/repository>")
            rconsoleprint("")
        else
            requirePackage(lpm, args)
        end
    elseif cmd == "update" then
        if args == "" then
            rconsolewarn("⚠ Usage: update <username/repository>")
            rconsoleprint("")
        else
            updatePackage(lpm, args)
        end
    elseif cmd == "remove" then
        if args == "" then
            rconsolewarn("⚠ Usage: remove <username/repository>")
            rconsoleprint("")
        else
            removePackage(lpm, args)
        end
    elseif cmd == "list" then
        listInstalledPackages()
    elseif cmd == "info" then
        if args == "" then
            rconsolewarn("⚠ Usage: info <username/repository>")
            rconsoleprint("")
        else
            showPackageInfo(args)
        end
    elseif cmd == "reinstall-core" then
        reinstallCore()
    elseif cmd == "update-core" then
        updateCore()
    elseif cmd == "clear" then
        rconsoleclear()
    elseif cmd == "version" then
        showVersions()
    elseif cmd == "exit" then
        rconsoleinfo("👋 Thank you for using LPM! Goodbye!")
        return false
    else
        rconsoleerr("✗ Unknown command: '" .. cmd .. "'")
        rconsoleinfo("  Type 'help' for available commands")
        rconsoleprint("")
    end
    
    return true
end

-- Main console loop
rconsoleinfo("⏳ Loading LPM core...")
local lpm = loadLPM()

if lpm then
    rconsoleinfo("✅ LPM ready!")
    displayWelcome()
    
    while true do
        local input = rconsoleinput("LPM> ")
        local shouldContinue = processCommand(lpm, input)
        
        if shouldContinue == false then
            break
        end
    end
else
    rconsoleerr("✗ Failed to load LPM. Exiting...")
end


end

local function remove(repo)
    local pkgName = safeName(repo)
    local path = "lpm/packages/"..pkgName

    if isfolder(path) then
        deleteFolder(path)
        print("[LPM] Removed:", repo)
    end
end

local function lpm(action, repo)
    local new = autoUpdate()
    if new then
        return new(action, repo)
    end

    if action == "install" then
        return install(repo)

    elseif action == "require" then
        return requirePkg(repo)

    elseif action == "update" then
        return update(repo)

    elseif action == "remove" then
        return remove(repo)
    elseif action == "console" then
        console()
    else
        error("[LPM] Unknown action: "..tostring(action))
    end
end

installDefaultPackages()

print("[LPM] Loaded")

return lpm
