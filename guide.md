# Depulsor Desolatio — Playtest Guide

Internal walkthrough for testing. **Contains full spoilers.** For the
spoiler-free player handout see `design.md`.

## Run It

```sh
swipl game.pl
```

Then at the `?- ` prompt:

```prolog
start.
```

End every command with a `.`. Quit with `halt.`.

## The Map

```
              old_stable
                  | n/s
              residential ---e/w--- water_tower
                                       | n/s
  magic_shop ---e/w--- main_street ---e/w--- sheriff_office
                            | n/s
                       trade_road   [START]
                            | n/s
                       deep_desert
                            | n/s
                       collector_exterior
                            | in/out
                       collector_interior
                            | in/out
                       control_room
```

Desert rooms (drain 1 water on entry): `deep_desert`, `collector_exterior`.
Dark rooms (need a lit lantern or you die): `collector_interior`, `control_room`.
You start with **water = 3**.

## Winning Walkthrough (true ending)

Goal: get a **lit lantern**, dig up the **ancient_component**, trade it to the
shopkeeper for the **access_key**, then enter the machine and `deactivate` it.
Keep your canteen topped up before each desert crossing.

| # | Command | Result |
|---|---------|--------|
| 1 | `start.` | Intro + you are on the trade_road |
| 2 | `n.` | main_street |
| 3 | `w.` | magic_shop |
| 4 | `buy(oil).` | get oil |
| 5 | `e.` | main_street |
| 6 | `n.` | water_tower |
| 7 | `refill.` | water = 5 |
| 8 | `w.` | residential |
| 9 | `talk(twins).` | hint: dig in the deep desert |
| 10 | `s.` | old_stable |
| 11 | `take(lantern).` | get lantern |
| 12 | `talk(bird_person).` | hint: it's no animal; bring light |
| 13 | `fill(lantern).` | oil consumed, lantern ready |
| 14 | `light(lantern).` | lantern lit |
| 15 | `n.` | residential |
| 16 | `e.` | water_tower |
| 17 | `s.` | main_street |
| 18 | `s.` | trade_road |
| 19 | `s.` | deep_desert (water 5→4) |
| 20 | `dig.` | reveals the ancient_component |
| 21 | `take(ancient_component).` | get component |
| 22 | `n.` | trade_road |
| 23 | `n.` | main_street |
| 24 | `w.` | magic_shop |
| 25 | `talk(shopkeeper).` | get the access_key |
| 26 | `e.` | main_street |
| 27 | `s.` | trade_road |
| 28 | `s.` | deep_desert (water 4→3) |
| 29 | `s.` | collector_exterior (water 3→2) |
| 30 | `in.` | hatch opens (have key); interior — survive because lit |
| 31 | `in.` | control_room |
| 32 | `deactivate.` | **YOU FREED DUSTFALL** — true ending |

One-liner to replay non-interactively:

```sh
swipl -q -g "start, n, w, buy(oil), e, n, refill, w, talk(twins), s, \
take(lantern), talk(bird_person), fill(lantern), light(lantern), n, e, s, s, s, \
dig, take(ancient_component), n, n, w, talk(shopkeeper), e, s, s, s, in, in, \
deactivate, halt" game.pl
```

## Failure Endings to Test

**Death — dehydration.** Start (water 3), cross into the desert until it hits 0:
```prolog
start.  s.  s.  n.  s.
```
On the last `s.` water is 0 → "Your canteen is bone dry..." → game over.

**Death — darkness.** Reach the interior without a lit lantern. Get the key but
skip the lantern:
```prolog
start. s. dig. take(ancient_component). n. n. w. talk(shopkeeper).
e. s. s. s. in.
```
The `in.` into the unlit interior → "It is pitch black..." → game over.

**Failure — last stand.** Make a stand instead of going in:
```prolog
start. s. s. fight.
```
→ "Courage... was never the missing piece." → game over.

## Edge Cases / Negative Checks

| Try | Expected |
|-----|----------|
| `in.` at collector_exterior without key | "A massive iron hatch is sealed..." (blocked, no death) |
| `take(unicorn).` | "I don't see it here." |
| `w.` from a room with no west exit | "You can't go that way." |
| `light(lantern).` before owning it | "You have no lantern." |
| `fill(lantern).` with no oil | "You have nothing to fill it with. You need oil." |
| `deactivate.` without the component | "...an empty socket — something belongs here." |
| `inventory.` (or `i.`) | lists carried items, or "carrying nothing" |
| `refill.` away from water_tower | "There is no clean water to be had here." |

## Puzzle / Requirement Checklist

- [ ] **Limited resource** — water drains in desert (steps 19, 28, 29); 0 → death
- [ ] **Incomplete object** — lantern needs oil → `fill` → `light` (steps 4, 13, 14)
- [ ] **Hidden object** — `dig` reveals component (step 20)
- [ ] **Locked door** — hatch needs access_key (steps 25, 30)
- [ ] **start/0** — shows command overview
- [ ] **inventory/0** — lists holdings
- [ ] Three endings reachable (true / last stand / death)

## Reset

State is dynamic (assert/retract). To start fresh, just reconsult:
```prolog
?- [game].
?- start.
```
