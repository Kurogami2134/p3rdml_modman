function save_options (options) --> nil
    for _, option in pairs(options) do
        ini.write("user/options.ini", option.key, option.options[option.current][2])
    end
end

function options_screen () --> nil
    local index = 1
    local y
    local options = {}
    table.insert(options,
        {
            name = "Confirm Button",
            current = circle_to_confirm and 2 or 1,
            options = {
                {"X", "false"},
                {"O", "true"}
            },
            key = "circle_to_confirm"
        })
    
    frame = 0
    while true do
        buttons.read()

        frame = (frame + 1) % 100
        if game_sel_bg then game_sel_bg:blit(0,0) end
        screen.print(198, 12, "OPTIONS", 1, color.black)

        y = 60

        alpha = (3 * frame) * (frame < 51 and 1 or -1)
        if alpha < 0 then alpha = (alpha % 150) end

        draw.fillrect(0, y+index*12-12, 480, 14, color.new(50, 232, 1, alpha + 30))
        for _, option in pairs(options) do
            screen.print(160, y, option.name, 0.6, color.black)
            screen.print(320-6*#option.options[option.current][1], y, option.options[option.current][1], 0.6, color.black)
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
                atlas:draw("circle", 381, 257)
                atlas:draw("cross", 433, 257)
            else
                atlas:draw("cross", 381, 257)
                atlas:draw("circle", 433, 257)
            end
        end
        screen.flip()
        if (circle_to_confirm and buttons.circle) or (not circle_to_confirm and buttons.cross) then -- confirm button 
            save_options(options)
        elseif (circle_to_confirm and buttons.cross) or (not circle_to_confirm and buttons.circle) then -- cancel button
            break
        end
    end
end