if not loading_screen then loading_screen=image.load("assets/loading_screen.png") end

function load_list () --> table[str, table[str, any], table[str], int
    local mod_name, mod_type, game_ver
    local mods = {}
    local mod_ids = {}

    loading_screen:blit(0, 0)
    screen.flip()

    local mod_list = files.listdirs("MODS/")

    for _, dirs in ipairs(mod_list) do
        if files.exists(dirs["path"].."/mod.ini") then
            local mod_name = ini.read(dirs["path"].."/mod.ini", "MOD INFO", "Name_"..language, "null")
            if mod_name == "null" then
                mod_name = ini.read(dirs["path"].."/mod.ini", "MOD INFO", "Name", "null")
            end
            local mod_type = ini.read(dirs["path"].."/mod.ini", "MOD INFO", "Type", "null")
            local game_ver = ini.read(dirs["path"].."/mod.ini", "MOD INFO", "Version", "NOHD")
            local dependencies  = ini.read(dirs["path"].."/mod.ini", "MOD INFO", "Depends", "null")
            local script = ini.read(dirs["path"].."/mod.ini", "MOD INFO", "Script", "null")
            local type5f = (string.sub(mod_type, 1, 5))
            local is_equip = type5f == "Equip"
            if is_equip or (game_ver == "BOTH" or game_ver == game_version) then
                local has_audio = is_equip and (ini.read(dirs["path"].."/mod.ini", "MOD INFO", "Audio", "null") != "null")
                local has_animations = is_equip and (ini.read(dirs["path"].."/mod.ini", "MOD INFO", "Animation", "null") != "null")
                mods[string.lower(dirs["name"])] = {
                    name = mod_name, 
                    enabled = false, 
                    type = mod_type, 
                    dest = nil, 
                    dest_id = nil,
                    has_audio = has_audio,
                    has_animations = has_animations,
                    depends = dependencies,
                    script = script
                }
                table.insert(mod_ids, string.lower(dirs["name"]))
            end
        end
    end

    mod_ids = sort_mods(mods, mod_ids, "name", false)

    return load_dest_ids(load_replaced(load_enabled(mods))), mod_ids, #mod_ids
end

function sort_mods (mods, mod_ids, key, reverse) --> table[str]
    local keys, aux, m_id, sorted_ids
    keys = {}
    aux = {}
    for _, m_id in pairs(mod_ids) do
        aux[mods[m_id][key]..mods[m_id]["name"]] = m_id
        table.insert(keys, mods[m_id][key]..mods[m_id]["name"])
    end

    if reverse then
        table.sort(keys, function(a, b) return a > b end)
    else
        table.sort(keys)
    end

    sorted_ids = {}
    for _, v in pairs(keys) do
        table.insert(sorted_ids, aux[v])
    end
    
    return sorted_ids
end

function load_dest_ids (mods) --> table[str, {str, bool}]
    local dest_ids = ini.read(dest_ids_db, "ids", "null")

    for mod in string.gmatch(dest_ids, "([^';']+)") do
        local mod_info = split(mod, ":")
        local mod_id, dest_id = mod_info[1], mod_info[2]
        if mods[mod_id] != nil then
            mods[mod_id]["dest_id"] = dest_id
            if mods[mod_id]["type"] == "EquipSET" then
                mods[mod_id]["dest"] = load_set(dest_id)
            elseif mods[mod_id]["type"] == "EquipCATSET" then
                mods[mod_id]["dest"] = load_cat_set_from_id(dest_id)
            end
        end
    end

    return mods
end

function load_replaced (mods) --> table[str, {str, bool}]
    local replaced = ini.read(replaced_db, "files", "null")

    for mod in string.gmatch(replaced, "([^';']+)") do
        if mods[string.sub(mod, 1, -5)] != nil then
            mods[string.sub(mod, 1, -5)]["dest"] = string.sub(mod, -4, -1)
        end
    end
    
    return mods
end

function load_enabled (mods) --> table[str, {str, bool}]
    local enabled = ini.read(enabled_db, "enabled", "nul")

    for mod in string.gmatch(enabled, "([^';']+)") do
        if mods[mod] != nil then
            mods[mod]["enabled"] = true
        end
    end
    
    return mods
end

function save_enabled (mods) --> nil
    enabled = ""
    for mod, info in pairs(mods) do
        if info["enabled"] then
            enabled = enabled..mod..";"
        end
    end
    ini.write(enabled_db, "enabled", enabled)
end

function get_deps(mods, mod, parent, iterations) --> table[str]
    local dep, sub_dep, sub_deps
    local deps = {}
    
    if mods[mod]["depends"] == "null" then
        return deps
    end
    for dep in string.gmatch(mods[mod]["depends"], "([^';']+)") do
        if (not aux_deps[dep] and dep != parent) then
            table.insert(deps, dep)
            aux_deps[dep] = true
        end
    end
    if iterations == 0 then
        return deps
    end
    for _, dep in pairs(deps) do
        sub_deps = get_deps(mods, dep, mod, iterations - 1)
        for _, sub_dep in pairs(sub_deps) do
            if (not aux_deps[dep] and dep != parent) then
                table.insert(deps, sub_dep)
                aux_deps[dep] = true
            end
        end
    end
    return deps
end

function remove_duplicates(input) --> table
    local e
    local aux = {}
    local res = {}
    for _, e in pairs(input) do
        if (not aux[e]) then
            table.insert(res, e)
            aux[e] = true
        end
    end
    return res
end

function toggle_mod(mod) --> nil
    local dest, dest_id
    if string.sub(mod["type"], 1, 5) == "Equip" then
        if mod["enabled"] then
            mod["enabled"] = false
            mod["dest"] = nil
            mod["dest_id"] = nil
        else
            dest, dest_id = select_replace(string.sub(mod["type"], 6, -1))
            if dest != nil then
                mod["enabled"] = true
                mod["dest"] = dest
                mod["dest_id"] = dest_id
            end
        end
    else --Files, Pack, Code
        if mod["script"] != "null" then
            if mod["enabled"] then
                mod["enabled"] = false
            else
                if run_install_scripts then
                    if confirm_msg(TEXT.run_install_script, 50) then
                        dofile("MODS/"..mod["script"])
                        mod["enabled"] = not mod["enabled"]
                    end
                else
                    msg_box(TEXT.enable_install_scripts, 50)
                end
            end
        else
            mod["enabled"] = not mod["enabled"]
        end
    end
end
