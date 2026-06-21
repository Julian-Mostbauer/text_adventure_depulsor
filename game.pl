/* Depulsor Desolatio - a text adventure set in the desert town of Dustfall.
   By <your name goes here>.

   Adapted from the Matuszek/UPenn adventure template.

   Goal (no spoilers): survive Dustfall, learn the truth about the
   monster called The Collector, and decide the town's fate.

   Type   start.   to begin and to see the list of commands. */


/* ----------------------------------------------------------------- */
/* Dynamic facts: the knowledge base is modified at runtime with      */
/* assert/retract as the player moves, takes things and solves puzzles.*/
/* ----------------------------------------------------------------- */

:- dynamic i_am_at/1, at/2, holding/1, water_level/1, lit/1, flag/1.

:- retractall(i_am_at(_)),
   retractall(at(_, _)),
   retractall(holding(_)),
   retractall(water_level(_)),
   retractall(lit(_)),
   retractall(flag(_)).


/* ----------------------------------------------------------------- */
/* Initial world state.                                               */
/* ----------------------------------------------------------------- */

i_am_at(trade_road).

/* The player starts with a half-full canteen. Water is the game's
   limited resource (see consume_water/0 and refill/0). */
water_level(3).

/* Objects placed in the world at the start.
   - The lantern is an INCOMPLETE object: it needs oil before it works.
   - The ancient_component is a HIDDEN object, buried until you dig. */
at(lantern, old_stable).


/* ----------------------------------------------------------------- */
/* The map. path(Here, Direction, There).                            */
/* ----------------------------------------------------------------- */

path(trade_road,          n,   main_street).
path(main_street,         s,   trade_road).

path(trade_road,          s,   deep_desert).
path(deep_desert,         n,   trade_road).

path(main_street,         n,   water_tower).
path(water_tower,         s,   main_street).

path(main_street,         e,   sheriff_office).
path(sheriff_office,      w,   main_street).

path(main_street,         w,   magic_shop).
path(magic_shop,          e,   main_street).

path(water_tower,         w,   residential).
path(residential,         e,   water_tower).

path(residential,         s,   old_stable).
path(old_stable,          n,   residential).

path(deep_desert,         s,   collector_exterior).
path(collector_exterior,  n,   deep_desert).

/* The hatch into the machine. The path exists, but entry is locked
   until you carry the access_key (see try_enter/2 - LOCKED DOOR puzzle). */
path(collector_exterior,  in,  collector_interior).
path(collector_interior,  out, collector_exterior).

path(collector_interior,  in,  control_room).
path(control_room,        out, collector_interior).


/* Desert rooms drain water on entry. Dark rooms need a lit lantern. */
desert(deep_desert).
desert(collector_exterior).

dark(collector_interior).
dark(control_room).


/* ----------------------------------------------------------------- */
/* Picking up and dropping objects (from the template).              */
/* ----------------------------------------------------------------- */

take(X) :-
        holding(X),
        write('Das hast du schon aufgehoben!'),
        !, nl.

take(X) :-
        i_am_at(Place),
        at(X, Place),
        retract(at(X, Place)),
        assert(holding(X)),
        write('OK.'),
        !, nl.

take(_) :-
        write('Das gibt es hier nicht.'),
        nl.


drop(X) :-
        holding(X),
        i_am_at(Place),
        retract(holding(X)),
        assert(at(X, Place)),
        write('OK.'),
        !, nl.

drop(_) :-
        write('Das Item hast du nicht!'),
        nl.


/* ----------------------------------------------------------------- */
/* Inventory (REQUIRED by the assignment).                           */
/* Uses findall to build a LIST and prints it with RECURSION.        */
/* ----------------------------------------------------------------- */

inventory :-
        findall(X, holding(X), Things),
        ( Things == []
        -> write('Dein Inventar ist leer'), nl
        ;  write('Dein Inventar beinhaltet:'), nl, list_things(Things) ).

list_things([]).
list_things([Thing | Rest]) :-
        write('  - '), write(Thing), nl,
        list_things(Rest).

/* Short alias. */
i :- inventory.

/* have_all(+List) succeeds if you are holding every item in the list.
   Recursive check over a list, reused by the win condition. */
have_all([]).
have_all([Item | Rest]) :-
        holding(Item),
        have_all(Rest).


/* ----------------------------------------------------------------- */
/* Movement.                                                         */
/* ----------------------------------------------------------------- */

n :- go(n).
s :- go(s).
e :- go(e).
w :- go(w).
in :- go(in).
out :- go(out).

go(Direction) :-
        i_am_at(Here),
        path(Here, Direction, There),
        try_enter(Here, There),
        !.

go(_) :-
        write('In diese Richtung kannst du nicht gehen.'), nl.


/* LOCKED DOOR puzzle: the hatch into the machine needs the access_key. */
try_enter(_, collector_interior) :-
        \+ holding(access_key),
        !,
        nl,
        write('In der Flanke des Biests befindet sich eine massive, fest verschlossene Eisenluke.'), nl,
        write('Es lässt sich nicht öffnen. Du brauchst warscheinlich einen Schlüssel.'), nl.

try_enter(_, There) :-
        enter(There).


/* enter/1 handles water, darkness and the actual move. */

/* Walking into the desert with an empty canteen is fatal. */
enter(There) :-
        desert(There),
        water_level(W),
        W =< 0,
        !,
        move_to(There),
        nl,
        write('Deine Kantine ist komplett ausgetrocknet und die Sonne kocht dich well-done.'), nl,
        write('Deine Beine werden immer langsamer, bis sie endlich ausgeben. Das letzte das du siehst ist Sand, Sand und Sand.'), nl,
        die.

/* Otherwise entering the desert costs one unit of water. */
enter(There) :-
        desert(There),
        !,
        consume_water,
        move_to(There),
        dark_check(There).

enter(There) :-
        move_to(There),
        dark_check(There).


move_to(There) :-
        retract(i_am_at(_)),
        assert(i_am_at(There)),
        look.


/* Entering a dark room without a lit lantern is fatal. */
dark_check(There) :-
        dark(There),
        \+ ( holding(lantern), lit(lantern) ),
        !,
        nl,
        write('Es ist stockfinster in der Maschine. Du stolperst blind herum.'), nl,
        write('Du steigst auf etwas das leise Nachgibt, bis du plötzlich einen lauten Knall über dir hörst.'), nl,
        die.

dark_check(_).


/* ----------------------------------------------------------------- */
/* LIMITED RESOURCE puzzle: water. Arithmetic counter.               */
/* ----------------------------------------------------------------- */

consume_water :-
        retract(water_level(W)),
        W1 is W - 1,
        assert(water_level(W1)),
        report_water(W1).

report_water(W) :-
        W =< 1,
        !,
        write('(Deine Kantine ist fast leer - Du hast noch: '), write(W), write('.)'), nl.
report_water(_).

/* Refill the canteen at the town water tower. */
refill :-
        i_am_at(water_tower),
        !,
        retract(water_level(_)),
        assert(water_level(5)),
        write('Du füllst deine Kantine bis kein Tropfen mehr rein passt. (Water: 5)'), nl.
refill :-
        write('Du findest hier kein Trinkwasser.'), nl.


/* ----------------------------------------------------------------- */
/* HIDDEN OBJECT puzzle: dig in the deep desert.                     */
/* ----------------------------------------------------------------- */

dig :-
        i_am_at(deep_desert),
        \+ flag(dug),
        !,
        assert(flag(dug)),
        assert(at(ancient_component, deep_desert)),
        nl,
        write('Du gräbst dort, wo der Wind die Düne weggetragen hat.'), nl,
        write('Mit deinen Fingern fühlst du etwas metallisches: ein seltsames altes Maschinenteil,'), nl,
        write('Relikt und Maschine zugleich. Beweis, dass das Monster nie lebendig war.'), nl,
        write('Du hast einen "ancient_component" for dir.'), nl.

dig :-
        i_am_at(deep_desert),
        flag(dug),
        !,
        write('Es gibt hier nix mehr zum ausgraben'), nl.

dig :-
        write('Der Boden hier ist zu fest.'), nl.


/* ----------------------------------------------------------------- */
/* INCOMPLETE OBJECT puzzle: the lantern needs oil, then a light.    */
/* ----------------------------------------------------------------- */

/* Buy oil from the shopkeeper. */
buy(oil) :-
        i_am_at(magic_shop),
        \+ holding(oil),
        !,
        assert(holding(oil)),
        write('Der Ladenbesitzer schiebt eine Flasche Lampenöl über den'), nl,
        write('Bartresen. "Verschwende es nicht. Das war meine letzte Reserve."'), nl.
buy(oil) :-
        holding(oil),
        !,
        write('Das war mein letztes Öl. Mehr habe ich nicht!'), nl.
buy(_) :-
        i_am_at(magic_shop),
        !,
        write('Das verkaufe ich hier nicht.'), nl.
buy(_) :-
        write('Hier kann man nix kaufen.'), nl.

/* Fill the lantern with oil. */
fill(lantern) :-
        holding(lantern),
        holding(oil),
        !,
        retract(holding(oil)),
        assert(flag(lantern_filled)),
        write('Du füllst die Lampe mit Öl auf. Sie kann jetzt angezündet werden.'), nl.
fill(lantern) :-
        \+ holding(lantern),
        !,
        write('Du hast keine Lampe.'), nl.
fill(lantern) :-
        write('Du brauchst Öl um die Lampe aufzufüllen.'), nl.
fill(_) :-
        write('Das kann man nicht auffüllen.'), nl.

/* Light the (filled) lantern. */
light(lantern) :-
        lit(lantern),
        !,
        write('Die Lampe brennt schon.'), nl.
light(lantern) :-
        holding(lantern),
        flag(lantern_filled),
        !,
        assert(lit(lantern)),
        write('Die Lampe fängt an zu brennen, du kannst ihre Wärme in deinen Händen fühlen.'), nl.
light(lantern) :-
        holding(lantern),
        !,
        write('Die Lampe hat kein Öl und kann nicht angezündet werden.'), nl.
light(lantern) :-
        write('Du hast keine Lampe.'), nl.
light(_) :-
        write('Das sollte man nicht anzünden.'), nl.


/* ----------------------------------------------------------------- */
/* Talking to the townsfolk. Hints, lore, and the key to the hatch.  */
/* ----------------------------------------------------------------- */

talk(sheriff) :-
        i_am_at(sheriff_office),
        !,
        nl,
        write('The sheriff does not look up. "Another wanderer. Listen -'), nl,
        write('don''t go stirring up hope. We pay the tribute, we survive."'), nl,
        write('"Fighting The Collector is how good people die. Leave it be."'), nl.

talk(twins) :-
        i_am_at(residential),
        !,
        nl,
        write('The twin girls eye you warily. "We''re not supposed to talk'), nl,
        write('to strangers." Then one leans in: "But we heard it. Out past'), nl,
        write('the road, in the deep dunes - a clinking under the sand.'), nl,
        write('Like something buried. You should dig there."'), nl.

talk(bird_person) :-
        i_am_at(old_stable),
        !,
        nl,
        write('The bird-person folds a broken wing. "I am not of this town,'), nl,
        write('so I will say what they won''t: that thing is no animal."'), nl,
        write('"Take the old lantern here. You''ll want light where you''re going."'), nl.

/* The shopkeeper gives the access_key once you bring real proof. */
talk(shopkeeper) :-
        i_am_at(magic_shop),
        holding(ancient_component),
        \+ holding(access_key),
        !,
        assert(holding(access_key)),
        nl,
        write('The shopkeeper''s eyes lock onto the component in your hands.'), nl,
        write('"So. You found it. I was young when I last held a piece like that."'), nl,
        write('They press an old iron key into your palm. "The beast has a hatch.'), nl,
        write('This opens it. Get inside, find the core, and shut the thing down.'), nl,
        write('Finish what I could not." (You received the access_key.)'), nl.
talk(shopkeeper) :-
        i_am_at(magic_shop),
        holding(access_key),
        !,
        nl,
        write('"Why are you still here? The hatch is out past the dunes. Go."'), nl.
talk(shopkeeper) :-
        i_am_at(magic_shop),
        !,
        nl,
        write('The shopkeeper grunts. "You want the truth? The desert keeps it."'), nl,
        write('"Bring me something solid - dig out past the road - and I''ll talk."'), nl,
        write('"And buy some oil while you''re here. You''ll need a lamp."'), nl.

talk(_) :-
        write('There is no one like that to talk to here.'), nl.


/* ----------------------------------------------------------------- */
/* The endings.                                                      */
/* ----------------------------------------------------------------- */

/* TRUE ENDING: deactivate the machine from the control room. */
deactivate :-
        i_am_at(control_room),
        have_all([ancient_component]),
        !,
        nl,
        write('You seat the ancient component into the empty socket at the core.'), nl,
        write('Centuries of blind routine stutter, slow, and fall silent.'), nl,
        write('The Collector will not walk to Dustfall again.'), nl,
        nl,
        write('*** YOU FREED DUSTFALL. The tribute is over. ***'), nl,
        finish.
deactivate :-
        i_am_at(control_room),
        !,
        nl,
        write('The control core has an empty socket - something belongs here.'), nl,
        write('You need the component you dug out of the desert.'), nl.
deactivate :-
        write('There is nothing here to deactivate.'), nl.

/* FAILURE ENDING: a last stand against the machine. */
fight :-
        i_am_at(collector_exterior),
        !,
        nl,
        write('You rally the townsfolk for a last stand against The Collector.'), nl,
        write('Steel and spellfire break against its ancient hide. It does not'), nl,
        write('even slow. Courage, it turns out, was never the missing piece.'), nl,
        die.
fight :-
        write('There is nothing here to fight.'), nl.


/* ----------------------------------------------------------------- */
/* Looking around (from the template).                               */
/* ----------------------------------------------------------------- */

look :-
        i_am_at(Place),
        describe(Place),
        nl,
        notice_objects_at(Place),
        nl.

notice_objects_at(Place) :-
        at(X, Place),
        write('There is a '), write(X), write(' here.'), nl,
        fail.
notice_objects_at(_).


/* ----------------------------------------------------------------- */
/* Death and game over (from the template).                          */
/* ----------------------------------------------------------------- */

die :-
        nl,
        write('*** The story ends here. ***'), nl,
        finish.

finish :-
        nl,
        write('The game is over. Please enter the "halt." command.'),
        nl.


/* ----------------------------------------------------------------- */
/* Instructions and start.                                           */
/* ----------------------------------------------------------------- */

instructions :-
        nl,
        write('Enter commands using standard Prolog syntax (end each with a "." ).'), nl,
        write('Available commands are:'), nl,
        write('start.              -- restart / show this overview again.'), nl,
        write('n.  s.  e.  w.      -- move in that direction.'), nl,
        write('in.  out.           -- enter or leave a structure.'), nl,
        write('look.               -- look around you again.'), nl,
        write('take(Object).       -- pick up an object.'), nl,
        write('drop(Object).       -- put down an object.'), nl,
        write('inventory.   (or i.)-- list what you are carrying.'), nl,
        write('talk(Who).          -- talk to a townsperson.'), nl,
        write('buy(Object).        -- buy something (at the shop).'), nl,
        write('fill(lantern).      -- pour oil into the lantern.'), nl,
        write('light(lantern).     -- light a filled lantern.'), nl,
        write('dig.                -- dig at your feet.'), nl,
        write('refill.             -- refill your canteen (at the water tower).'), nl,
        write('deactivate.         -- shut the machine down (from its core).'), nl,
        write('fight.              -- make a stand against The Collector.'), nl,
        write('instructions.       -- see this message again.'), nl,
        write('halt.               -- quit the game.'), nl,
        nl.

start :-
        nl,
        write('     ,---.       ,---.'), nl,
        write('    ( o   )-----( o   )    ~ D E P U L S O R   D E S O L A T I O ~'), nl,
        write('     )   (       )   (       a Prolog text adventure'), nl,
        write('   __|___________|___|__'), nl,
        write('  (      the dunes       )'), nl,
        write('   ~~~~~~~~~~~~~~~~~~~~~~~'), nl,
        instructions,
        look.


/* ----------------------------------------------------------------- */
/* Room descriptions. A room may describe who and what is present.   */
/* ----------------------------------------------------------------- */

describe(trade_road) :-
        write('You stand on the old trade road at the edge of Dustfall, a tired'), nl,
        write('frontier town hemmed in by endless dunes. The desert lies south;'), nl,
        write('the town''s main street is north.'), nl.

describe(main_street) :-
        write('Main Street. Dirt road, weathered wood and stone buildings. People'), nl,
        write('move quietly, bracing for the next tribute. The magic shop is west,'), nl,
        write('the sheriff''s office east, the water tower north, the road south.'), nl.

describe(magic_shop) :-
        write('A cramped magic shop, shelves thick with dust. The elderly shopkeeper'), nl,
        write('watches you from behind the counter. Main Street is east.'), nl.

describe(sheriff_office) :-
        write('The sheriff''s office. A worn desk, a rack of unused rifles. The'), nl,
        write('sheriff sits here, grim and unmoving. Main Street is west.'), nl.

describe(water_tower) :-
        write('The town water tower, Dustfall''s most guarded treasure. You could'), nl,
        write('refill a canteen here. Main Street is south, the homes lie west.'), nl.

describe(residential) :-
        write('The residential quarter - patched-up houses passed down for'), nl,
        write('generations. Two young twin girls watch you from a doorway.'), nl,
        write('The water tower is east, the old stable south.'), nl.

describe(old_stable) :-
        write('The old stable, half-abandoned, smelling of straw and rust. A'), nl,
        write('stranded bird-person rests in the corner. The quarter is north.'), nl.

describe(deep_desert) :-
        write('The deep desert. Wind claws at the dunes and reshapes them by the'), nl,
        write('hour. The town is north; something dark looms further south.'), nl.

describe(collector_exterior) :-
        write('You stand beneath The Collector - a mountain of crusted hide and'), nl,
        write('sediment, vast as a hill. An iron hatch sits low in its flank.'), nl,
        write('The desert is north; the way in is, well, in.'), nl.

describe(collector_interior) :-
        write('Inside the machine. Ancient mechanisms turn in the gloom, untouched'), nl,
        write('by the centuries. A narrow passage leads further in; the hatch is out.'), nl.

describe(control_room) :-
        write('The control core - a silent chamber of strange instruments still'), nl,
        write('faintly alive. At its center, a single empty socket waits. (out leads back.)'), nl.
