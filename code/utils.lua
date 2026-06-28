function int_to_bytes(int) --> bytes
    local bin = string.char(int & 0xFF)..string.char((int >> 8) & 0xFF)
    bin = bin..string.char((int >> 16) & 0xFF)..string.char((int >> 24) & 0xFF)
    return bin
end

function file_copy(origin, dest, is_file) --> nil
    local target
    if not is_file and not files.exists(dest) then
        files.mkdir(dest)
    end

    local file = io.open(origin, "rb")
    local file_data = file:read("*all")
    file:close()
    
    if is_file then
        if not files.exists(files.nofile(dest)) then
            files.mkdir(files.nofile(dest))
        end
        target = dest
    else
        target = dest.."/"..string.upper(files.nopath(origin))
    end
    
    file = io.open(target, "wb")
    file:write(file_data)
    file:close()
end

function copy_sets(set_mods) --> nil
    for _, mod in pairs(set_mods) do
        for i=1,5 do
            if mod[3][i] != "null" and mod[4][i] != "null" then
                copy_file(mod[1], mod[4][i], mod[3][i])
            end
        end
    end
end

function replace_files (file_mods) --> nil
    local target, files
    for _, mod in pairs(file_mods) do
        local targets = {}
        local replacements = {}

        target = get_target(mod)
        files = get_mod_files(mod)

        for file in string.gmatch(target, "([^;]+)") do
            table.insert(targets, file)
        end
        for file in string.gmatch(files, "([^;]+)") do
            table.insert(replacements, file)
        end
        
        for i, dest in pairs(targets) do
            if game_version == "FUC" then
                table.insert(replaced_files, dest)
            end
            copy_file(mod, replacements[i], dest)
        end
    end
end

function get_field(mod_id, field) --> str
    local data = ini.read(MODS_DIR..mod_id.."/mod.ini", "MOD INFO", field, "null")
    return data
end

function toggle_mod_list(mods, list, state) --> nil
    for _, mod_id in pairs(split(list, ";")) do
        toggle_mod_and_deps(mods, mod_id, state)
    end
end

function toggle_mod_and_deps(mods, mod_id, state) --> nil
    local dep_name, deps = "", nil
    local missing_deps = ""
    local enabled_deps = {}
    local depends_met = true
    if state != nil and not state then
        toggle_mod(mods[mod_id], false)
        return
    end
    if not mods[mod_id].enabled and mods[mod_id].depends != "null" then
        aux_deps = {}
        deps = remove_duplicates(get_deps(mods, mod_id, "", 10))
        for _, mod in pairs(deps) do
            if mods[mod] then
                if not mods[mod].enabled then
                    toggle_mod(mods[mod])
                    table.insert(enabled_deps, mods[mod]["name"])
                end
            else
                missing_deps = missing_deps..mod.."\n"
                depends_met = false
            end
        end
        deps = ""
        for _, dep_name in pairs(enabled_deps) do
            deps = deps.."\n"..dep_name
        end
        if deps != "" then
            msg_box(TEXT.enabled_deps, 10, deps, 40)
        end
        if depends_met then
            toggle_mod(mods[mod_id])
        else
            msg_box(TEXT.missing_deps, 10, missing_deps, 40)
        end
    else
        toggle_mod(mods[mod_id], state)
        end
end
