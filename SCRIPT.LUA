collectgarbage()
color.loadpalette()

dofile "code/atlas.lua"
dofile "code/msg_box.lua"
dofile "code/iso_patching.lua"

if not game_sel_bg then game_sel_bg=image.load("assets/game_sel_background.png") end
if not atlas.image then atlas.image=image.load("assets/atlas.png") end
if not p3rd_logo then p3rd_logo=image.load("assets/p3rd_logo.png") end
if not p3rd_hd_logo then p3rd_hd_logo=image.load("assets/p3rd_hd_logo.png") end

dofile "code/options_screen.lua"
dofile "code/load_options.lua"


buttons.interval(10, 10)

selection = default_game - 1

while true do
    buttons.read()

    if game_sel_bg then game_sel_bg:blit(0,0) end

    if atlas.image then
        if circle_to_confirm then
            atlas:draw("circle", 380, 257)
            atlas:draw("cross", 433, 257)
        else
            atlas:draw("cross", 380, 257)
            atlas:draw("circle", 433, 257)
        end

        atlas:draw("square", 317, 257)
        atlas:draw("triangle", 253, 257)
    end

    screen.print(448, 257, TEXT.exit, 0.6)
    screen.print(394, 257, TEXT.select, 0.6)
    screen.print(268, 257, TEXT.patch, 0.6)
    screen.print(331, 257, TEXT.options, 0.6)

    if selection == 0 then
        if p3rd_hd_logo then p3rd_hd_logo:blit(246, 61, 1, 1, 222, 150) end
        draw.fillrect(0, 0, 480, 256, color.new(1, 1, 1, 179))
        if p3rd_logo then p3rd_logo:blit(12, 61, 1, 1, 222, 150) end
    else
        if p3rd_logo then p3rd_logo:blit(12, 61, 1, 1, 222, 150) end
        draw.fillrect(0, 0, 480, 256, color.new(1, 1, 1, 179))
        if p3rd_hd_logo then p3rd_hd_logo:blit(246, 61, 1, 1, 222, 150) end
    end

    screen.print(23, 257, "v0.16.0c")

    if buttons.right or buttons.left then
        selection = (selection*-1)+1
    elseif buttons.square then
        options_screen()
        load_options()
    elseif (circle_to_confirm and buttons.cross) or (not circle_to_confirm and buttons.circle) then -- cancel button
        break
    elseif (circle_to_confirm and buttons.circle) or (not circle_to_confirm and buttons.cross) then -- confirm button
        if selection == 0 then
            game_version = "NOHD"
            modloader_root = "P3RDML"
            enabled_db = "user/nohd/enabled.ini"
            replaced_db = "user/nohd/replaced_files.ini"
            dest_ids_db = "user/nohd/dest_ids.ini"
            data_dir = "DATA"
            anim_start_offset = 0x99C0000
        else
            game_version = "HD"
            modloader_root = "P3RDHDML"
            enabled_db = "user/hd/enabled.ini"
            replaced_db = "user/hd/replaced_files.ini"
            dest_ids_db = "user/hd/dest_ids.ini"
            data_dir = "DATA_HD"
            anim_start_offset = 0x0B000400
        end
        dofile "code/main.lua"
    elseif buttons.triangle then
        patch_menu()
    end

    screen.flip()
end
