BOX_CORNER_X = 94
BOX_CORNER_Y = 50

if not msg_box_tex then msg_box_tex=image.load("assets/dialog_box.png") end

function msg_box (line1, line1_x, line1_y, line2, line2_x, line2_y, line3, line3_x, line3_y) --> nil
    msg_box_tex:blit(BOX_CORNER_X, BOX_CORNER_Y)

    if line1 then
        screen.print(BOX_CORNER_X+line1_x, BOX_CORNER_Y+line1_y, line1)
    end

    if line2 then
        screen.print(BOX_CORNER_X+line2_x, BOX_CORNER_Y+line2_y, line2)
    end

    if line3 then
        screen.print(BOX_CORNER_X+line3_x, BOX_CORNER_Y+line3_y, line1)
    end

    screen.flip()

    while true do
        buttons.read()
        if buttons.circle then
            break
        end
    end
end
