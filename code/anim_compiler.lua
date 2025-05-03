json = require "code/json"

if not ANIM_TYPES then
    local file = io.open(data_dir.."/anim_types.json", "r")
    ANIM_TYPES = json.decode(file:read("*a"))
    file:close()
end

function int_to_bytes(int) --> bytes
    local bin = string.char(int & 0xFF)..string.char((int >> 8) & 0xFF)
    bin = bin..string.char((int >> 16) & 0xFF)..string.char((int >> 24) & 0xFF)
    return bin
end

WPN_TYPES = {
    GS = 0,
    SNS = 1,
    HMR = 2,
    LNC = 3,
    HBG = 4,
    LBG = 6,
    LS = 7,
    SAXE = 8,
    GL = 9,
    BOW = 10,
    DB = 11,
    HH = 12
}

function load_anim (path, mdl_id, addr) --> bytes
    local file = io.open(path, "r")
    local json_string = file:read("*a")
    file:close()

    local data = json.decode(json_string)

    local mdl_addr = #data["model"] > 0 and addr or 0
    local tex_addr = #data["texture"] > 0 and addr + 0x1C*#data["model"] or 0

    local bin = string.char(WPN_TYPES[data["type"]:upper()]).."\00"
    bin = bin..string.char(mdl_id)..string.char(#data["model"])..string.char(#data["texture"]).."\00\00\00"
    bin = bin..int_to_bytes(mdl_addr)..int_to_bytes(tex_addr).."\00\00\00\00"

    entry = bin
    bin = ""
    for _, mdl_anim in pairs(data["model"]) do
        bin = bin..string.char(ANIM_TYPES["MODEL"][mdl_anim["type"]])..string.char(mdl_anim["bone"]).."\00\03"
        for _, frame in pairs(mdl_anim["keyframes"]) do
            bin = bin..int_to_bytes(frame)
        end
    end

    for _, tex_anim in pairs(data["texture"]) do
        bin = bin..string.char(ANIM_TYPES["TEXTURE"][tex_anim["type"]])..string.char(tex_anim["bone"]).."\00\03"
        for _, frame in pairs(tex_anim["keyframes"]) do
            bin = bin..int_to_bytes(frame)
        end
    end

    return {entry, bin}
end


function build_anim_pack (anims) --> bytes
    local entries = ""
    local anim_data = ""
    for _, anim in pairs(anims) do
        anim = load_anim(anim[1], anim[2], anim_start_offset + 4 + 0x14 * #anims + #anim_data)
        entries = entries..anim[1]
        anim_data = anim_data..anim[2]
    end
    
    local file = io.open("ms0:/"..modloader_root.."/mods/spanimpack.bin", "wb")
    file:write(int_to_bytes(anim_start_offset)..int_to_bytes(#entries+4+#anim_data))
    file:write(entries.."\255\255\255\255")
    file:write(anim_data.."\255\255\255\255\0\0\0\0")
    file:close()

end
