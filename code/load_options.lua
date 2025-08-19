-- defaults

circle_to_confirm = false

function load_options () --> nil
    circle_to_confirm = "true" == ini.read("user/options.ini", "circle_to_confirm", "false")
end

if files.exists("user/options.ini") then
    load_options()
else
    options_screen()
    load_options()
end
