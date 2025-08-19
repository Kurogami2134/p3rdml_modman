EQUIPMENT_NAMES = {
    GS = "Great Sword",
    SNS = "Sword and Shield",
    HMR = "Hammer",
    LNC = "Lance",
    LS = "Long Sword",
    SAXE = "Switch Axe",
    HH = "Hunting Horn",
    DB = "Dual Blades",
    GL = "Gunlance",
    HBG = "Heavy Bowgun",
    LBG = "Light Bowgun",
    BOW = "Bow",
    CATHELM = "Felyne Helm",
    CATWPN = "Felyne Weapon",
    CATPLATE = "Felyne Plate",
    ARMS = "Arms Armor",
    LEGS = "Legs Armor",
    BODY = "Chest Armor",
    WAIST = "Waist Armor",
    HEAD = "Head Armor",
}
function load_equipment (eq_type) --> table[int], table[str], int
    file_list = {}
    names = {}
    parts = ini.read(data_dir.."/EQUIPMENT_LIST/"..eq_type..".ini", "files", "")
    parts = parts..ini.read(data_dir.."/EQUIPMENT_LIST/"..eq_type..".ini", "files2", "")
    parts = parts..ini.read(data_dir.."/EQUIPMENT_LIST/"..eq_type..".ini", "files3", "")
    parts = parts..ini.read(data_dir.."/EQUIPMENT_LIST/"..eq_type..".ini", "files4", "")
    parts = parts..ini.read(data_dir.."/EQUIPMENT_LIST/"..eq_type..".ini", "files5", "")
    count = 0
    for file in string.gmatch(parts, "([^;]+)") do
        table.insert(file_list, string.sub(file, -4, -1))
        table.insert(names, string.sub(file, 1, -5))
        count += 1
    end
    return file_list, names, count
end

function load_cat_set_list() --> table[str], int
    names = {}
    count = 0
    sets = ini.read(data_dir.."/EQUIPMENT_LIST/CATSET.ini", "sets", "")
    for set in string.gmatch(sets, "([^,]+)") do
        table.insert(names, set)
        count += 1
    end
    return names, count
end

function load_set_list() --> table[str], int
    categories = {
        Female_Blademaster = {
            names = {},
            count = 0
        },
        Female_Gunner = {
            names = {},
            count = 0
        },
        Female_Generic = {
            names = {},
            count = 0
        },
        Male_Blademaster = {
            names = {},
            count = 0
        },
        Male_Gunner = {
            names = {},
            count = 0
        },
        Male_Generic = {
            names = {},
            count = 0
        }
    }
    sets = ini.read(data_dir.."/EQUIPMENT_LIST/SET.ini", "setsfb", "")
    for set in string.gmatch(sets, "([^,]+)") do
        table.insert(categories["Female_Blademaster"]["names"], set)
        categories["Female_Blademaster"]["count"] += 1
    end
    sets = ini.read(data_dir.."/EQUIPMENT_LIST/SET.ini", "setsfg", "")
    for set in string.gmatch(sets, "([^,]+)") do
        table.insert(categories["Female_Gunner"]["names"], set)
        categories["Female_Gunner"]["count"] += 1
    end
    sets = ini.read(data_dir.."/EQUIPMENT_LIST/SET.ini", "setsf", "")
    for set in string.gmatch(sets, "([^,]+)") do
        table.insert(categories["Female_Generic"]["names"], set)
        categories["Female_Generic"]["count"] += 1
    end
    sets = ini.read(data_dir.."/EQUIPMENT_LIST/SET.ini", "setsmb", "")
    for set in string.gmatch(sets, "([^,]+)") do
        table.insert(categories["Male_Blademaster"]["names"], set)
        categories["Male_Blademaster"]["count"] += 1
    end
    sets = ini.read(data_dir.."/EQUIPMENT_LIST/SET.ini", "setsmg", "")
    for set in string.gmatch(sets, "([^,]+)") do
        table.insert(categories["Male_Gunner"]["names"], set)
        categories["Male_Gunner"]["count"] += 1
    end
    sets = ini.read(data_dir.."/EQUIPMENT_LIST/SET.ini", "setsm", "")
    for set in string.gmatch(sets, "([^,]+)") do
        table.insert(categories["Male_Generic"]["names"], set)
        categories["Male_Generic"]["count"] += 1
    end
    return categories
end

function load_cat_set (name) --> str
    return ini.read(data_dir.."/EQUIPMENT_LIST/CATSET.ini", name, "")
end

function load_cat_set_from_id (id) --> str
    local names, count = load_cat_set_list()
    return load_cat_set(names[id+1])
end

function load_set (name) --> str
    return ini.read(data_dir.."/EQUIPMENT_LIST/SET.ini", name, "")
end

function select_replace (equip_type) --> nil
    local set_names, set_count, categories, cat_names, cat_idx, parts
    if equip_type == "SET" then
        categories = load_set_list()
        cat_names = {"Female_Blademaster", "Female_Gunner", "Female_Generic", "Male_Blademaster", "Male_Gunner", "Male_Generic"}
    elseif equip_type == "CATSET" then
        set_names, set_count = load_cat_set_list()
        cat_names = {"Cat"}
        categories = {
            Cat = {
                names = set_names,
                count = set_count
            }
        }
    else
        parts, set_names, set_count = load_equipment(equip_type)
        cat_names = {EQUIPMENT_NAMES[equip_type]}
        categories = {}
        categories[EQUIPMENT_NAMES[equip_type]] = {
            names = set_names,
            count = set_count
        }
    end

    cat_idx = 1
    set_names = categories[cat_names[cat_idx]]["names"]
    set_count = categories[cat_names[cat_idx]]["count"]

    local index_s, y_s = 1, 17

    while true do
    buttons.read()

    if game_sel_bg then game_sel_bg:blit(0,0) end
    if atlas.image then
        if circle_to_confirm then
            atlas:draw("circle", 381, 257)
            atlas:draw("cross", 433, 257)
        else
            atlas:draw("cross", 381, 257)
            atlas:draw("circle", 433, 257)
        end
    end

    if #cat_names > 1 and atlas.image then
        atlas:draw("l_button", 100, 12)
        atlas:draw("r_button", 362, 12)
    end
    
    screen.print(240-6*#cat_names[cat_idx], 12, cat_names[cat_idx]:gsub("_", " "), 1, color.black)
    local max = set_count < 15+index_s and set_count or 15+index_s
    y_s = 40
    screen.print(25, y_s, ">", 0.6, color.black)
    screen.print(12, 257, index_s.."/"..set_count, 0.6, color.white)
    for i=index_s, max do
        screen.print(35, y_s, set_names[i], 0.6, color.black)
        y_s = y_s + 12
    end

    if buttons.down then
        index_s += 1
    elseif buttons.up then
        index_s -= 1
    elseif buttons.right then
        index_s = math.min(set_count, index_s+10)
    elseif buttons.left then
        index_s = math.max(1, index_s-10)
    elseif buttons.r then
        cat_idx += 1
    elseif buttons.l then
        cat_idx -= 1
    end
    
    if cat_idx < 1 then
        cat_idx = #cat_names
    elseif cat_idx > #cat_names then
        cat_idx = 1
    end

    if buttons.l or buttons.r then
        set_names = categories[cat_names[cat_idx]]["names"]
        set_count = categories[cat_names[cat_idx]]["count"]
        index_s = math.min(set_count, index_s)
    end

    if index_s < 1 then
        index_s, y_s = set_count, set_count*12+22
    end

    if index_s > set_count then
        index_s= 1
    end

    if (circle_to_confirm and buttons.circle) or (not circle_to_confirm and buttons.cross) then -- confirm button
        if type == "SET" then
            return load_set(set_names[index_s]), set_names[index_s] - 1
        elseif type == "CATSET" then
            return load_cat_set(set_names[index_s]), index_s - 1
        else
            return parts[index_s], index_s - 1
        end
    elseif (circle_to_confirm and buttons.cross) or (not circle_to_confirm and buttons.circle) then -- cancel button
        return nil
    end

    screen.flip()
    end
end