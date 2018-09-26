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
 * Optional `facedir = x` argument will apply rotation to the explosion if applicable.
### Responses
* `{type = "launched", target = <vector>}`
### Errors
* `{type = "error", error = "ammo", target = <vector>}`
* `{type = "error", error = "power", target = <vector>}`
* `{type = "error", error = "distance", target = <vector>}`
