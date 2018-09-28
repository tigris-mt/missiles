minetest.register_craftitem("missiles:handheld", {
    description = "Handheld Launcher (combine with missile)",
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

minetest.register_craftitem("missiles:handheld_auto", {
    description = "Automatic Handheld Launcher (combine with missile)",
    inventory_image = "missiles_handheld_auto.png",
})

minetest.register_craft{
    output = "missiles:handheld_auto",
    recipe = {
        {"default:bronze_ingot", "missiles:handheld", "default:bronze_ingot"},
        {"", "default:obsidian_shard", ""},
    },
}

missiles.register_hook(function(name, def)
    local function r(auto)
        local mn = name .. "_handheld" .. (auto and "_auto" or "")
        local base = "missiles:handheld" .. (auto and "_auto" or "")
        minetest.register_tool(":" .. mn, {
            description = def.description .. (auto and " Automatic" or "") .. " Handheld Launcher",
            inventory_image = def.image .. "^missiles_handheld" .. (auto and "_auto" or "") .. ".png",
            groups = {not_in_creative_inventory = 1},

            on_use = function(itemstack, user)
                -- If auto, then check cooldown.
                if auto then
                    if minetest.get_gametime() - itemstack:get_meta():get_int("time") < 3 then
                        return itemstack
                    end
                end

                -- Fire missile.
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

                -- If auto, try to remove a missile from the inventory and reload.
                if auto then
                    if user:get_inventory():remove_item("main", ItemStack(name)):get_count() > 0 then
                        -- Reset for cooldown.
                        itemstack:get_meta():set_int("time", minetest.get_gametime())
                        return itemstack
                    else
                        return ItemStack(base)
                    end
                else
                    return ItemStack(base)
                end
            end,
        })

        -- Creation craft.
        minetest.register_craft{
            output = mn,
            type = "shapeless",
            recipe = {base, name},
        }

        -- Unloading craft.
        minetest.register_craft{
            output = name,
            type = "shapeless",
            recipe = {mn},
            replacements = {{mn, base}},
        }
    end

    r(true)
    r(false)
end)
