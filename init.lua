missiles = {
    missiles = {},
}

function missiles.register(name, def)
    local p = name .. "_projectile"
    tigris.register_projectile(":" .. p, {
        texture = "missiles_missile.png",
        timeout = 600,
        load_map = true,
        draw_distance = 3000,
        on_any_hit = function(self)
            if self._last_air then
                def.action(self._last_air, def, self._missile_data)
            end
            return true
        end,
        on_timeout = function(self)
            if self._last_air then
                def.action(self._last_air, def, self._missile_data)
            end
            return true
        end,
    })
    minetest.register_craftitem(":" .. name, {
        description = def.description,
        inventory_image = def.image,
        groups = {missile = 1},
    })

    missiles.missiles[name] = def
    missiles.hook(name, def)
end

function missiles.hook(name, def)
    -- Dummy hook function.
end

function missiles.register_hook(f)
    local old = missiles.hook
    missiles.hook = function(...)
        f(...)
        old(...)
    end
end

tigris.include("handheld.lua")

if minetest.get_modpath("technic") and minetest.get_modpath("digilines") then
    tigris.include("launcher.lua")
end

tigris.include("missiles.lua")
