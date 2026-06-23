# Depulsor Desolatio

*A Prolog text adventure*

## The Idea

A lone wanderer rides into **Dustfall**, a dying frontier town at the end of a
forgotten trade road, ringed by endless dunes. For as long as anyone can
remember, a gigantic camel-like monster — **The Collector** — has emerged from
the desert each month to demand tribute: food, livestock, tools. Refuse, and it
destroys. The town has paid for centuries.

Now the storehouses are nearly empty. Pay again and people starve; refuse and
the monster comes. As the outsider, you must talk to the townsfolk, scavenge
what the desert hides, and decide what to do before the next tribute falls due.

There is more than one way for your story to end. Choose carefully — courage
alone may not be enough, time is running out, and the desert is not forgiving.

## How To Play

Type commands in standard Prolog syntax, each ending with a full stop (`.`).
Start with `start.` for the intro and the full command list.

| Command | What it does |
|---|---|
| `n.` `s.` `e.` `w.` | Move in a direction |
| `in.` `out.` | Enter or leave a structure |
| `look.` | Look around again |
| `take(X).` `drop(X).` | Pick up / put down an object |
| `inventory.` (or `i.`) | List what you are carrying |
| `talk(Who).` | Talk to a townsperson |
| `buy(X).` | Buy something at the shop |
| `fill(lantern).` `light(lantern).` | Prepare your light source |
| `dig.` | Dig at your feet |
| `refill.` | Refill your canteen at the water tower |
| `deactivate.` / `fight.` | ...when the moment comes |
| `instructions.` | Show the command list again |
| `halt.` | Quit |

## Mechanics & Puzzles

The game leans on the things Prolog does best — facts and rules, recursion over
lists, cuts, and a knowledge base rewritten at runtime with `assert`/`retract`.
It includes five core mechanics and adventure-puzzle types:

- **Limited resource** — water. Crossing the desert drains your canteen (tracked
  with arithmetic); run dry out there and you won't make it back. Refill in town.
- **Incomplete object** — a lantern is useless until you give it what it lacks
  and bring it to life. You'll want light before you go anywhere dark.
- **Hidden object** — the desert buries its secrets. Search the right spot and
  be persistent (you must dig once to hear a rattle, then dig again to find the component).
- **Locked door** — one way forward is sealed tight. Earn the means to open it
  by gaining the right person's trust.
- **Time limit** — every action takes time (steps). You must resolve the mystery (by obtaining the access key) before 70 steps, or Depulsor will arrive in town, forcing a hopeless final battle.

Talking to the townsfolk is how you learn what to do next — each has a hint, and
one holds the key to everything.

## Map of Dustfall

```
              Old Stable
                  |
              Residential ------- Water Tower
                                       |
    Magic Shop ------- Main Street ------- Sheriff's Office
                            |
                       Trade Road  [ you start here ]
                            |
                       Deep Desert
                            |
                       ( the dunes... )
```

Make it across the dunes, and find out what The Collector really is.
