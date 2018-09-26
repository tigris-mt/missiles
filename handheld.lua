minetest.register_craftitem("missiles:handheld", {
    description = "Handheld Launcher",
    inventory_image = "missiles_handheld.png",
})

minetest.register_craft{
    output = "missiles:handheld",
    recipe = {
        {"default:steel_ingot", "", "default:steel_ingot"},
        {"default:steel_ingot", "", "default:steel_ingot"},
        {"default:steel_ingot", "default:mese_crystal", "default:steel_ingot"},
    },
}

missiles.register_hook(function(name, def)
    local mn = name .. "_handheld"
    minetest.register_tool(":" .. mn, {
        description = def.description .. " Handheld Launcher",
        inventory_image = def.image .. "^missiles_handheld.png",

        on_use = function(itemstack, user)
            local o = tigris.create_projectile(name .. "_projectile", {
                pos = vector.add(user:getpos(), vector.new(0, user:get_properties().eye_height or 1.625, 0)),
                velocity = vector.multiply(user:get_look_dir(), 20),
                gravity = 1,
                owner = user:get_player_name(),
                owner_object = user,
            })
            if o then
                o:get_luaentity()._timeout_override = 30
            end
            return ItemStack("missiles:handheld")
        end,
    })

    minetest.register_craft{
        output = mn,
        type = "shapeless",
        recipe = {"missiles:handheld", name},
    }
end)
