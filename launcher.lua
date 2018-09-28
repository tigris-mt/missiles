local function dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

function missiles.launch(start, target, name, speed, mode, facedir)
    local def = assert(missiles.missiles[name], "no such missile")

    local g = vector.new(0, -8.5, 0)
    local gsq = dot(g, g)
    local delta = vector.subtract(target, start)
    local b = speed * speed + dot(delta, g)
    local disc = b * b - gsq * dot(delta, delta)

    if disc < 0 then
        return false
    end

    local modes = {
        normal = math.sqrt(math.sqrt(dot(delta, delta) * 4 / gsq)),
        short = math.sqrt((b - math.sqrt(disc)) * 2 / gsq),
        long = math.sqrt((b + math.sqrt(disc)) * 2 / gsq),
    }
    local t = modes[mode] or modes.normal

    local velocity = vector.subtract(vector.divide(delta, t), vector.multiply(g, t / 2))

    local o = tigris.create_projectile(name .. "_projectile", {
        pos = start,
        velocity = velocity,
        gravity = 1,
    })
    if o then
        o:get_luaentity()._missile_data = {
            facedir = facedir,
        }
    end
    return (o and true), o
end

minetest.register_node("missiles:launcher_tower", {
    description = "Missile Launching Tower",
    tiles = {"technic_lead_block.png^missiles_tower_top.png", "technic_lead_block.png", "technic_lead_block.png", "technic_lead_block.png", "technic_lead_block.png", "technic_lead_block.png"},
    groups = {cracky = 1, level = 2, tubedevice = 1, tubedevice_receiver = 1},
    sounds = default.node_sound_metal_defaults(),

    on_construct = function(pos)
        local meta = minetest.get_meta(pos)
        meta:get_inventory():set_size("main", 1)
        meta:set_string("formspec", "size[8,5] list[current_name;main;3.5,0;1,1] list[current_player;main;0,1;8,4] listring[context;main] listring[current_player;main]")
    end,

    can_dig = function(pos, player)
        local meta = minetest.get_meta(pos);
        local inv = meta:get_inventory()
        return inv:is_empty("main")
    end,

    allow_metadata_inventory_put = function(pos, listname, index, stack, player)
        return ((minetest.get_item_group(stack:get_name(), "missile") or 0) ~= 0 and not minetest.is_protected(pos, player:get_player_name())) and stack:get_count() or 0
    end,

    allow_metadata_inventory_take = function(pos, listname, index, stack, player)
        return (not minetest.is_protected(pos, player:get_player_name())) and stack:get_count() or 0
    end,

    tube = {
        insert_object = function(pos, node, stack, direction)
            local meta = minetest.get_meta(pos)
            local inv = meta:get_inventory()
            return inv:add_item("main",stack)
        end,
        can_insert = function(pos, node, stack, direction)
                local meta = minetest.get_meta(pos)
                local inv = meta:get_inventory()
                return inv:room_for_item("main", stack)
        end,
        input_inventory = "main",
        connect_sides = {left=1, right=1, front=1, back=1, bottom=1},
    },

    after_place_node = pipeworks.after_place,
    after_dig_node = pipeworks.after_dig,
})

minetest.register_craft{
    output = "missiles:launcher_tower",
    recipe = {
        {"technic:lead_block", "", "technic:lead_block"},
        {"technic:lead_block", "", "technic:lead_block"},
        {"technic:stainless_steel_block", "technic:control_logic_unit", "technic:stainless_steel_block"},
    },
}

local facedirs = {
    ["+x"] = 1,
    ["+y"] = 6,
    ["+z"] = 0,
    ["-x"] = 3,
    ["-y"] = 4,
    ["-z"] = 2,
}

function missiles.register_launcher(name, def)
    local names = {
        inactive = name,
        active = name .. "_active",
    }

    local class = {
        lc = def.class:lower(),
        uc = def.class:upper(),
    }

    local desc = class.uc .. " " .. def.description

    local function r(active)
        local n = active and names.active or names.inactive

        local function reply(pos, msg)
            digiline:receptor_send(pos, digiline.rules.default, minetest.get_meta(pos):get_string("channel"), msg)
        end

        local function cooldown(meta)
            return minetest.get_gametime() - meta:get_int("last")
        end

        minetest.register_node(n, {
            description = desc,
            tiles = active and def.active_tiles or def.tiles,
            drop = names.inactive,
            groups = {cracky = 1, level = 2, technic_machine = 1, ["technic_" .. class.lc] = 1,
                not_in_creative_inventory = (active and 1 or 0)},

            technic_disabled_machine_name = names.inactive,

            on_construct = function(pos)
                local meta = minetest.get_meta(pos)
                meta:set_string("formspec", "field[channel;Channel:;${channel}]")
                meta:set_int(class.uc .. "_EU_demand", def.demand)
                meta:set_string("infotext", desc .. " Unpowered")
                meta:set_int("last", 0)
            end,

            technic_run = function(pos, node)
                local meta = minetest.get_meta(pos)
                local eu_input = meta:get_int(class.uc .. "_EU_input")
                local eu_demand = meta:get_int(class.uc .. "_EU_demand")
                local powered = eu_input >= eu_demand
                if powered then
                    meta:set_string("infotext", desc .. " Powered")
                    if not active then
                        node.name = names.active
                        minetest.swap_node(pos, node)
                    end
                    meta:set_int(class.uc .. "_EU_demand", 0)
                else
                    meta:set_string("infotext", desc .. " Unpowered")
                    if active then
                        node.name = names.inactive
                        minetest.swap_node(pos, node)
                    end
                end
            end,

            on_receive_fields = function(pos, _, fields, sender)
                if not minetest.is_protected(pos, sender:get_player_name()) then
                    if fields.channel then
                        minetest.get_meta(pos):set_string("channel", fields.channel)
                    end
                end
            end,

            digiline = {
                receptor = {},
                effector = {
                    action = function(pos, node, channel, msg)
                        local meta = minetest.get_meta(pos)
                        if meta:get_string("channel") ~= channel then
                            return
                        end
                        if type(msg) ~= "table" or not msg.type then
                            return
                        end

                        local above = vector.add(pos, vector.new(0, 1, 0))
                        VoxelManip():read_from_map(above, above)
                        local tower = (minetest.get_node(above).name == "missiles:launcher_tower") and minetest.get_meta(above):get_inventory()
                        local ammo = tower and tower:get_list("main")[1]

                        if msg.type == "getinfo" then
                            reply(pos, {
                                type = "info",
                                cooldown = def.cooldown - cooldown(meta),
                                ammo = ammo and {name = ammo:get_name(), count = ammo:get_count()},
                                powered = active,
                                max_count = def.max_count,
                            })
                        elseif msg.type == "launch" then
                            if type(msg.target) ~= "table" or type(msg.target.x) ~= "number" or type(msg.target.y) ~= "number" or type(msg.target.z) ~= "number" then
                                return reply(pos, {type = "error", error = "protocol"})
                            end

                            local count = math.max(1, math.min(tonumber(msg.count) or 1, def.max_count))

                            if not active then
                                return reply(pos, {type = "error", error = "power", target = msg.target})
                            end
                            if not tower or not ammo or ammo:get_count() < count then
                                return reply(pos, {type = "error", error = "ammo", target = msg.target})
                            end
                            if cooldown(meta) < def.cooldown then
                                return reply(pos, {type = "error", error = "cooldown", target = msg.target})
                            end

                            local ok = missiles.launch(vector.add(above, vector.new(0, 1, 0)), msg.target, ammo:get_name(), def.speed, msg.mode, facedirs[msg.facedir])
                            if not ok then
                                return reply(pos, {type = "error", error = "distance", target = msg.target})
                            end

                            local remaining = count - 1
                            for i = remaining,1,-1 do
                                minetest.after(i * 0.25, function()
                                    missiles.launch(vector.add(above, vector.new(0, 1, 0)), msg.target, ammo:get_name(), def.speed, msg.mode, facedirs[msg.facedir])
                                end)
                            end

                            tower:remove_item("main", ItemStack(ammo:get_name() .. " " .. count))
                            meta:set_int(class.uc .. "_EU_demand", def.demand)
                            reply(pos, {type = "launched", target = msg.target})
                            meta:set_int("last", minetest.get_gametime())
                        end
                    end,
                },
            },
        })

        technic.register_machine(class.uc, n, technic.receiver)
    end

    r(true)
    r(false)
end

missiles.register_launcher("missiles:simple_launcher", {
    description = "Simple Missile Launcher",
    tiles = {"missiles_simple_launcher.png"},
    active_tiles = {"missiles_simple_launcher_active.png"},

    speed = 30,
    demand = 90 * 1000,
    cooldown = 20,
    class = "mv",
    max_count = 1,
})

minetest.register_craft{
    output = "missiles:simple_launcher",
    recipe = {
        {"technic:blast_resistant_concrete", "technic:blast_resistant_concrete", "technic:blast_resistant_concrete"},
        {"default:steelblock", "technic:machine_casing", "default:steelblock"},
        {"technic:green_energy_crystal", "technic:mv_transformer", "technic:control_logic_unit"},
    },
}

missiles.register_launcher("missiles:reinforced_launcher", {
    description = "Reinforced Missile Launcher",
    tiles = {"missiles_simple_launcher.png^missiles_reinforced.png"},
    active_tiles = {"missiles_simple_launcher_active.png^missiles_reinforced.png"},

    speed = 55,
    demand = 200 * 1000,
    cooldown = 35,
    class = "hv",
    max_count = 1,
})

minetest.register_craft{
    output = "missiles:reinforced_launcher",
    recipe = {
        {"technic:blast_resistant_concrete", "technic:brass_block", "technic:blast_resistant_concrete"},
        {"technic:stainless_steel_block", "missiles:simple_launcher", "technic:stainless_steel_block"},
        {"technic:green_energy_crystal", "technic:hv_transformer", "technic:green_energy_crystal"},
    },
}

missiles.register_launcher("missiles:bulk_launcher", {
    description = "Bulk Missile Launcher",
    tiles = {"missiles_simple_launcher.png^missiles_bulk.png"},
    active_tiles = {"missiles_simple_launcher_active.png^missiles_bulk.png"},

    speed = 55,
    demand = 700 * 1000,
    cooldown = 40,
    class = "hv",
    max_count = 5,
})

minetest.register_craft{
    output = "missiles:bulk_launcher",
    recipe = {
        {"technic:control_logic_unit", "missiles:reinforced_launcher", "technic:control_logic_unit"},
        {"technic:hv_transformer", "technic:hv_transformer", "technic:hv_transformer"},
    },
}
