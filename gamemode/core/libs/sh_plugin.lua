lia.module = lia.module or {}
lia.module.list = lia.module.list or {}
lia.module.unloaded = lia.module.unloaded or {}

function lia.module.load(uniqueID, path, isSingleFile, variable)
    variable = uniqueID == "schema" and "SCHEMA" or variable or "MODULE"
    if hook.Run("ModuleShouldLoad", uniqueID) == false then return end
    -- Do not load non-existent Modules.
    if not isSingleFile and not file.Exists(path .. "/sh_" .. variable:lower() .. ".lua", "LUA") then return end
    -- Create a table to store module information.
    local oldModule = MODULE

    local MODULE = {
        folder = path,
        module = oldModule,
        uniqueID = uniqueID,
        name = "Unknown",
        desc = "Description not available",
        author = "Anonymous",
        IsValid = function(module)
            return true
        end
    }

    if uniqueID == "schema" then
        -- If the module is actually the schema, overwrite delevant variables.
        if SCHEMA then
            MODULE = SCHEMA
        end

        variable = "SCHEMA"
        MODULE.folder = engine.ActiveGamemode()
    elseif lia.module.list[uniqueID] then
        -- Handle auto-reload.
        MODULE = lia.module.list[uniqueID]
    end

    -- Expose MODULE as a global so the module files can access the table.
    _G[variable] = MODULE
    -- Then include all of the module files so they run.
    MODULE.loading = true
    MODULE.path = path

    if not isSingleFile then
        lia.module.loadExtras(path)
    end

    lia.util.include(isSingleFile and path or path .. "/sh_" .. variable:lower() .. ".lua", "shared")
    MODULE.loading = false
    -- Add helper methods for persistent data.
    local uniqueID2 = uniqueID

    if uniqueID2 == "schema" then
        uniqueID2 = MODULE.name
    end

    function MODULE:setData(value, global, ignoreMap)
        lia.data.set(uniqueID2, value, global, ignoreMap)
    end

    function MODULE:getData(default, global, ignoreMap, refresh)
        return lia.data.get(uniqueID2, default, global, ignoreMap, refresh) or {}
    end

    -- Add listeners for the module hooks so they run.
    for k, v in pairs(MODULE) do
        if type(v) == "function" then
            hook.Add(k, MODULE, v)
        end
    end

    -- Store a reference to the module for later access.
    if uniqueID == "schema" then
        function MODULE:IsValid()
            return true
        end
    else
        lia.module.list[uniqueID] = MODULE
        _G[variable] = oldModule
    end

    -- Signal that a module has finished loading.
    hook.Run("ModuleLoaded", uniqueID, MODULE)

    if MODULE.OnLoaded then
        MODULE:OnLoaded()
    end
end

function lia.module.loadExtras(path)
    lia.util.includeDir(path .. "/libs", true, true)
    lia.faction.loadFromDir(path .. "/factions")
    lia.class.loadFromDir(path .. "/classes")
    lia.util.includeDir(path .. "/derma", true)
    lia.module.loadEntities(path .. "/entities")
    lia.lang.loadFromDir(path .. "/languages")
    lia.module.loadFromDir(path .. "/modules")
    hook.Run("DoModuleIncludes", path, MODULE)
    local hookID = "liaItems" .. path

    hook.Add("InitializedModules", hookID, function()
        lia.item.loadFromDir(path .. "/items")
        hook.Remove("InitializedModules", hookID)
    end)
end

function lia.module.loadEntities(path)
    local files, folders

    local function IncludeFiles(path2, clientOnly)
        if (SERVER and file.Exists(path2 .. "init.lua", "LUA")) or (CLIENT and file.Exists(path2 .. "cl_init.lua", "LUA")) then
            lia.util.include(path2 .. "init.lua", clientOnly and "client" or "server")

            if file.Exists(path2 .. "cl_init.lua", "LUA") then
                lia.util.include(path2 .. "cl_init.lua", "client")
            end

            return true
        elseif file.Exists(path2 .. "shared.lua", "LUA") then
            lia.util.include(path2 .. "shared.lua", "shared")

            return true
        end

        return false
    end

    local function HandleEntityInclusion(folder, variable, register, default, clientOnly)
        files, folders = file.Find(path .. "/" .. folder .. "/*", "LUA")
        default = default or {}

        for k, v in ipairs(folders) do
            local path2 = path .. "/" .. folder .. "/" .. v .. "/"
            _G[variable] = table.Copy(default)
            _G[variable].ClassName = v

            if IncludeFiles(path2, clientOnly) and not client then
                if clientOnly then
                    if CLIENT then
                        register(_G[variable], v)
                    end
                else
                    register(_G[variable], v)
                end
            end

            _G[variable] = nil
        end

        for k, v in ipairs(files) do
            local niceName = string.StripExtension(v)
            _G[variable] = table.Copy(default)
            _G[variable].ClassName = niceName
            lia.util.include(path .. "/" .. folder .. "/" .. v, clientOnly and "client" or "shared")

            if clientOnly then
                if CLIENT then
                    register(_G[variable], niceName)
                end
            else
                register(_G[variable], niceName)
            end

            _G[variable] = nil
        end
    end

    -- Include entities.
    HandleEntityInclusion("entities", "ENT", scripted_ents.Register, {
        Type = "anim",
        Base = "base_gmodentity",
        Spawnable = true
    })

    -- Include weapons.
    HandleEntityInclusion("weapons", "SWEP", weapons.Register, {
        Primary = {},
        Secondary = {},
        Base = "weapon_base"
    })

    -- Include effects.
    HandleEntityInclusion("effects", "EFFECT", effects and effects.Register, nil, true)
end

function lia.module.initialize()
    lia.module.loadFromDir(engine.ActiveGamemode() .. "/preload")
    lia.module.load("schema", engine.ActiveGamemode() .. "/schema")
    hook.Run("InitializedSchema")
    lia.module.loadFromDir("lilia/modules")
    lia.module.loadFromDir(engine.ActiveGamemode() .. "/modules")
    hook.Run("InitializedModules")
    hook.Run("InitializedItems")
end

function lia.module.loadFromDir(directory)
    local files, folders = file.Find(directory .. "/*", "LUA")

    for k, v in ipairs(folders) do
        lia.module.load(v, directory .. "/" .. v)
    end

    for k, v in ipairs(files) do
        lia.module.load(string.StripExtension(v), directory .. "/" .. v, true)
    end
end

function lia.module.setDisabled(uniqueID, disabled)
    disabled = tobool(disabled)
    local oldData = table.Copy(lia.data.get("unloaded", {}, false, true))
    oldData[uniqueID] = disabled
    lia.data.set("unloaded", oldData, false, true, true)
end

function lia.module.isDisabled(uniqueID)
    if istable(DISABLED_MODULES) and DISABLED_MODULES[uniqueID] then return true end

    return lia.data.get("unloaded", {}, false, true)[uniqueID] == true
end