# Optimal playthrough
skips many hints and NPCs, **full spoilers**


## Goals

Get lantern (old stable)
Get oil (magic shop)
Light lantern

Dig out ancient component -> bring to magic shop

Get to control room

### Optimal Ordering

- Ancient Component first (least backtracking that way)
- Then lantern at old stable (here it doesn't matter if we go magic first i think)
- Magic shop (talk to shopkeeper, buy oil)
- Go to control room, light lantern before collector_interior


## Command Sequence

| # | Command | Result |
|---|---------|--------|
| 1 | s. | deep_desert (water: 2) |
| 2 | dig. | First dig, hear rattle |
| 3 | dig. | Second dig, uncover ancient component |
| 4 | take(ancient_component). | Take the component |
| 5 | n. | trade_road |
| 6 | n. | main_street |
| 7 | n. | water_tower |
| 8 | w. | residential |
| 9 | s. | old_stable |
| 10 | take(lantern). | Take the lantern at the stable |
| 11 | n. | residential |
| 12 | e. | water_tower |
| 13 | s. | main_street |
| 14 | w. | magic_shop |
| 15 | talk(shopkeeper) | Get access key |
| 16 | buy(oil) | Buy oil for the lantern |
| 17 | e. | main_street |
| 18 | s. | trade_road |
| 19 | s. | deep_desert (water: 1) |
| 20 | s. | collector_exterior (water: 0) |
| 21 | fill(lantern). | Fill lantern with oil you bought |
| 22 | light(lantern). | Light the lantern |
| 23 | in. | collector_interior |
| 24 | in. | control_room |
| 25 | deactivate. | True ending; ez win |
