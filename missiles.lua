minetest.register_craftitem("missiles:base", {
    description = "Missile Base",
    inventory_image = "missiles_missile.png",
})

minetest.register_craft{
    output = "missiles:base",
    recipe = {
        {"default:steel_ingot", "", "default:steel_ingot"},
        {"default:steel_ingot", "", "default:steel_ingot"},
        {"default:mese_crystal", "tnt:tnt", "default:mese_crystal"},
    },
}

morebombs.register_hook(function(name, def)
    local mn = name .. "_missile"

    missiles.register(mn, {
        description = def.description .. " Missile",
        image = "missiles_missile.png^(" .. def.tiles[1] .. "^[resize:16x16)",
        action = function(pos, mdef, data)
            -- Activate payload, default orientation down.
            def.action(pos, def, (data and data.facedir) or 4)
        end,
    })

    minetest.register_craft{
        output = mn,
        type = "shapeless",
        recipe = {"missiles:base", name},
    }
end)
