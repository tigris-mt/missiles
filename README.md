# Missiles
Blow up the world from a distance.

## Dependencies
* [tigris-base](https://github.com/tigris-mt/tigris_base)
* [morebombs](https://github.com/tigris-mt/morebombs)

### Optional (Long range launchers)
* [technic](https://github.com/minetest-mods/technic)
* [digilines](https://github.com/minetest-mods/digilines)

## Launcher API

### Actions
* `{type = "launch", target = <vector>}`
  * Optional `direction = "+x"` (or `+y`, `-z`, etc.) argument will apply drill rotation towards the specified coordinate if applicable.
  * Optional `mode = x` where x can be `normal`, `short`, or `long` to control the missile path.
* `{type = "getinfo"}`
### Responses
* `{type = "launched", target = <vector>}`
* `{type = "info", cooldown = 4.483, ammo = {name = "tnt:tnt_missile", count = 12}, powered = true}`
### Errors
* `{type = "error", error = "protocol"}`
* `{type = "error", error = "ammo", target = <vector>}`
 * Appears when there is either no tower or no missiles in the tower.
* `{type = "error", error = "power", target = <vector>}`
* `{type = "error", error = "distance", target = <vector>}`
* `{type = "error", error = "cooldown", target = <vector>}`
