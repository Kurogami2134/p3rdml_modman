function find_file(cur_path, header) --> string
    local file_list, file, index, y_offset, i, max_files

    file_list = files.list(cur_path)
    index = 1
    while true do
        buttons.read()
        
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
    local iso_path = find_file("ms0:/", "Select your ISO")
    if iso_path == nil then
        msg_box("Patch Canceled", 85, 50)
        return
    end
    local patch_path = find_file("PATCHES/", "Select your patch")
    if iso_path != nil and patch_path != nil then
        patch_iso(patch_path, iso_path)
        msg_box("Patch Applied", 90, 50)
    else
        msg_box("Patch Canceled", 85, 50)
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
        screen.print(40, 40, "Patching"..steps[math.floor(step/10) % 3 + 1])
        screen.print(40, 60, math.floor(step*chunk_size*100/patch_size).."%")
        step = step + 1
        iso:write(data)
        data = patch:read(chunk_size)
        screen.flip()
    end
    iso:close()
    patch:close()
end
