--// LPM CORE (no _G, returns function)

local HttpService = game:GetService("HttpService")

local LPM_URL   = "https://raw.githubusercontent.com/Zeroevience/LPM/refs/heads/main/init.lua"
local LOCALPATH = "lpm/init.lua"

-- helpers
local function httpGet(url)
    local r = request({Url = url, Method = "GET"})
    if not r or not r.Body then return nil end
    return r.Body
end

local function githubRaw(repo, ref, path)
    return "https://raw.githubusercontent.com/"..repo.."/"..ref.."/"..path
end

local function safeName(repo)
    return repo:gsub("/", "_")
end

-- ensure folders
if not isfolder("lpm") then makefolder("lpm") end
if not isfolder("lpm/packages") then makefolder("lpm/packages") end

-- auto-update core (silent)
do
    local remote = httpGet(LPM_URL)
    if remote and isfile(LOCALPATH) then
        local localData = readfile(LOCALPATH)
        if localData ~= remote then
            writefile(LOCALPATH, remote)
            print("[LPM] Core updated.")
        end
    end
end

-- cache
local loaded = {}

-- install
local function install(repo)
    local ref     = "main"
    local name    = safeName(repo)
    local pkgPath = "lpm/packages/"..name

    if isfolder(pkgPath) then
        print("[LPM] Already installed:", repo)
        return
    end

    print("[LPM] Installing:", repo)

    local manifestRaw = httpGet(githubRaw(repo, ref, "pkg.json"))
    if not manifestRaw then
        error("[LPM] Failed to fetch pkg.json for "..repo)
    end

    local manifest = HttpService:JSONDecode(manifestRaw)

    makefolder(pkgPath)
    writefile(pkgPath.."/pkg.json", manifestRaw)

    -- deps
    for dep, _ in pairs(manifest.dependencies or {}) do
        install(dep)
    end

    -- files
    for _, file in ipairs(manifest.files or {}) do
        local content = httpGet(githubRaw(repo, ref, file))
        if content then
            writefile(pkgPath.."/"..file, content)
            print("[LPM] +", file)
        else
            warn("[LPM] Failed:", file)
        end
    end

    print("[LPM] Installed:", repo)
end

-- require
local function requirePkg(repo)
    local name = safeName(repo)

    if loaded[name] then
        return loaded[name]
    end

    local base = "lpm/packages/"..name.."/"
    if not isfolder(base) then
        error("[LPM] Not installed: "..repo)
    end

    local manifest = HttpService:JSONDecode(readfile(base.."pkg.json"))
    local entry    = manifest.entry or "init.lua"

    local src = readfile(base..entry)
    local fn, err = loadstring(src)
    if not fn then error("[LPM] Load error: "..err) end

    local result = fn()
    loaded[name] = result
    return result
end

-- update
local function update(repo)
    local name = safeName(repo)
    local path = "lpm/packages/"..name

    if isfolder(path) then
        -- delete recursively
        local function del(p)
            for _, f in ipairs(listfiles(p)) do
                if isfolder(f) then del(f) else delfile(f) end
            end
            delfolder(p)
        end
        del(path)
    end

    install(repo)
end

-- remove
local function remove(repo)
    local name = safeName(repo)
    local path = "lpm/packages/"..name

    if not isfolder(path) then
        warn("[LPM] Not installed:", repo)
        return
    end

    local function del(p)
        for _, f in ipairs(listfiles(p)) do
            if isfolder(f) then del(f) else delfile(f) end
        end
        delfolder(p)
    end
    del(path)

    print("[LPM] Removed:", repo)
end

-- exported function
local function lpm(action, repo)
    if action == "install" then
        return install(repo)
    elseif action == "require" then
        return requirePkg(repo)
    elseif action == "update" then
        return update(repo)
    elseif action == "remove" then
        return remove(repo)
    else
        error("[LPM] Unknown action: "..tostring(action))
    end
end

return lpm
