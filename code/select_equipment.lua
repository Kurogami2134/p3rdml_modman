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
    names = {}
    count = 0
    sets = ini.read(data_dir.."/EQUIPMENT_LIST/SET.ini", "setsfb", "")
    for set in string.gmatch(sets, "([^,]+)") do
        table.insert(names, set)
        count += 1
    end
    sets = ini.read(data_dir.."/EQUIPMENT_LIST/SET.ini", "setsfg", "")
    for set in string.gmatch(sets, "([^,]+)") do
        table.insert(names, set)
        count += 1
    end
    sets = ini.read(data_dir.."/EQUIPMENT_LIST/SET.ini", "setsf", "")
    for set in string.gmatch(sets, "([^,]+)") do
        table.insert(names, set)
        count += 1
    end
    sets = ini.read(data_dir.."/EQUIPMENT_LIST/SET.ini", "setsmb", "")
    for set in string.gmatch(sets, "([^,]+)") do
        table.insert(names, set)
        count += 1
    end
    sets = ini.read(data_dir.."/EQUIPMENT_LIST/SET.ini", "setsmg", "")
    for set in string.gmatch(sets, "([^,]+)") do
        table.insert(names, set)
        count += 1
    end
    sets = ini.read(data_dir.."/EQUIPMENT_LIST/SET.ini", "setsm", "")
    for set in string.gmatch(sets, "([^,]+)") do
        table.insert(names, set)
        count += 1
    end
    return names, count
end

function select_replace (equip_type) --> nil
    local parts, part_names, part_count = load_equipment(equip_type)

    index_s, y_s = 1, 17

    while true do
    buttons.read()

    screen.print(35, 5, "Parts List", 0.6)
    max = part_count < 15+index_s and part_count or 15+index_s
    y_s = 22
    screen.print(25, y_s, ">", 0.6)
    screen.print(400, 5, index_s.."/"..part_count, 0.6)
    for i=index_s, max do
        screen.print(35, y_s, part_names[i], 0.6)
        y_s = y_s + 12
    end

    screen.print(105, 240, "O To exit", 0.6)
    screen.print(25, 240, "X To Select", 0.6)

    if buttons.down then
        index_s += 1
    elseif buttons.up then
        index_s -= 1
    elseif buttons.right then
        index_s = math.min(part_count, index_s+10)
    elseif buttons.left then
        index_s = math.max(1, index_s-10)
    end

    if index_s < 1 then
        index_s = part_count
    end

    if index_s > part_count then
        index_s = 1
    end

    if buttons.cross then
        return parts[index_s]
    elseif buttons.circle then
        return nil
    end

    screen.flip()
    end
end

function load_cat_set (name) --> str
    return ini.read(data_dir.."/EQUIPMENT_LIST/CATSET.ini", name, "")
end

function load_cat_set_from_id (id) --> str
    local names, count = load_cat_set_list()
    return load_cat_set(names[id+1])
end

function load_set_from_id (id) --> str
    local names, count = load_set_list()
    return load_set(names[id+1])
end

function load_set (name) --> str
    return ini.read(data_dir.."/EQUIPMENT_LIST/SET.ini", name, "")
end

function select_set (cat) --> nil
    local set_names, set_count
    if cat then
        set_names, set_count = load_cat_set_list()
    else
        set_names, set_count = load_set_list()
    end

    index_s, y_s = 1, 17

    while true do
    buttons.read()

    screen.print(35, 5, "Set List", 0.6)
    local max = set_count < 15+index_s and set_count or 15+index_s
    y_s = 22
    screen.print(25, y_s, ">", 0.6)
    screen.print(400, 5, index_s.."/"..set_count, 0.6)
    for i=index_s, max do
        screen.print(35, y_s, set_names[i], 0.6)
        y_s = y_s + 12
    end

    screen.print(105, 240, "O To exit", 0.6)
    screen.print(25, 240, "X To Select", 0.6)

    if buttons.down then
        index_s += 1
    elseif buttons.up then
        index_s -= 1
    elseif buttons.right then
        index_s = math.min(count, index_s+10)
    elseif buttons.left then
        index_s = math.max(1, index_s-10)
    end

    if index_s < 1 then
        index_s, y_s = set_count, set_count*12+22
    end

    if index_s > set_count then
        index_s= 1
    end

    if buttons.cross and cat then
        return load_cat_set(set_names[index_s])
    elseif buttons.cross then
        return load_set(set_names[index_s])
    elseif buttons.circle then
        return nil
    end

    screen.flip()
    end
end