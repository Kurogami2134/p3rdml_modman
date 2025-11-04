BOX_CORNER_X = 94
BOX_CENTER_X = 240
BOX_CORNER_Y = 50

if not msg_box_tex then msg_box_tex=image.load("assets/dialog_box.png") end

function split(str, sep) --> table[string]
    local parts = string.gmatch(str, "([^"..sep.."]+)")
    local res = {}
    for part in parts do
        table.insert(res, part)
    end
    return res
end

function sp_print(line, x, y, size) --> nil
    if x == nil then x = 0 end
    if y == nil then y = 0 end
    if size == nil then size = 1 end
    local parts = split(line, "::")
    local i
    for i=1,#parts do
        if i%2 == 1 then
            screen.print(x, y, parts[i], size)
            x += screen.textwidth(parts[i], size)
        else
            atlas:draw(parts[i], x, y)
            x += atlas[parts[i]].w
        end
    end
end

function sp_text_width(line, size) --> int
    if size == nil then size = 1 end
    local parts = split(line, "::")
    local width = 0
    local i
    for i=1,#parts do
        if i%2 == 1 then
            width += screen.textwidth(parts[i], size)
        else
            width += atlas[parts[i]].w
        end
    end
    return width
end

function msg_box (line1, line1_y, line2, line2_y, line3, line3_y) --> nil
    msg_box_tex:blit(BOX_CORNER_X, BOX_CORNER_Y)

    if line1 then
        sp_print(line1, BOX_CENTER_X-(sp_text_width(line1)/2), BOX_CORNER_Y+line1_y)
    end

    if line2 then
        sp_print(line2, BOX_CENTER_X-(sp_text_width(line2)/2), BOX_CORNER_Y+line2_y)
    end

    if line3 then
        sp_print(line2, BOX_CENTER_X-(sp_text_width(line3)/2), BOX_CORNER_Y+line3_y)
    end

    sp_print(TEXT.press_circle, BOX_CENTER_X-(sp_text_width(TEXT.press_circle, .6)/2), 197, .6)

    screen.flip()

    while true do
        buttons.read()
        if buttons.circle then
            break
        end
    end
end

function confirm_msg (line1, line1_y, line2, line2_y, line3, line3_y) --> nil
    msg_box_tex:blit(BOX_CORNER_X, BOX_CORNER_Y)

    if line1 then
        sp_print(line1, BOX_CENTER_X-(sp_text_width(line1)/2), BOX_CORNER_Y+line1_y)
    end

    if line2 then
        sp_print(line2, BOX_CENTER_X-(sp_text_width(line2)/2), BOX_CORNER_Y+line2_y)
    end

    if line3 then
        sp_print(line2, BOX_CENTER_X-(sp_text_width(line3)/2), BOX_CORNER_Y+line3_y)
    end

    if circle_to_confirm then
        sp_print(" ::circle::"..TEXT.yes, 115, 180, .6)
        sp_print(" ::cross::"..TEXT.no, 115, 196, .6)
    else
        sp_print(" ::cross::"..TEXT.yes, 115, 180, .6)
        sp_print(" ::circle::"..TEXT.no, 115, 196, .6)
    end

    screen.flip()

    while true do
        buttons.read()
        if (circle_to_confirm and buttons.cross) or (not circle_to_confirm and buttons.circle) then -- cancel button
            return false
        elseif (circle_to_confirm and buttons.circle) or (not circle_to_confirm and buttons.cross) then -- confirm button
            return true
        end
    end
end
