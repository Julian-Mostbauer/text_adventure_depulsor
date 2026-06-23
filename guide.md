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
| 20 | `dig.` | hear a faint rattling sound from deeper in the sand |
| 21 | `dig.` | reveals the ancient_component |
| 22 | `take(ancient_component).` | get component |
| 23 | `n.` | trade_road |
| 24 | `n.` | main_street |
| 25 | `w.` | magic_shop |
| 26 | `talk(shopkeeper).` | get the access_key |
| 27 | `e.` | main_street |
| 28 | `s.` | trade_road |
| 29 | `s.` | deep_desert (water 4→3) |
| 30 | `s.` | collector_exterior (water 3→2) |
| 31 | `in.` | hatch opens (have key); interior — survive because lit |
| 32 | `in.` | control_room |
| 33 | `deactivate.` | **YOU FREED DUSTFALL** — true ending |

One-liner to replay non-interactively:

```sh
swipl -q -g "start, n, w, buy(oil), e, n, refill, w, talk(twins), s, \
take(lantern), talk(bird_person), fill(lantern), light(lantern), n, e, s, s, s, \
dig, dig, take(ancient_component), n, n, w, talk(shopkeeper), e, s, s, s, in, in, \
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
start. s. dig. dig. take(ancient_component). n. n. w. talk(shopkeeper).
e. s. s. s. in.
```
The `in.` into the unlit interior → "It is pitch black..." → game over.

**Failure — last stand.** Make a stand instead of going in:
```prolog
start. s. s. fight.
```
→ "...gleichgültige Grollen des Monsters, das dein Leben einfach im Vorbeigehen zerquetschen." → game over.

**Failure — forced fight (time limit).** Take 70 actions without deactivating the machine or obtaining the access key:
```prolog
?- forall(between(1, 35, _), (n, s)).
```
→ Warnings at 50 and 60 steps. On the 70th step → "=== DIE ZEIT IST ABGELAUFEN ===" → forced fight with the colossus and death → game over.

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

- [ ] **Limited resource** — water drains in desert (steps 19, 29, 30); 0 → death
- [ ] **Incomplete object** — lantern needs oil → `fill` → `light` (steps 4, 13, 14)
- [ ] **Hidden object** — `dig` twice to find component (steps 20, 21)
- [ ] **Locked door** — hatch needs access_key (steps 26, 31)
- [ ] **Time limit** — 70-step limit triggers warnings (at 50 and 60 steps) and forced fight ending (at 70 steps) unless access_key is obtained
- [ ] **start/0** — shows command overview
- [ ] **inventory/0** — lists holdings
- [ ] Four endings reachable (true / last stand / death / forced fight)

## Reset

State is dynamic (assert/retract). To start fresh, just reconsult:
```prolog
?- [game].
?- start.
```
