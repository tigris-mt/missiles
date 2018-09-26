local function dot(a, b)
    return a.x * b.x + a.y * b.y + a.z * b.z
end

function missiles.launch(start, target, name, speed)
    local def = assert(missiles.missiles[name], "no such missile")

    local g = vector.new(0, -8.5, 0)
    local gsq = dot(g, g)
    local delta = vector.subtract(target, start)
    local b = speed * speed + dot(delta, g)
    local disc = b * b - gsq * dot(delta, delta)

    if disc < 0 then
        return false
    end

    local t = math.sqrt(math.sqrt(dot(delta, delta) * 4 / gsq))
    local velocity = vector.subtract(vector.divide(delta, t), vector.multiply(g, t / 2))

    local o = tigris.create_projectile(name .. "_projectile", {
        pos = start,
        velocity = velocity,
        gravity = 1,
    })
    return (o and true), o
end

minetest.register_node("missiles:test", {
    tiles = {"default_cloud.png"},
    on_rightclick = function(pos)
        local start = vector.add(pos, vector.new(0, 1, 0))
        local ok = missiles.launch(start, vector.new(0, 0, 0), "morebombs:thunderfist_missile", 100)
        minetest.chat_send_all(tostring(ok))
    end,
})
