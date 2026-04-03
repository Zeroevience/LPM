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

    else
        error("[LPM] Unknown action: "..tostring(action))
    end
end

installDefaultPackages()

print("[LPM] Loaded")

return lpm
