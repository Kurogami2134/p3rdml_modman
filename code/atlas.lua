atlas = {
    enabled_icon = {
        x = 0,
        y = 0,
        w = 6,
        h = 7
    },
    sort_desc = {
        x = 0,
        y = 8,
        w = 16,
        h = 16
    },
    sort_asc = {
        x = 0,
        y = 25,
        w = 16,
        h = 16
    },
    has_audio = {
        x = 0,
        y = 42,
        w = 16,
        h = 16
    },
    has_animations = {
        x = 17,
        y = 0,
        w = 16,
        h = 16
    }
}


function ld (atlas, path)
    atlas["image"] = mage.load(path)
end

function dr (atlas, tex_name, x, y)
    atlas.image:blit(x, y, atlas[tex_name]["x"], atlas[tex_name]["y"], atlas[tex_name]["w"], atlas[tex_name]["h"])
end

atlas.draw = dr
atlas.load = ld
