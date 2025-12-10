function save_options (options) --> nil
    for _, option in pairs(options) do
        ini.write("user/options.ini", option.key, option.options[option.current][2])
    end
end

function options_screen () --> nil
    local LANG = {
        en = 1,
        sp = 2
    }
    local index = 1
    local y
    local options = {}
    table.insert(options,
        {
            name = TEXT.opt_confirm_button,
            current = circle_to_confirm and 2 or 1,
            options = {
                {"X", "false"},
                {"O", "true"}
            },
            key = "circle_to_confirm"
        })
    table.insert(options,
        {
            name = TEXT.opt_default_game,
            current = default_game,
            options = {
                {"P3rd", "p3rd"},
                {"P3rdHD", "p3rdhd"}
            },
            key = "default_game"
        })
    table.insert(options,
        {
            name = TEXT.opt_language,
            current = LANG[language],
            options = {
                {"English", "en"},
                {"Español", "sp"}
            },
            key = "language"
        })
    table.insert(options,
        {
            name = TEXT.always_clear,
            current = always_clear and 2 or 1,
            options = {
                {TEXT.no, "false"},
                {TEXT.yes, "true"}
            },
            key = "always_clear"
        })
    table.insert(options,
        {
            name = TEXT.opt_install_scripts,
            current = run_install_scripts and 2 or 1,
            options = {
                {TEXT.install_script_no, "false"},
                {TEXT.install_script_ok, "true"}
            },
            key = "run_install_scripts"
        })
    
    frame = 0
    while true do
        buttons.read()

        frame = (frame + 1) % 100
        if game_sel_bg then game_sel_bg:blit(0,0) end
        screen.print(240 - screen.textwidth(TEXT.options_upper, 1) / 2, 12, TEXT.options_upper, 1, color.black)

        y = 60

        alpha = (3 * frame) * (frame < 51 and 1 or -1)
        if alpha < 0 then alpha = (alpha % 150) end

        draw.fillrect(0, y+index*12-12, 480, 14, color.new(50, 232, 1, alpha + 30))
        for _, option in pairs(options) do
            screen.print(120, y, option.name, 0.6, color.black)
            screen.print(320 - screen.textwidth(option.options[option.current][1], 0.6) / 2, y, option.options[option.current][1], 0.6, color.black)
            y += 12
        end

        if buttons.down then
            index += 1
            if index > #options then
                index = 1
            end
        elseif buttons.up then
            index -= 1
            if index < 1 then
                index = #options
            end
        elseif buttons.right then
            options[index].current += 1
            if options[index].current > #options[index].options then
                options[index].current = 1
            end
        elseif buttons.left then
            options[index].current -= 1
            if options[index].current < 1 then
                options[index].current = #options[index].options
            end
        end

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
        screen.print(394, 257, TEXT.ok, 0.6)

        screen.flip()
        if (circle_to_confirm and buttons.circle) or (not circle_to_confirm and buttons.cross) then -- confirm button 
            save_options(options)
        elseif (circle_to_confirm and buttons.cross) or (not circle_to_confirm and buttons.circle) then -- cancel button
            break
        end
    end
end
