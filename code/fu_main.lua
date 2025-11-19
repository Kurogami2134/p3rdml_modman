collectgarbage()
color.loadpalette()

--dofile "code/anim_compiler.lua"
dofile "code/select_equipment.lua"
dofile "code/mods.lua"

if not (bg and mmbg == "FUC") then bg=image.load("assets/fu_mm_background.png") end
mmbg = "FUC"

SORT_MODES = {TEXT.sort_name, TEXT.sort_type}
SORTING_KEYS = {"name", "type"}

buttons.interval(10, 10)

function int_to_bytes(int) --> bytes
    local bin = string.char(int & 0xFF)..string.char((int >> 8) & 0xFF)
    bin = bin..string.char((int >> 16) & 0xFF)..string.char((int >> 24) & 0xFF)
    return bin
end

function create_index(MODS) --> nil
    table.sort(MODS)
    local file = io.open("ms0:/"..modloader_root.."/NATIVEPSP/FILE.BIN", "wb")
    local integer
    for i=1,207 do
        integer = 0
        while #MODS > 0 and math.floor(MODS[1] / 32) == i-1 do
            integer = integer | (1 << (MODS[1] % 32))
            table.remove(MODS, 1)
        end
        file:write(int_to_bytes(integer))
    end
    file:close()
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
    file:write(int_to_bytes(#file_data))
    file:write(file_data)
    file:close()
end

function clear_files () --> nil
    files.delete("ms0:/"..modloader_root.."/NATIVEPSP/")
    files.mkdir("ms0:/"..modloader_root.."/NATIVEPSP/")
end

function copy_file (mod, origin, dest) --> nil
    if files.exists("ms0:/"..modloader_root.."/NATIVEPSP/"..dest) then
        files.delete("ms0:/"..modloader_root.."/NATIVEPSP/"..dest)
    end
    file_copy(MODS_DIR..mod.."/"..origin, "ms0:/"..modloader_root.."/NATIVEPSP/"..dest, true)
end

function get_target(mod_id) --> str
    local target = ini.read(MODS_DIR..mod_id.."/mod.ini", "MOD INFO", "Target", "null")
    return target
end

function get_mod_files(mod_id) --> str
    local file = ini.read(MODS_DIR..mod_id.."/mod.ini", "MOD INFO", "Files", "null")
    return file
end

function install_mods (mods) --> nil
    save_enabled(mods)

    if not files.exists("ms0:/"..modloader_root) then
        files.mkdir("ms0:/PSP")
        files.mkdir("ms0:/PSP/SAVEDATA")
        files.mkdir("ms0:/"..modloader_root)
        files.mkdir("ms0:/"..modloader_root.."/NATIVE_PSP")
    end

    local replaced = ""
    replaced_files = {}
    local dest_ids = ""
    local file_mods  = {}
    local set_mods   = {}
    
    local do_build_patches = false
    local compile_anims = false

    local mod, info

    for mod, info in pairs(mods) do
        if info["enabled"] then
            if info["type"] == "Pack" then
            elseif info["type"] == "EquipSET" then
                dest_ids = dest_ids..mod..":"..info["dest_id"]..";"
                file = split(get_mod_files(mod), ";")
                table.insert(set_mods, {mod, info["dest_id"], split(info["dest"], ","), file})
            elseif info["dest"] != nil then
                replaced = replaced..mod..info["dest"]..";"
                table.insert(replaced_files, info["dest"])
                file = get_mod_files(mod)
                copy_file(mod, file, info["dest"])
                
                if info["dest_id"] then
                    dest_ids = dest_ids..mod..":"..info["dest_id"]..";"
                end

                --if info["dest_id"] != nil and info["has_animations"] then
                --    anim_mods[mod] = info["dest_id"]
                --    compile_anims = true
                --end

                --if info["dest_id"] != nil and info["has_audio"] then
                --    local audio = split(ini.read(MODS_DIR..mod.."/mod.ini", "MOD INFO", "Audio", "null"), ";")

                --    local header = ini.read(data_dir.."/AUDIO/"..string.sub(info["type"], 6, -1)..".ini", "header"..info["dest_id"], "null")
                --    local bin = ini.read(data_dir.."/AUDIO/"..string.sub(info["type"], 6, -1)..".ini", "bin"..info["dest_id"], "null")

                --    copy_file(mod, audio[1], header)
                --    copy_file(mod, audio[2], bin)
                --end
            elseif info["dest"] == nil then
                table.insert(file_mods, mod)
            end
        end
    end

    ini.write(replaced_db, "files", replaced)
    ini.write(dest_ids_db, "ids", dest_ids)
    if #file_mods > 0 then
        replace_files(file_mods)
    end
    if #set_mods > 0 then
        copy_sets(set_mods)
    end
    create_index(replaced_files)

    msg_box(TEXT.mods_applied, 50)
end

function copy_sets(set_mods) --> nil
    for _, mod in pairs(set_mods) do
        for i=1,5 do
            if mod[3][i] != "null" and mod[4][i] != "null" then
                table.insert(replaced_files, mod[3][i])
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
            table.insert(replaced_files, dest)
            copy_file(mod, replacements[i], dest)
        end
    end
end

function main () --> nil
    local mods, mod_ids, mod_count = load_list()

    if mod_count == 0 then
        msg_box(TEXT.no_mods, 50)
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
        if files.exists(MODS_DIR..mod_ids[page*10+index].."/preview.png") then
            preview = image.load(MODS_DIR..mod_ids[page*10+index].."/preview.png")
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
                msg_box(TEXT.enabled_deps, 10, deps, 40)
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
        mod_ids = sort_mods(mods, mod_ids, SORTING_KEYS[sort_mode], reverse_sort)
        frame = 0
    elseif buttons.l then
        reverse_sort = not reverse_sort
        mod_ids = sort_mods(mods, mod_ids, SORTING_KEYS[sort_mode], reverse_sort)
        frame = 0
    elseif (circle_to_confirm and buttons.cross) or (not circle_to_confirm and buttons.circle) then -- cancel button
        break
    end

    screen.flip()
    end
end

main()
