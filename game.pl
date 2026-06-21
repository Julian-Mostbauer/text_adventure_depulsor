/* Depulsor - a text adventure set in the desert town of Dustfall.
   By <your name goes here>.

   Adapted from the Matuszek/UPenn adventure template.

   Goal (no spoilers): survive Dustfall, learn the truth about the
   monster called Depulsor, and decide the town's fate.

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
        write('Der Sherif schaut nicht auf beim Sprechen. "Noch ein Abenteurer. Hör mir zu:'), nl,
        write('verbreite keine falsche Hoffnung. Wir zahlen unseren Anteil und nur so können wir überleben."'), nl,
        write('"Im Kampf gegen das Biest würden wir nur Leben verschwenden. Lass es einfach seihen."'), nl.

talk(twins) :-
        i_am_at(residential),
        !,
        nl,
        write('Die Zwillingsmädchen mustern dich misstrauisch. "Wir sollen nicht mit'), nl,
        write('Fremden sprechen." Eines kommt etwas näher: "Aber wir haben es gehört.'), nl,
        write('Tief in der Wüste - Ein Rauschen unter dem Sand.'), nl,
        write('Irgendwas ist dort vergraben. Du solltest danach suchen."'), nl.

talk(bird_person) :-
        i_am_at(old_stable),
        !,
        nl,
        write('Der Vogelmensch faltet einen gebrochenen Flügel. "Ich bin nicht aus dieser Stadt,"'), nl,
        write('also sage ich, was sie nicht sagen werden: Dieses Ding ist kein Tier."'), nl,
        write('"Nimm die alte Lampe hier. Du wirst Licht brauchen, wo du hingehst."'), nl.

/* The shopkeeper gives the access_key once you bring real proof. */
talk(shopkeeper) :-
        i_am_at(magic_shop),
        holding(ancient_component),
        \+ holding(access_key),
        !,
        assert(holding(access_key)),
        nl,
        write('Der Ladenbesitzer starrt auf das Relikt in deinen Händen.'), nl,
        write('"Also. Du hast es gefunden. Ich war jung, als ich das letzte Mal so ein Stück selbst halten durfte."'), nl,
        write('Er drückt dir einen alten Eisenschlüssel in die Hand. "Das Biest hat eine Luke.'), nl,
        write('Das öffnet sie. Geh rein, finde den Kern und schalte das Ding ab.'), nl,
        write('Beende, was ich damals nicht konnte." (Du hast einen "access_key" erhalten.)'), nl.
talk(shopkeeper) :-
        i_am_at(magic_shop),
        holding(access_key),
        !,
        nl,
        write('"Warum bist du noch hier? Das Monster ist draußen in der Wüste. Geh."'), nl.
talk(shopkeeper) :-
        i_am_at(magic_shop),
        !,
        nl,
        write('Der Ladenbesitzer grunzt. "Du willst die Wahrheit? Die Wüste behält es."'), nl,
        write('"Bring mir etwas Solides ... grabe hinter der Straße und ich rede."'), nl,
        write('"Und kauf etwas Öl, solange du hier bist. Du brauchst eine Lampe."'), nl.

talk(_) :-
        write('Gerade will Niemand mit dir reden.'), nl.


/* ----------------------------------------------------------------- */
/* The endings.                                                      */
/* ----------------------------------------------------------------- */

/* TRUE ENDING: deactivate the machine from the control room. */
deactivate :-
        i_am_at(control_room),
        have_all([ancient_component]),
        !,
        nl,
        write('Du setzt das uralte Bauteil in die leere Stelle im Kern.'), nl,
        write('Jahrhunderte blinder Routine stottern, verlangsamen und verstummen.'), nl,
        write('Depulsor wird nie wieder nach Dustfall kommen.'), nl,
        nl,
        write('*** DU HAST DUSTFALL BEFREIT. Das Spiel ist vorbei. ***'), nl,
        finish.
deactivate :-
        i_am_at(control_room),
        !,
        nl,
        write('Der Steuerkern hat eine leere Buchse ... irgendetwas gehört hierher.'), nl,
        write('Du brauchst das Relikt, das du in der Wüste ausgegraben hast.'), nl.
deactivate :-
        write('Hier kann man nichts deaktivieren.'), nl.

/* FAILURE ENDING: a last stand against the machine. */
fight :-
        i_am_at(collector_exterior),
        !,
        nl,
        write('Du motivierst die Stadtbewohner zu einem letzten Widerstand gegen das Monster.'), nl,
        write('Stahl und Zauberfeuer brallen gegen seine uralte Haut. Doch das verlangsamt'), nl,
        write('die Maschine nicht mal. Mut, wie sich herausstellte, war nie das fehlende Puzzlestück.'), nl,
        die.
fight :-
        write('Hier kannst du nicht kämpfen.'), nl.


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
        write('Hier siehst du einen '), write(X), nl,
        fail.
notice_objects_at(_).


/* ----------------------------------------------------------------- */
/* Death and game over (from the template).                          */
/* ----------------------------------------------------------------- */

die :-
        nl,
        write('*** Tod ***'), nl,
        finish.

finish :-
        nl,
        write('Das Spiel ist vorbei. Beende das Program mit "halt."'),
        nl.


/* ----------------------------------------------------------------- */
/* Instructions and start.                                           */
/* ----------------------------------------------------------------- */

instructions :-
        nl,
        write('Gib Befehle in normaler Prolog-Syntax ein (jeden Befehl mit einem "." abschließen).'), nl,
        write('Verfügbare Befehle sind:'), nl,
        write('start.              -- Spiel neu starten / diese Übersicht erneut anzeigen.'), nl,
        write('n.  s.  e.  w.      -- in diese Richtung gehen.'), nl,
        write('in.  out.           -- ein Gebäude oder eine Struktur betreten bzw. verlassen.'), nl,
        write('look.               -- die Umgebung erneut betrachten.'), nl,
        write('take(Object).       -- einen Gegenstand aufheben.'), nl,
        write('drop(Object).       -- einen Gegenstand ablegen.'), nl,
        write('inventory.   (or i.)-- zeigen, was du bei dir trägst.'), nl,
        write('talk(Who).          -- mit einem Dorfbewohner sprechen.'), nl,
        write('buy(Object).        -- etwas kaufen (im Laden).'), nl,
        write('fill(lantern).      -- Öl in die Laterne füllen.'), nl,
        write('light(lantern).     -- eine gefüllte Laterne anzünden.'), nl,
        write('dig.                -- an deiner aktuellen Position graben.'), nl,
        write('refill.             -- die Feldflasche auffüllen (am Wasserturm).'), nl,
        write('deactivate.         -- die Maschine abschalten (vom Kern aus).'), nl,
        write('fight.              -- dich Depulsor entgegenstellen.'), nl,
        write('instructions.       -- diese Hilfe erneut anzeigen.'), nl,
        write('halt.               -- das Spiel beenden.'), nl,
        nl.


start :-
        nl,
        write('                         MMMMMMM                     MMMMMMMMMMMMMM'), nl,
        write('                      MMMMMMMMMMMM                MMMMMMMMMMMMMMMMMMM'), nl,
        write('                    MMMMMMMMMMMMMMMM                MMMMMMMMMMMMMMMMM'), nl,
        write('               MMMMMMMMMMMMMMMMMMMMMM              MMMMMMMMMMMMM   MM'), nl,
        write('            MMMMMMMMMMMMMMMMMMMMMMMMMMM            MMMMMMMMMMM'), nl,
        write('          MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM        MMMMMMMMMMMM'), nl,
        write('        MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM    MMMMMMMMMMMMM'), nl,
        write('        MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM'), nl,
        write('       MMMMMMMMMMMMM    DEPULSOR    MMMMMMMMMMMMMMMMMMMMMM'), nl,
        write('       MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM'), nl,
        write('       MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM'), nl,
        write('      MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM'), nl,
        write('     MMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMM'), nl,
        write('    MMMMMMMM  MMMMMMMM  MMMMMMMMMMMMMMMMMMMM'), nl,
        write('   MMMMM  M   MMMMMMM       MNMMMMMMMMMMMMMM'), nl,
        write(' MMMMM  MMMM  MMMMMM          MMMMM  MMMMMM'), nl,
        write('MMMMMM  MMM  MMMMMM           MMMMM   MMMMM'), nl,
        write('MMMMM     M  MMMMM            MMMM     MMMM'), nl,
        write('MMMM        MMMMM           MMMMMM      MMMMM'), nl,
        write(' MMM       MMMMMMM          NMMMMM      MMMMM'), nl,
        write(' MM         MMMM             MMMM         MMM'), nl,
        write('MMMM         MMMM           MMMM           MM'), nl,
        write(' MMM          MMM           MMM            MMM'), nl,
        write(' MMMM         MMMM         MMM              MMM'), nl,
        write(' MMMMM         MMM        MMMM               MMM'), nl,
        write('   MMMMMM      MMMM        MMMM              MMMMMM'), nl,
        write('      MMM       MMMMM       MMMM              MMMMMM'), nl,
        write('                  MMMMMM                        MMMMM'), nl,
        write('                    MMMMM'), nl,
        instructions,
        look.


/* ----------------------------------------------------------------- */
/* Room descriptions. A room may describe who and what is present.   */
/* ----------------------------------------------------------------- */

describe(trade_road) :-
        write('Du stehst auf der alten Handelsstraße am Rand von Dustfall, einer'), nl,
        write('erschöpften Grenzstadt, die von endlosen Dünen umgeben ist. Die'), nl,
        write('Wüste erstreckt sich im Süden, die Hauptstraße der Stadt liegt im Norden.'), nl.

describe(main_street) :-
        write('Die Hauptstraße. Eine staubige Straße, gesäumt von verwitterten Holz-'), nl,
        write('und Steingebäuden. Die Menschen bewegen sich schweigend und erwarten'), nl,
        write('bereits den nächsten Tribut. Der Magieladen liegt im Westen, das'), nl,
        write('Sheriffbüro im Osten, der Wasserturm im Norden und die Straße im Süden.'), nl.

describe(magic_shop) :-
        write('Ein beengter Magieladen, dessen Regale von einer dicken Staubschicht'), nl,
        write('bedeckt sind. Der betagte Ladenbesitzer beobachtet dich hinter dem'), nl,
        write('Tresen. Die Hauptstraße liegt im Osten.'), nl.

describe(sheriff_office) :-
        write('Das Büro des Sheriffs. Ein abgenutzter Schreibtisch und ein Gestell'), nl,
        write('mit unbenutzten Gewehren stehen hier. Der Sheriff sitzt regungslos'), nl,
        write('an seinem Platz. Die Hauptstraße liegt im Westen.'), nl.

describe(water_tower) :-
        write('Der Wasserturm der Stadt, Dustfalls am strengsten bewachter Schatz.'), nl,
        write('Hier könntest du eine Feldflasche auffüllen. Die Hauptstraße liegt'), nl,
        write('im Süden, die Wohnhäuser im Westen.'), nl.

describe(residential) :-
        write('Das Wohnviertel mit notdürftig instand gehaltenen Häusern, die seit'), nl,
        write('Generationen weitergegeben werden. Zwei junge Zwillingsmädchen'), nl,
        write('beobachten dich aus einer Türöffnung.'), nl,
        write('Der Wasserturm liegt im Osten, der alte Stall im Süden.'), nl.

describe(old_stable) :-
        write('Der alte Stall, halb verlassen und erfüllt vom Geruch nach Stroh'), nl,
        write('und Rost. In einer Ecke ruht eine gestrandete Vogelperson. Das'), nl,
        write('Wohnviertel liegt im Norden.'), nl.

describe(deep_desert) :-
        write('Die tiefe Wüste. Der Wind krallt sich in die Dünen und formt sie'), nl,
        write('von Stunde zu Stunde neu. Die Stadt liegt im Norden; weiter südlich'), nl,
        write('zeichnet sich eine dunkle Silhouette ab.'), nl.

describe(collector_exterior) :-
        write('Du stehst vor Depulsor, einem gewaltigen Berg aus verkrusteter'), nl,
        write('Haut und Sediment, groß wie ein Hügel. Tief an seiner Flanke befindet'), nl,
        write('sich eine eiserne Luke.'), nl,
        write('Die Wüste liegt im Norden; der Weg hinein führt, nun ja, nach in.'), nl.

describe(collector_interior) :-
        write('Im Inneren der Maschine. Uralte Mechanismen arbeiten in der Dunkelheit'), nl,
        write('weiter, unberührt von den Jahrhunderten. Ein schmaler Gang führt'), nl,
        write('tiefer hinein; die Luke liegt out.'), nl.

describe(control_room) :-
        write('Der Kontrollkern, eine stille Kammer voller fremdartiger Instrumente,'), nl,
        write('die noch immer schwach leben. Im Zentrum wartet eine einzelne leere'), nl,
        write('Fassung. (out führt zurück.)'), nl.
