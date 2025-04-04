collectgarbage()
color.loadpalette()

dofile "anim_compiler.lua"

if not bg then bg=image.load("assets/mm_background.png") end
if not enabled_icon then enabled_icon=image.load("assets/enabled.png") end

buttons.interval(10, 10)

function split(str, sep) --> table[string]
    local parts = string.gmatch(str, "([^"..sep.."]+)")
    local res = {}
    for part in parts do
        table.insert(res, part)
    end
    return res
end

function load_equipment (eq_type) --> table[int], table[str], int
    file_list = {}
    names = {}
    parts = ini.read(data_dir.."/EQUIPMENT_LIST/"..eq_type..".ini", "files", "")
    count = 0
    for file in string.gmatch(parts, "([^;]+)") do
        table.insert(file_list, string.sub(file, -4, -1))
        table.insert(names, string.sub(file, 1, -5))
        count += 1
    end
    return file_list, names, count
end

function select_replace (equip_type) --> nil
    parts, part_names, part_count = load_equipment(equip_type)

    index_s, y_s = 1, 17

    while true do
    buttons.read()

    screen.print(35, 5, "Parts List", 0.6)
    max = part_count < 15+index_s and part_count or 15+index_s
    y_s = 22
    screen.print(25, y_s, ">", 0.6)
    screen.print(400, 5, index_s.."/"..part_count, 0.6)
    for i=index_s, max do
        screen.print(35, y_s, part_names[i], 0.6)
        y_s = y_s + 12
    end

    screen.print(105, 240, "O To exit", 0.6)
    screen.print(25, 240, "X To Select", 0.6)

    if buttons.down then
        index_s += 1
        y_s += 12
    elseif buttons.up then
        index_s -= 1
        y_s -= 12
    end

    if index_s < 1 then
        index_s, y_s = part_count, part_count*12+22
    end

    if index_s > part_count then
        index_s, y_s = 1, 22
    end

    if buttons.cross then
        return parts[index_s]
    elseif buttons.circle then
        return nil
    end

    screen.flip()
    end
end

function load_list () --> table[str, table[str], {str, bool, str}], int
    mods = {}
    mod_ids = {}

    mod_list = files.listdirs("MODS/")
    for _, dirs in ipairs(mod_list) do
        if files.exists(dirs["path"].."/mod.ini") then
            mod_name = ini.read(dirs["path"].."/mod.ini", "MOD INFO", "Name", "null")
            mod_type = ini.read(dirs["path"].."/mod.ini", "MOD INFO", "Type", "null")
            game_ver = ini.read(dirs["path"].."/mod.ini", "MOD INFO", "Version", "NOHD")
            if (string.sub(mod_type, 1, 5) == "Equip") or (game_ver == game_version) then
                mods[dirs["name"]] = {mod_name, false, mod_type, null}
                table.insert(mod_ids, dirs["name"])
            end
        end
    end

    return load_animations(load_replaced(load_enabled(mods))), mod_ids, #mod_ids
    -- esto crashea con exactamente 10 mods
end

function load_replaced (mods) --> table[str, {str, bool}]
    local replaced = ini.read(replaced_db, "files", "nul")

    for mod in string.gmatch(replaced, "([^';']+)") do
        if mods[string.sub(mod, 1, -5)] != nil then
            mods[string.sub(mod, 1, -5)][4] = string.sub(mod, -4, -1)
        end
    end
    
    return mods
end

function load_animations (mods) --> table[str, {str, bool}]
    local anim = ini.read(anim_db, "Anim", "nul")
    local mod_id = ""
    for mod in string.gmatch(anim, "([^';']+)") do
        mod = split(mod, ":")
        if mods[mod[1]] != nil then
            mods[mod[1]][5] = mod[2]
        end
    end

    return mods
end

function load_enabled (mods) --> table[str, {str, bool}]
    local enabled = ini.read(enabled_db, "enabled", "nul")

    for mod in string.gmatch(enabled, "([^';']+)") do
        if mods[mod] != nil then
            mods[mod][2] = true
        end
    end
    
    return mods
end

function save_enabled (mods) --> nil
    enabled = ""
    for mod, info in pairs(mods) do
        if info[2] then
            enabled = enabled..mod..";"
        end
    end
    ini.write(enabled_db, "enabled", enabled)
end

function clear_files () --> nil
    files.delete("ms0:/"..modloader_root.."/files/")
    files.mkdir("ms0:/"..modloader_root.."/files/")
end

function copy_file (mod, origin, dest) --> nil
    files.copy("MODS/"..mod.."/"..origin, "ms0:/"..modloader_root.."/files/")
    if files.exists("ms0:/"..modloader_root.."/files/"..dest) then
        files.delete("ms0:/"..modloader_root.."/files/"..dest)
    end
    files.rename("ms0:/"..modloader_root.."/files/"..origin, "ms0:/"..modloader_root.."/files/"..dest)
end

function install_mods (mods) --> nil
    save_enabled(mods)

    replaced = ""
    code_mods = {}
    anim_mods = {}
    file_mods = {}
    compile_anims = false

    for mod, info in pairs(mods) do
        if info[2] then
            if info[3] == "Pack" then
                local code = ini.read("MODS/"..mod.."/mod.ini", "MOD INFO", "Code", "null")
                if code != "null" then
                    code = split(code, ";")
                    for _, child in pairs(code) do
                        table.insert(code_mods, mod.."/"..child)
                    end
                end
                local file = ini.read("MODS/"..mod.."/mod.ini", "MOD INFO", "File", "null")
                if file != null then
                    for _, mod in split(file, ";") do
                        table.insert(file_mods, mod)
                    end
                end

            elseif info[3] == "Code" then
                table.insert(code_mods, mod)
            elseif info[4] != nil then
                replaced = replaced..mod..info[4]..";"
                file = ini.read("MODS/"..mod.."/mod.ini", "MOD INFO", "Files", "null")
                copy_file(mod, file, info[4])

                if info[5] != nil and ini.read("MODS/"..mod.."/mod.ini", "MOD INFO", "Animation", "null") != "null" then
                    anim_mods[mod] = info[5]
                    compile_anims = true
                end
            elseif info[4] == nil then
                table.insert(file_mods, mod)
            end
        end
    end

    ini.write(replaced_db, "files", replaced)
    if #file_mods > 0 then
        replace_files(file_mods)
    end
    if #code_mods > 0 then
        build_mods_bin(code_mods)
    end
    if compile_anims then
        build_animations(anim_mods)
    end
end

function replace_files (file_mods) --> nil
    for _, mod in pairs(file_mods) do
        local targets = {}
        local replacements = {}
        for file in string.gmatch(ini.read("MODS/"..mod.."/mod.ini", "MOD INFO", "Target", "null"), "([^;]+)") do
            table.insert(targets, file)
        end
        for file in string.gmatch(ini.read("MODS/"..mod.."/mod.ini", "MOD INFO", "Files", "null"), "([^;]+)") do
            table.insert(replacements, file)
        end
        
        for i, dest in pairs(targets) do
            copy_file(mod, replacements[i], dest)
        end
    end
end

function build_animations (anim_mods) --> nil
    local animations = {}
    local mods = ""
    for mod, mdl_id in pairs(anim_mods) do
        mods = mods..mod..":"..mdl_id..";"
        local animpath = "MODS/"..mod.."/"..ini.read("MODS/"..mod.."/mod.ini", "MOD INFO", "Animation", "null")
        table.insert(animations, {animpath, mdl_id})
    end
    ini.write(anim_db, "Anim", mods)
    build_anim_pack(animations)
end

function build_mods_bin (mod_list) --> nil
    file = io.open("ms0:/"..modloader_root.."/mods.bin", "w")
    io.output(file)

    for _, mod in pairs(mod_list) do
        mod_files = ini.read("MODS/"..mod.."/mod.ini", "MOD INFO", "Files", "null")
        for mod_file in string.gmatch(mod_files, "([^';']+)") do
            io.write(string.char(string.len(mod_file)+2))
            io.write("/"..mod_file..string.char(0))

            files.copy("MODS/"..mod.."/"..mod_file, "ms0:/"..modloader_root.."/mods/")
        end
    end

    io.write(string.char(255))

    io.close(file)
end

function main () --> nil
    mods, mod_ids, mod_count = load_list()
    last_img = nil
    preview = nil
    frame = 0
    pages = math.ceil(mod_count / 10)

    index = 1
    page = 0

    sel_alpha = 10
    alpha_inc = true

    while true do
    buttons.read()

    if bg then bg:blit(0,0) end


    sel_alpha += alpha_inc and 3 or -3
    if sel_alpha <= 30 then
        alpha_inc = true
    elseif sel_alpha >= 180 then
        alpha_inc = false
    end

    screen.print(49, 53, "Mod list", 0.6, color.yellow)
    screen.print(216, 53, (page+1).."/"..pages, 0.6)
    y = 68
    draw.fillrect(41, y-16+16*index, 220, 15, color.new(50, 232, 1, sel_alpha))
    for i=page*10+1, (page == pages-1 and mod_count % 10 != 0) and (page*10) + mod_count % 10 or (page+1)*10 do
        screen.print(43, y, mods[mod_ids[i]][1], 0.6)--, mods[mod_ids[i]][2] and color.green or  color.red)
        if mods[mod_ids[i]][2] then
            enabled_icon:blit(248, y+4)
        end
        y += 16
    end

    if last_img != mod_ids[page*10+index] and frame >= 30 then
        last_img = mod_ids[page*10+index]
        if files.exists("MODS/"..mod_ids[page*10+index].."/preview.png") then
            preview = image.load("MODS/"..mod_ids[page*10+index].."/preview.png")
        else
            preview = nil
        end
    end

    frame = math.min(frame+1, 50)

    if preview != nil then
        preview:blit(273, 55)
    end

    if buttons.down then
        index += 1
        frame = 0
    elseif buttons.up then
        index -= 1
        frame = 0
    elseif buttons.left then
        page = math.max(0, page-1)
        frame = 0
    elseif buttons.right then
        page = math.min(pages-1, page+1)
        frame = 0
    end

    if index < 1 then
        index = ((page == pages-1 and mod_count % 10 != 0) and mod_count % 10 or 10)
    end

    if index > ((page == pages-1 and mod_count % 10 != 0) and mod_count % 10 or 10) then
        index = 1
    end

    if buttons.cross then
        if string.sub(mods[mod_ids[page*10+index]][3], 1, 5) == "Equip" then
            if mods[mod_ids[page*10+index]][2] then
                mods[mod_ids[page*10+index]][2] = false
                mods[mod_ids[page*10+index]][4] = nil
            else
                dest = select_replace(string.sub(mods[mod_ids[page*10+index]][3], 6, -1))
                if dest != nil then
                    mods[mod_ids[page*10+index]][2] = true
                    mods[mod_ids[page*10+index]][4] = dest
                    mods[mod_ids[page*10+index]][5] = index_s - 1
                end
            end
        else --Files, Pack, Code
            mods[mod_ids[page*10+index]][2] = not mods[mod_ids[page*10+index]][2]
        end
    elseif buttons.triangle then
        install_mods(mods)
    elseif buttons.square then
        clear_files()
        install_mods(mods)
    elseif buttons.circle then
        break
    end

    screen.flip()
    end
end

main()
