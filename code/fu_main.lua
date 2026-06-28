collectgarbage()
color.loadpalette()

dofile "code/anim_compiler.lua"
dofile "code/select_equipment.lua"
dofile "code/mods.lua"
dofile "code/utils.lua"

if not (bg and mmbg == "FUC") then bg=image.load("assets/fu_mm_background.png") end
mmbg = "FUC"

SORT_MODES = {TEXT.sort_name, TEXT.sort_type}
SORTING_KEYS = {"name", "type"}

buttons.interval(10, 10)

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


function clear_files () --> nil
    files.delete("ms0:/"..modloader_root.."/NATIVEPSP/")
    files.mkdir("ms0:/"..modloader_root.."/NATIVEPSP/")
end

function copy_file (mod, origin, dest) --> nil
    if files.exists("ms0:/"..modloader_root.."/NATIVEPSP/"..dest) then
        files.delete("ms0:/"..modloader_root.."/NATIVEPSP/"..dest)
    end
    file_copy(MODS_DIR..mod.."/"..origin, "ms0:/"..modloader_root.."/NATIVEPSP/"..dest, true, true)
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
    local anim_mods  = {}
    local code_mods  = {}
    local set_mods   = {}
    
    local do_build_patches = false
    local do_build_mods = false
    local compile_anims = false

    local mod, info

    for mod, info in pairs(mods) do
        if info["enabled"] then
            if info["type"] == "Pack" then
            elseif info["type"] == "Code" then
                do_build_mods = true
                if not code_mods[info.priority] then
                    prio_set = {}
                    code_mods[info.priority] = prio_set
                end
                table.insert(code_mods[info.priority], mod)
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

                if info["dest_id"] != nil and info["has_animations"] then
                    anim_mods[mod] = info["dest"] - 3388
                    compile_anims = true
                end

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
    if do_build_mods then
        build_mods_bin(code_mods)
        file_copy(data_dir.."/PRELOAD.BIN", "ms0:/"..modloader_root, false)
    end
    if compile_anims then
        build_animations(anim_mods)
    end
    create_index(replaced_files)

    msg_box(TEXT.mods_applied, 50)
end

function build_mods_bin (mod_table) --> nil
    local mod_files, file_name, file, priority
    file = io.open("ms0:/"..modloader_root.."/MMMODS.BIN", "w")

    for priority=0, 5 do
        if mod_table[tostring(priority)] then
            for _, mod in pairs(mod_table[tostring(priority)]) do
                mod_files = get_mod_files(mod)
                for mod_file in string.gmatch(mod_files, "([^';']+)") do
                    file_name = string.upper(files.nopath(mod_file))
                    file:write(string.char(string.len(file_name)+2))
                    file:write("/"..file_name..string.char(0))

                    file_copy(MODS_DIR..mod.."/"..mod_file, "ms0:/"..modloader_root.."/MMMODS", false)
                end
            end
        end
    end

    file:write(string.char(255))
    file:close()
end

function build_animations (anim_mods) --> nil
    local animations = {}
    --local mods = ""
    for mod, mdl_id in pairs(anim_mods) do
        --mods = mods..mod..":"..mdl_id..";"
        local animpath = MODS_DIR..mod.."/"..ini.read(MODS_DIR..mod.."/mod.ini", "MOD INFO", "Animation", "null")
        table.insert(animations, {animpath, mdl_id})
    end
    --ini.write(anim_db, "Anim", mods)
    build_anim_pack(animations, true)
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
    screen.print(201 + (50 - screen.textwidth((page+1).."/"..pages, 0.6)) / 2, 53, (page+1).."/"..pages, 0.6)

    local input_msg = " ::select::"..TEXT.description.." ::triangle::"..TEXT.apply.." ::square::"..TEXT.clear_and_apply..(circle_to_confirm and " ::circle::"..TEXT.toggle.." ::cross::"..TEXT.exit or " ::cross::"..TEXT.toggle.." ::circle::"..TEXT.exit)
    sp_print(input_msg, 476-sp_text_width(input_msg, 0.6), 257, 0.6)
    
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
        toggle_mod_and_deps()
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
    elseif buttons.select then  -- show description
        desc = ini.read(MODS_DIR..mod_ids[page*10+index].."/mod.ini", "MOD INFO", "Description", "")
        big_box(mods[mod_ids[page*10+index]]["name"], desc)
    elseif (circle_to_confirm and buttons.cross) or (not circle_to_confirm and buttons.circle) then -- cancel button
        break
    end

    screen.flip()
    end
end

main()
