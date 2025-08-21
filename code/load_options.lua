-- defaults

circle_to_confirm = false
default_game = 1

function load_options () --> nil
    circle_to_confirm = "true" == ini.read("user/options.ini", "circle_to_confirm", "false")
    default_game = ("p3rd" == ini.read("user/options.ini", "default_game", "false")) and 1 or 2
end

if files.exists("user/options.ini") then
    load_options()
else
    options_screen()
    load_options()
end
