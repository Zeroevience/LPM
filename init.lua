--// LPM CORE (AUTO-UPDATING)

local HttpService = game:GetService("HttpService")

local LPM_URL = "https://raw.githubusercontent.com/Zeroevience/LPM/refs/heads/main/init.lua"
local LOCAL_PATH = "lpm/init.lua"

-- auto update
local function httpGet(url)
    local res = request({Url = url, Method = "GET"})
    return res and res.Body or nil
end

local function autoUpdate()
    local success, remote = pcall(httpGet, LPM_URL)
    if not success or not remote then return end

    if isfile(LOCAL_PATH) then
        local localData = readfile(LOCAL_PATH)

        if localData ~= remote then
            writefile(LOCAL_PATH, remote)
            print("[LPM] Core updated!")
        end
    end
end

-- init folders
if not isfolder("lpm") then makefolder("lpm") end
if not isfolder("lpm/packages") then makefolder("lpm/packages") end

autoUpdate()

local loaded = {}

local function githubRaw(repo, branch, path)
    return "https://raw.githubusercontent.com/"..repo.."/"..branch.."/"..path
end

local function safeName(repo)
    return repo:gsub("/", "_")
end

-- INSTALL
local function install(repo)
    local branch = "main"
    local pkgName = safeName(repo)
    local pkgPath = "lpm/packages/"..pkgName

    if isfolder(pkgPath) then
        print("[LPM] Already installed:", repo)
        return
    end

    print("[LPM] Installing:", repo)

    local manifestData = httpGet(githubRaw(repo, branch, "pkg.json"))
    if not manifestData then
        error("[LPM] Failed to fetch pkg.json")
    end

    local manifest = HttpService:JSONDecode(manifestData)

    makefolder(pkgPath)
    writefile(pkgPath.."/pkg.json", manifestData)

    -- dependencies
    for dep, _ in pairs(manifest.dependencies or {}) do
        install(dep)
    end

    -- files
    for _, file in ipairs(manifest.files or {}) do
        local content = httpGet(githubRaw(repo, branch, file))
        if content then
            writefile(pkgPath.."/"..file, content)
            print("[LPM] +", file)
        end
    end

    print("[LPM] Installed:", repo)
end

-- REQUIRE
local function requirePkg(repo)
    local pkgName = safeName(repo)

    if loaded[pkgName] then
        return loaded[pkgName]
    end

    local base = "lpm/packages/"..pkgName.."/"

    if not isfolder(base) then
        error("[LPM] Not installed: "..repo)
    end

    local manifest = HttpService:JSONDecode(readfile(base.."pkg.json"))
    local entry = manifest.entry or "init.lua"

    local source = readfile(base..entry)
    local fn, err = loadstring(source)

    if not fn then error(err) end

    local result = fn()
    loaded[pkgName] = result

    return result
end

-- UPDATE
local function update(repo)
    local pkgName = safeName(repo)
    local path = "lpm/packages/"..pkgName

    if isfolder(path) then
        delfolder(path)
    end

    install(repo)
end

-- REMOVE
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

local function remove(repo)
    local pkgName = safeName(repo)
    local path = "lpm/packages/"..pkgName

    if isfolder(path) then
        deleteFolder(path)
        print("[LPM] Removed:", repo)
    end
end

-- API
_G.lpm = function(action, repo)
    if action == "install" then
        install(repo)

    elseif action == "require" then
        return requirePkg(repo)

    elseif action == "update" then
        update(repo)

    elseif action == "remove" then
        remove(repo)

    else
        error("[LPM] Unknown action")
    end
end

print("[LPM] Loaded (auto-update enabled)")
