collectgarbage()
color.loadpalette()

dofile "code/anim_compiler.lua"
dofile "code/select_equipment.lua"
dofile "code/mods.lua"

if not bg then bg=image.load("assets/mm_background.png") end

SORT_MODES = {TEXT.sort_name, TEXT.sort_type}

buttons.interval(10, 10)

function split(str, sep) --> table[string]
    local parts = string.gmatch(str, "([^"..sep.."]+)")
    local res = {}
    for part in parts do
        table.insert(res, part)
    end
    return res
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
        target = dest
    else
        target = dest.."/"..string.upper(files.nopath(origin))
    end
    
    file = io.open(target, "wb")
    file:write(file_data)
    file:close()
end

function clear_files () --> nil
    files.delete("ms0:/"..modloader_root.."/FILES/")
    files.mkdir("ms0:/"..modloader_root.."/FILES/")
end

function copy_file (mod, origin, dest) --> nil
    if files.exists("ms0:/"..modloader_root.."/FILES/"..dest) then
        files.delete("ms0:/"..modloader_root.."/FILES/"..dest)
    end
    file_copy("MODS/"..mod.."/"..origin, "ms0:/"..modloader_root.."/FILES/"..dest, true)
    --files.rename("ms0:/"..modloader_root.."/files/"..files.nopath(origin), "ms0:/"..modloader_root.."/files/"..dest)
end

function get_target(mod_id) --> str
    local target = ini.read("MODS/"..mod_id.."/mod.ini", "MOD INFO", "Target", "null")
    if game_version == "HD" then
        local target_hd = ini.read("MODS/"..mod_id.."/mod.ini", "MOD INFO", "TargetHD", "null")
        if target_hd != "null" then
            target = target_hd
        end
    end

    return target
end

function get_mod_files(mod_id) --> str
    local file = ini.read("MODS/"..mod_id.."/mod.ini", "MOD INFO", "Files", "null")
    if game_version == "HD" then
        local file_hd = ini.read("MODS/"..mod_id.."/mod.ini", "MOD INFO", "FilesHD", "null")
        if file_hd != "null" then
            file = file_hd
        end
    end

    return file
end

function install_mods (mods) --> nil
    save_enabled(mods)

    if not files.exists("ms0:/"..modloader_root) then
        files.mkdir("ms0:/"..modloader_root)
        files.mkdir("ms0:/"..modloader_root.."/FILES")
        files.mkdir("ms0:/"..modloader_root.."/MODS")
    end

    local replaced = ""
    local dest_ids = ""
    local code_mods  = {}
    local anim_mods  = {}
    local file_mods  = {}
    local set_mods   = {}
    local cat_set_mods   = {}
    local patch_mods = {}
    
    local do_build_patches = false
    local compile_anims = false

    local mod, info

    for mod, info in pairs(mods) do
        if info["enabled"] then
            if info["type"] == "Pack" then
            elseif info["type"] == "Code" then
                table.insert(code_mods, mod)
            elseif info["type"] == "Patch" then
                do_build_patches = true

                file = split(get_mod_files(mod), ";")
                target = split(get_target(mod), ";")
                for i=1,#file do
                    if patch_mods[target[i]] == nil then
                        patch_mods[target[i]] = {}
                    end
                    table.insert(patch_mods[target[i]], {mod, file[i]})
                end
            elseif info["type"] == "EquipSET" then
                dest_ids = dest_ids..mod..":"..info["dest_id"]..";"
                file = split(get_mod_files(mod), ";")
                table.insert(set_mods, {mod, info["dest_id"], split(info["dest"], ","), file})
            elseif info["type"] == "EquipCATSET" then
                dest_ids = dest_ids..mod..":"..info["dest_id"]..";"
                file = split(get_mod_files(mod), ";")
                table.insert(cat_set_mods, {mod, info["dest_id"], split(info["dest"], ","), file})
            elseif info["dest"] != nil then
                replaced = replaced..mod..info["dest"]..";"
                file = get_mod_files(mod)
                copy_file(mod, file, info["dest"])
                
                if info["dest_id"] then
                    dest_ids = dest_ids..mod..":"..info["dest_id"]..";"
                end

                if info["dest_id"] != nil and info["has_animations"] then
                    anim_mods[mod] = info["dest_id"]
                    compile_anims = true
                end

                if info["dest_id"] != nil and info["has_audio"] then
                    local audio = split(ini.read("MODS/"..mod.."/mod.ini", "MOD INFO", "Audio", "null"), ";")

                    local header = ini.read(data_dir.."/AUDIO/"..string.sub(info["type"], 6, -1)..".ini", "header"..info["dest_id"], "null")
                    local bin = ini.read(data_dir.."/AUDIO/"..string.sub(info["type"], 6, -1)..".ini", "bin"..info["dest_id"], "null")

                    copy_file(mod, audio[1], header)
                    copy_file(mod, audio[2], bin)
                end
            elseif info["dest"] == nil then
                table.insert(file_mods, mod)
            end
        end
    end

    ini.write(replaced_db, "files", replaced)
    ini.write(dest_ids_db, "ids", dest_ids)
    if do_build_patches then
        build_patches(patch_mods)
    end
    if #file_mods > 0 then
        replace_files(file_mods)
    end
    if #set_mods > 0 then
        copy_sets(set_mods)
    end
    if #cat_set_mods > 0 then
        copy_cat_sets(cat_set_mods)
    end
    if #code_mods > 0 then
        build_mods_bin(code_mods)
    end
    if compile_anims then
        build_animations(anim_mods)
    end

    msg_box(TEXT.mods_applied, 100, 50)
end

function build_patches (patch_mods)  --> nil
    local target, patch, file, patches, data
    for target, patches in pairs(patch_mods) do
        local data = ""
        for _, patch in pairs(patches) do
            file = io.open("MODS/"..patch[1].."/"..patch[2], "rb")
            data = data..file:read("*all")
            file:close()
        end
        
        file = io.open("ms0:/"..modloader_root.."/FILES/"..target.."P", "wb")
        file:write(data)
        file:write(int_to_bytes(-1)..int_to_bytes(0))
        file:close()
    end
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

function copy_cat_sets(set_mods) --> nil
    for _, mod in pairs(set_mods) do
        for i=1,2 do
            if not mod[3][i] then
                debug_msg = "huh?"
                dofile"debug.lua"
            end
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
            copy_file(mod, replacements[i], dest)
        end
    end
end

function build_animations (anim_mods) --> nil
    local animations = {}
    --local mods = ""
    for mod, mdl_id in pairs(anim_mods) do
        --mods = mods..mod..":"..mdl_id..";"
        local animpath = "MODS/"..mod.."/"..ini.read("MODS/"..mod.."/mod.ini", "MOD INFO", "Animation", "null")
        table.insert(animations, {animpath, mdl_id})
    end
    --ini.write(anim_db, "Anim", mods)
    build_anim_pack(animations)
end

function build_mods_bin (mod_list) --> nil
    local mod_files, file_name, file
    file = io.open("ms0:/"..modloader_root.."/MODS.BIN", "w")

    for _, mod in pairs(mod_list) do
        mod_files = get_mod_files(mod)
        for mod_file in string.gmatch(mod_files, "([^';']+)") do
            file_name = string.upper(files.nopath(mod_file))
            file:write(string.char(string.len(file_name)+2))
            file:write("/"..file_name..string.char(0))

            file_copy("MODS/"..mod.."/"..mod_file, "ms0:/"..modloader_root.."/MODS", false)
        end
    end

    file:write(string.char(255))
    file:close()
end

function main () --> nil
    local mods, mod_ids, mod_count = load_list()

    if mod_count == 0 then
        msg_box(TEXT.no_mods, 95, 50)
        return
    end

    local x, y

    local last_img = nil
    local preview = nil
    local frame = 0
    local pages = math.ceil(mod_count / 10)

    local index = 1
    local page = 0

    local sel_alpha = 10
    local alpha_inc = true

    local sort_mode = 1
    local reverse_sort = false

    while true do
    buttons.read()

    if bg then bg:blit(0,0) end


    sel_alpha += alpha_inc and 3 or -3
    if sel_alpha <= 30 then
        alpha_inc = true
    elseif sel_alpha >= 180 then
        alpha_inc = false
    end

    screen.print(49, 53, TEXT.mod_list, 0.6, color.yellow)
    screen.print(216, 53, (page+1).."/"..pages, 0.6)

    local r_offset = 472 - screen.textwidth(TEXT.exit, 0.6)
    screen.print(r_offset, 257, TEXT.exit, 0.6)
    
    if circle_to_confirm then
        r_offset = r_offset - 16
        atlas:draw("cross", r_offset - 16, 257)
        r_offset = r_offset - screen.textwidth(TEXT.toggle, 0.6) - 2
        screen.print(r_offset, 257, TEXT.toggle, 0.6)
        r_offset = r_offset - 16
        atlas:draw("circle", r_offset, 257)
    else
        r_offset = r_offset - 16
        atlas:draw("circle", r_offset, 257)
        r_offset = r_offset - screen.textwidth(TEXT.toggle, 0.6) - 2
        screen.print(r_offset, 257, TEXT.toggle, 0.6)
        r_offset = r_offset - 16
        atlas:draw("cross", r_offset, 257)
    end
    
    r_offset = r_offset - screen.textwidth(TEXT.apply, 0.6) - 2
    screen.print(r_offset, 257, TEXT.apply, 0.6)
    r_offset = r_offset - 16
    atlas:draw("triangle", r_offset, 257)
    r_offset = r_offset - screen.textwidth(TEXT.clear_and_apply, 0.6) - 2
    screen.print(r_offset, 257, TEXT.clear_and_apply, 0.6)
    r_offset = r_offset - 16
    atlas:draw("square", r_offset, 257)
    
    screen.print(23, 257, SORT_MODES[sort_mode])
    if reverse_sort then
        atlas:draw("sort_desc", 99, 256)
    else
        atlas:draw("sort_asc", 99, 256)
    end
    y = 68
    draw.fillrect(41, y-16+16*index, 220, 15, color.new(50, 232, 1, sel_alpha))
    for i=page*10+1, (page == pages-1 and mod_count % 10 != 0) and (page*10) + mod_count % 10 or (page+1)*10 do
        screen.print(43, y, mods[mod_ids[i]]["name"], 0.6)
        if mods[mod_ids[i]]["enabled"] then
            atlas:draw("enabled_icon", 248, y+4)
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

    if last_img == mod_ids[page*10+index] then
        x = 284

        if mods[mod_ids[page*10+index]]["has_animations"] then
            atlas:draw("has_animations", x, 221)
            x += 20
        end

        if mods[mod_ids[page*10+index]]["has_audio"] then
            atlas:draw("has_audio", x, 221)
            x += 20
        end
    end

    if buttons.down then
        index += 1
        frame = 0
    elseif buttons.up then
        index -= 1
        frame = 0
    elseif buttons.left then
        page = page - 1
        if page < 0 then
            page = pages - 1
        end
        frame = 0
        index = math.min(((page == pages-1 and mod_count % 10 != 0) and mod_count % 10 or 10), index)
    elseif buttons.right then
        page = page + 1
        if page >= pages then
            page = 0
        end
        frame = 0
        index = math.min(((page == pages-1 and mod_count % 10 != 0) and mod_count % 10 or 10), index)
    end

    if index < 1 then
        index = ((page == pages-1 and mod_count % 10 != 0) and mod_count % 10 or 10)
    end

    if index > ((page == pages-1 and mod_count % 10 != 0) and mod_count % 10 or 10) then
        index = 1
    end

    if (circle_to_confirm and buttons.circle) or (not circle_to_confirm and buttons.cross) then -- confirm button
        local dep_name, deps = "", nil
        local enabled_deps = {}
        local depends_met = true
        if not mods[mod_ids[page*10+index]]["enabled"] and mods[mod_ids[page*10+index]]["depends"] != "null" then
            aux_deps = {}
            deps = remove_duplicates(get_deps(mods, mod_ids[page*10+index], "", 10))
            for _, mod in pairs(deps) do
                if mods[mod] then
                    if not mods[mod]["enabled"] then
                        toggle_mod(mods[mod])
                        table.insert(enabled_deps, mods[mod]["name"])
                    end
                else
                    depends_met = false
                    break
                end
            end
            deps = ""
            for _, dep_name in pairs(enabled_deps) do
                deps = deps.."\n"..dep_name
            end
            if deps != "" then
                msg_box(TEXT.enabled_deps, 10, 10, deps, 10, 40)
            end
            if depends_met then
                toggle_mod(mods[mod_ids[page*10+index]])
            end
        else
            toggle_mod(mods[mod_ids[page*10+index]])
        end
    elseif buttons.triangle then
        install_mods(mods)
    elseif buttons.square then
        clear_files()
        install_mods(mods)
    elseif buttons.r then
        sort_mode += 1
        if sort_mode > #SORT_MODES then
            sort_mode = 1
        end
        mod_ids = sort_mods(mods, mod_ids, string.lower(SORT_MODES[sort_mode]), reverse_sort)
        frame = 0
    elseif buttons.l then
        reverse_sort = not reverse_sort
        mod_ids = sort_mods(mods, mod_ids, string.lower(SORT_MODES[sort_mode]), reverse_sort)
        frame = 0
    elseif (circle_to_confirm and buttons.cross) or (not circle_to_confirm and buttons.circle) then -- cancel button
        break
    end

    screen.flip()
    end
end

main()
