function find_file(cur_path, header) --> string
    local file_list, file, index, y_offset, i, max_files

    file_list = files.list(cur_path)
    index = 1
    while true do
        buttons.read()
        
        if atlas.image then
            if circle_to_confirm then
                atlas:draw("circle", 380, 257)
                atlas:draw("cross", 433, 257)
            else
                atlas:draw("cross", 380, 257)
                atlas:draw("circle", 433, 257)
            end
        end

        screen.print(448, 257, TEXT.exit, 0.6)
        screen.print(394, 257, TEXT.select, 0.6)
        screen.print(24, 24, header, 1, color.white)
        screen.print(400, 24, index.."/"..#file_list, 1, color.white)

        y_offset = 46
        for i= (index - math.min(index - 1, 5)), math.min(index + 18, #file_list) do
            screen.print(35, y_offset, file_list[i]["name"], 0.6, i == index and color.green or color.white)
            y_offset = y_offset + 12
        end

        screen.flip()
        if buttons.down then
            index += 1
        elseif buttons.up then
            index -= 1
        end
        
        if index < 1 then
            index = #file_list
        end
        if index > #file_list then
            index = 1
        end

        if (circle_to_confirm and buttons.cross) or (not circle_to_confirm and buttons.circle) then -- cancel button
            if cur_path == files.nofile(cur_path) then
                return nil
            end
            cur_path = files.nofile(cur_path)
            file_list = files.list(cur_path)
            index = 1
        elseif (circle_to_confirm and buttons.circle) or (not circle_to_confirm and buttons.cross) then -- confirm button
            if file_list[index]["directory"] then
                cur_path = file_list[index]["path"]
                file_list = files.list(cur_path)
                index = 1
            else
                return file_list[index]["path"]
            end
        end
    end
end

function patch_menu() --> nil
    local iso_path = find_file("ms0:/", TEXT.select_iso)
    if iso_path == nil then
        msg_box(TEXT.patch_canceled, 85, 50)
        return
    end
    local patch_path = find_file("PATCHES/", TEXT.select_patch)
    if iso_path != nil and patch_path != nil then
        patch_iso(patch_path, iso_path)
        msg_box(TEXT.patch_applied, 90, 50)
    else
        msg_box(TEXT.patch_canceled, 85, 50)
    end
end

function patch_iso(patch_path, iso_path) --> nil
    local data, patch, iso, step
    local chunk_size = 0x500
    local patch_size = files.size(patch_path)
    local steps = {".", "..", "..."}
    step = 1
    patch = io.open(patch_path, "rb")
    iso = io.open(iso_path, "rb+")
    iso:seek("set", 0x110000)
    data = patch:read(chunk_size)
    while data != nil do
        screen.print(40, 40, TEXT.patching..steps[math.floor(step/10) % 3 + 1])
        screen.print(40, 60, math.floor(step*chunk_size*100/patch_size).."%")
        step = step + 1
        iso:write(data)
        data = patch:read(chunk_size)
        screen.flip()
    end
    iso:close()
    patch:close()
end
