:- dynamic i_am_at/1, at/2, holding/1, water_level/1, lit/1, flag/1, steps/1.

:- retractall(i_am_at(_)),
   retractall(at(_, _)),
   retractall(holding(_)),
   retractall(water_level(_)),
   retractall(lit(_)),
   retractall(flag(_)),
   retractall(steps(_)).






i_am_at(trade_road).

water_level(3).

at(lantern, old_stable).

steps(0).


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

path(collector_exterior,  in,  collector_interior).
path(collector_interior,  out, collector_exterior).

path(collector_interior,  in,  control_room).
path(control_room,        out, collector_interior).



desert(deep_desert).
desert(collector_exterior).

dark(collector_interior).
dark(control_room).






take(X) :-
        holding(X),
        write('Das hast du schon aufgehoben!'),
        !, nl.

take(X) :-
        i_am_at(Place),
        at(X, Place),
        retract(at(X, Place)),
        assert(holding(X)),
        write('OK.'), nl,
        ( member(X, [lantern, ancient_component])
        -> write('Neue Befehle sind jetzt verfügbar. (Gib "instructions." für Details ein.)'), nl
        ;  true ),
        increment_steps,
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
        increment_steps,
        !, nl.

drop(_) :-
        write('Das Item hast du nicht!'),
        nl.







inventory :-
        findall(X, holding(X), Things),
        ( Things == []
        -> write('Dein Inventar ist leer'), nl
        ;  write('Dein Inventar beinhaltet:'), nl, list_things(Things) ),
        water_level(W),
        write('Wasser in deiner Kantine: '), write(W), nl.

list_things([]).
list_things([Thing | Rest]) :-
        write('  - "'), write(Thing), write('"'), nl,
        list_things(Rest).


i :- inventory.

have_all([]).
have_all([Item | Rest]) :-
        holding(Item),
        have_all(Rest).


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
        !,
        increment_steps.

go(_) :-
        write('In diese Richtung kannst du nicht gehen.'), nl.



try_enter(_, collector_interior) :-
        \+ holding(access_key),
        !,
        nl,
        write('Hier gibt es keinen Weg hinein.'), nl.

try_enter(_, There) :-
        enter(There).





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


enter(There) :-
        desert(There),
        !,
        write('Du nimmst einen Schluck aus deiner Kantine.'), nl,
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



dark_check(There) :-
        dark(There),
        \+ ( holding(lantern), lit(lantern) ),
        !,
        nl,
        write('Es ist stockfinster in der Maschine. Du stolperst blind herum.'), nl,
        write('Du steigst auf etwas das leise Nachgibt, bis du plötzlich einen lauten Knall über dir hörst.'), nl,
        die.

dark_check(_).






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


refill :-
        i_am_at(water_tower),
        !,
        retract(water_level(_)),
        assert(water_level(5)),
        write('Du füllst deine Kantine bis kein Tropfen mehr rein passt. (Water: 5)'), nl,
        increment_steps.
refill :-
        write('Du findest hier kein Trinkwasser.'), nl.






dig :-
        i_am_at(deep_desert),
        \+ flag(dig_heard),
        !,
        assert(flag(dig_heard)),
        nl,
        write('Du gräbst tief im heißen Sand.'), nl,
        write('Plötzlich hörst du ein leises Rasseln von tiefer unten im Sand.'), nl,
        increment_steps.

dig :-
        i_am_at(deep_desert),
        flag(dig_heard),
        \+ flag(dug),
        !,
        assert(flag(dug)),
        assert(at(ancient_component, deep_desert)),
        nl,
        write('Du gräbst noch einmal dort, wo du das Rasseln gehört hast.'), nl,
        write('Mit deinen Fingern fühlst du etwas metallisches: ein seltsames altes Maschinenteil,'), nl,
        write('Relikt und Maschine zugleich. Beweis, dass das Monster nie lebendig war.'), nl,
        write('Du hast einen "ancient_component" vor dir.'), nl,
        increment_steps.

dig :-
        i_am_at(deep_desert),
        flag(dug),
        !,
        write('Es gibt hier nix mehr zum ausgraben'), nl.

dig :-
        write('Der Boden hier ist zu fest.'), nl.







buy(oil) :-
        i_am_at(magic_shop),
        \+ holding(oil),
        !,
        assert(holding(oil)),
        write('Der Ladenbesitzer schiebt eine Flasche "oil" über den'), nl,
        write('Bartresen. "Verschwende es nicht. Das war meine letzte Reserve."'), nl,
        increment_steps.
buy(oil) :-
        holding(oil),
        !,
        write('Das war mein letztes "oil". Mehr habe ich nicht!'), nl.
buy(_) :-
        i_am_at(magic_shop),
        !,
        write('Das verkaufe ich hier nicht.'), nl.
buy(_) :-
        write('Hier kann man nix kaufen.'), nl.


fill(lantern) :-
        holding(lantern),
        holding(oil),
        !,
        retract(holding(oil)),
        assert(flag(lantern_filled)),
        write('Du füllst die "lantern" mit "oil" auf. Sie kann jetzt angezündet werden.'), nl,
        increment_steps.
fill(lantern) :-
        \+ holding(lantern),
        !,
        write('Du hast keine "lantern".'), nl.
fill(lantern) :-
        write('Du brauchst "oil" um die "lantern" aufzufüllen.'), nl.
fill(_) :-
        write('Das kann man nicht auffüllen.'), nl.


light(lantern) :-
        lit(lantern),
        !,
        write('Die "lantern" brennt schon.'), nl.
light(lantern) :-
        holding(lantern),
        flag(lantern_filled),
        !,
        assert(lit(lantern)),
        write('Die "lantern" fängt an zu brennen, du kannst ihre Wärme in deinen Händen fühlen.'), nl,
        increment_steps.
light(lantern) :-
        holding(lantern),
        !,
        write('Die "lantern" hat kein "oil" und kann nicht angezündet werden.'), nl.
light(lantern) :-
        write('Du hast keine "lantern".'), nl.
light(_) :-
        write('Das sollte man nicht anzünden.'), nl.






talk(sheriff) :-
        i_am_at(sheriff_office),
        !,
        nl,
        write('Der Sherif schaut nicht auf beim Sprechen. "Noch ein Abenteurer. Hör mir zu:'), nl,
        write('verbreite keine falsche Hoffnung. Wir zahlen unseren Anteil und nur so können wir überleben."'), nl,
        write('"Im Kampf gegen das Biest würden wir nur Leben verschwenden. Lass es einfach seihen."'), nl,
        increment_steps.

talk(twins) :-
        i_am_at(residential),
        !,
        nl,
        write('Die Zwillingsmädchen mustern dich misstrauisch. "Wir sollen nicht mit'), nl,
        write('Fremden sprechen." Eines kommt etwas näher: "Aber wir haben es gehört.'), nl,
        write('Tief in der Wüste - Ein Rauschen unter dem Sand.'), nl,
        write('Irgendwas ist dort vergraben. Du solltest danach suchen."'), nl,
        increment_steps.

talk(bird_person) :-
        i_am_at(old_stable),
        !,
        nl,
        write('Der Vogelmensch faltet einen gebrochenen Flügel. "Ich bin nicht aus dieser Stadt,"'), nl,
        write('also sage ich, was sie nicht sagen werden: Dieses Ding ist kein Tier."'), nl,
        write('"Nimm die alte "lantern" hier. Du wirst Licht brauchen, wo du hingehst."'), nl,
        increment_steps.


talk(shopkeeper) :-
        i_am_at(magic_shop),
        holding(ancient_component),
        \+ holding(access_key),
        !,
        assert(holding(access_key)),
        nl,
        write('Der Ladenbesitzer starrt auf das "ancient_component" in deinen Händen.'), nl,
        write('"Also. Du hast es gefunden. Ich war jung, als ich das letzte Mal so ein Stück selbst halten durfte."'), nl,
        write('Er drückt dir einen alten "access_key" in die Hand. "Das Biest hat eine Luke.'), nl,
        write('Das öffnet sie. Geh rein, finde den Kern und schalte das Ding ab.'), nl,
        write('Beende, was ich damals nicht konnte." (Du hast einen "access_key" erhalten.)'), nl,
        increment_steps.
talk(shopkeeper) :-
        i_am_at(magic_shop),
        holding(access_key),
        !,
        nl,
        write('"Warum bist du noch hier? Das Monster ist draußen in der Wüste. Geh."'), nl,
        increment_steps.
talk(shopkeeper) :-
        i_am_at(magic_shop),
        !,
        nl,
        write('Der Ladenbesitzer grunzt. "Du willst die Wahrheit? Die Wüste behält es."'), nl,
        write('"Bring mir etwas Solides und du erfährst, was du wissen willst."'), nl,
        write('"Und kauf etwas "oil", solange du hier bist. Du brauchst eine "lantern"."'), nl,
        increment_steps.

talk(_) :-
        write('Gerade will Niemand mit dir reden.'), nl.







deactivate :-
        i_am_at(control_room),
        have_all([ancient_component]),
        !,
        nl,
        write('Du setzt das "ancient_component" in die leere Stelle im Kern.'), nl,
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
        write('Du brauchst das "ancient_component", das du in der Wüste ausgegraben hast.'), nl,
        increment_steps.
deactivate :-
        write('Hier kann man nichts deaktivieren.'), nl.


fight :-
        i_am_at(collector_exterior),
        !,
        nl,
        write('Du stellst dich Depulsor direkt in den Weg. Mit einem Schrei ziehst du deine Waffe und'), nl,
        write('mobilisierst die verzweifelten Bewohner von Dustfall zu einem letzten, selbstmörderischen Sturm.'), nl,
        write('Pfeile, Kugeln und glühendes Zauberfeuer prallen in einem ohrenbetäubenden Aufprall'), nl,
        write('gegen seine tonnenschwere, verkrustete Haut aus Sediment und Stein. Doch der gigantische Koloss schreitet einfach voran.'), nl,
        write('Keine deiner Attacken hinterlässt auch nur einen Kratzer auf der uralten Bestie.'), nl,
        write('Mit einem dumpfen, mahlenden Grollen hebt sich ein gigantischer Fuß des Ungetüms.'), nl,
        write('Ein Schatten legt sich über dich, bevor Tonnen aus hartem Gestein und Erde auf dich niederkrachen.'), nl,
        write('Deine Knochen zersplittern unter dem unvorstellbaren Druck. Das Letzte, was du hörst, ist das dumpfe,'), nl,
        write('gleichgültige Grollen des Monsters, das dein Leben einfach im Vorbeigehen zerquetschen.'), nl,
        die.
fight :-
        write('Hier kannst du nicht kämpfen.'), nl.

forced_fight :-
        nl,
        write('Der gigantische Koloss — Depulsor — bricht mit ohrenbetäubendem Lärm durch die Grenzen von Dustfall.'), nl,
        write('Häuser zerbersten wie Streichhölzer unter seinen gewaltigen Schritten. Du stellst dich dem gigantischen Ungetüm'), nl,
        write('todesmutig in den Weg, ziehst deine Waffe und stürzt dich in den ungleichen Kampf.'), nl,
        write('Mit aller Kraft schlägst du auf die dicke Kruste seines Körpers ein, doch deine Angriffe hinterlassen'), nl,
        write('nicht einmal einen Kratzer auf dem uralten, steinernen Panzer aus Sediment.'), nl,
        write('Ein wuchtiges Bein des Kolosses fegt dich mit brutaler Leichtigkeit beiseite. Du fliegst durch die Luft'), nl,
        write('und prallst hart gegen die Ruinen eines eingestürzten Hauses. Deine Knochen zersplittern, heiße Schmerzen durchzucken dich.'), nl,
        write('Während dir das Blut in die Augen steigt und du verzweifelt nach Luft ringst, schreitet Depulsor ungerührt voran.'), nl,
        write('Er begräbt dich und die schreiende Stadt unter Tonnen von brennendem Trümmerfeld und erstickendem Wüstensand.'), nl,
        write('Dein Blick wird dunkel, während das monotone, ferne Grollen des Ungetüms dein Ende besiegelt.'), nl,
        die.

increment_steps :-
        steps(S),
        NewS is S + 1,
        retract(steps(S)),
        assert(steps(NewS)),
        check_step_limit.

check_step_limit :-
        holding(access_key),
        !.
check_step_limit :-
        steps(S),
        S >= 70,
        !,
        nl,
        write('=== DIE ZEIT IST ABGELAUFEN ==='), nl,
        write('Ein gewaltiges, dumpfes Dröhnen erschüttert die Erde.'), nl,
        write('Der Himmel verdunkelt sich, als sich Depulsor — der gigantische Koloss —'), nl,
        write('aus den Dünen erhebt. Er kommt, um seinen gnadenlosen Tribut einzufordern.'), nl,
        write('Es gibt kein Entkommen mehr. Inmitten von Panik und Schreien stellst du dich'), nl,
        write('dem furchterregenden Ungeheuer entgegen...'), nl,
        forced_fight.
check_step_limit :-
        steps(S),
        S == 50,
        !,
        nl,
        write('(WARNUNG: Der Wind weht unruhiger. Die Stadtbewohner tuscheln nervös. Der Tag des Tributs rückt näher...)'), nl.
check_step_limit :-
        steps(S),
        S == 60,
        !,
        nl,
        write('(WARNUNG: Der Wüstensand bebt leicht. Die Zeit wird extrem knapp. Depulsor wird bald eintreffen!)'), nl.
check_step_limit.

look :-
        i_am_at(Place),
        describe(Place),
        nl,
        notice_objects_at(Place),
        nl.

notice_objects_at(Place) :-
        at(X, Place),
        write('Hier siehst du einen "'), write(X), write('"'), nl,
        fail.
notice_objects_at(_).

die :-
        nl,
        write('*** DEIN ABENTEUER ENDET HIER IM STAUB ***'), nl,
        write('Die Wüste nimmt sich, was ihr gehört. Deine Geschichte verweht im heißen Wind...'), nl,
        finish.

finish :-
        nl,
        write('Das Spiel ist vorbei. Beende das Program mit "halt."'),
        nl.






instructions :-
        nl,
        write('Gib Befehle in normaler Prolog-Syntax ein (jeden Befehl mit einem "." abschließen).'), nl,
        write('Verfügbare Befehle sind:'), nl,
        write('start.              -- Spiel neu starten / diese Übersicht erneut anzeigen.'), nl,
        write('n.  s.  e.  w.      -- in diese Richtung gehen.'), nl,
        write('in.  out.           -- ein Gebäude oder eine Struktur betreten bzw. verlassen.'), nl,
        write('look.               -- die Umgebung erneut betrachten.'), nl,
        write('take(Object).       -- einen Gegenstand ("lantern", "ancient_component", "access_key", "oil") aufheben.'), nl,
        write('drop(Object).       -- einen Gegenstand ablegen.'), nl,
        write('inventory.   (or i.)-- zeigen, was du bei dir trägst.'), nl,
        write('talk(Who).          -- mit einem Dorfbewohner sprechen ("sheriff", "twins", "bird_person", "shopkeeper").'), nl,
        write('buy(Object).        -- etwas kaufen (im Laden, z.B. "oil").'), nl,
        ( holding(lantern)
        -> write('fill(lantern).      -- "oil" in die "lantern" füllen.'), nl,
           write('light(lantern).     -- eine gefüllte "lantern" anzünden.'), nl
        ;  true ),
        ( \+ flag(dug)
        -> write('dig.                -- an deiner aktuellen Position graben.'), nl
        ;  true ),
        write('refill.             -- die Feldflasche auffüllen (am Wasserturm).'), nl,
        ( holding(ancient_component)
        -> write('deactivate.         -- die Maschine abschalten (vom Kern aus).'), nl
        ;  true ),
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
        nl,
        write('Du bist ein Fremder, gerade erst in Dustfall angekommen. Seit'), nl,
        write('Generationen erhebt sich einmal im Monat ein gewaltiges Ungetüm'), nl,
        write('aus der Wüste — Depulsor — und fordert seinen Tribut: Nahrung,'), nl,
        write('Vieh, Werkzeug. Wer sich weigert, wird vernichtet. Doch die'), nl,
        write('Vorräte der Stadt sind fast erschöpft; zahlt sie erneut, verhungert'), nl,
        write('sie. Niemand glaubt mehr an Rettung. Vielleicht findest du heraus,'), nl,
        write('was das Monster wirklich ist — und wie man es aufhalten kann.'), nl,
        nl,
        instructions,
        look.






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
        write('bedeckt sind. Der betagte Ladenbesitzer ("shopkeeper") beobachtet dich hinter dem'), nl,
        write('Tresen. Die Hauptstraße liegt im Osten.'), nl.

describe(sheriff_office) :-
        write('Das Büro des Sheriffs. Ein abgenutzter Schreibtisch und ein Gestell'), nl,
        write('mit unbenutzten Gewehren stehen hier. Der Sheriff ("sheriff") sitzt regungslos'), nl,
        write('an seinem Platz. Die Hauptstraße liegt im Westen.'), nl.

describe(water_tower) :-
        write('Der Wasserturm der Stadt, Dustfalls am strengsten bewachter Schatz.'), nl,
        write('Hier könntest du eine Feldflasche auffüllen. Die Hauptstraße liegt'), nl,
        write('im Süden, die Wohnhäuser im Westen.'), nl.

describe(residential) :-
        write('Das Wohnviertel mit notdürftig instand gehaltenen Häusern, die seit'), nl,
        write('Generationen weitergegeben werden. Zwei junge Zwillingsmädchen ("twins")'), nl,
        write('beobachten dich aus einer Türöffnung.'), nl,
        write('Der Wasserturm liegt im Osten, der alte Stall im Süden.'), nl.

describe(old_stable) :-
        write('Der alte Stall, halb verlassen und erfüllt vom Geruch nach Stroh'), nl,
        write('und Rost. In einer Ecke ruht eine gestrandete Vogelperson ("bird_person"). Das'), nl,
        write('Wohnviertel liegt im Norden.'), nl.

describe(deep_desert) :-
        write('Die tiefe Wüste. Der Wind krallt sich in die Dünen und formt sie'), nl,
        write('von Stunde zu Stunde neu. Die Stadt liegt im Norden; weiter südlich'), nl,
        write('zeichnet sich eine dunkle Silhouette ab.'), nl.

describe(collector_exterior) :-
        holding(access_key),
        !,
        write('Du stehst vor Depulsor, einem gewaltigen Berg aus verkrusteter'), nl,
        write('Haut und Sediment, groß wie ein Hügel. Tief an seiner Flanke befindet'), nl,
        write('sich eine eiserne Luke — dein "access_key" passt genau hinein.'), nl,
        write('Die Wüste liegt im Norden; die Luke führt nach in.'), nl,
        ( \+ holding(lantern)
		->  write('(In der Luke ist es dunkel, du brauchst vielleicht eine "lantern".)'), nl
		; \+ lit(lantern)
		->  write('(In der Luke ist es dunkel, zünde zuerst deine "lantern" an.)'), nl
		; true
		).

describe(collector_exterior) :-
        write('Du stehst vor Depulsor, einem gewaltigen Berg aus verkrusteter'), nl,
        write('Haut und Sediment, groß wie ein Hügel. Die Oberfläche ist'), nl,
        write('dicht mit Schichten aus Rost und erstarrtem Sediment bedeckt.'), nl,
        write('Die Wüste liegt im Norden.'), nl.

describe(collector_interior) :-
        write('Du betrittst das Innere der Maschine. Uralte Mechanismen erleuchten'), nl,
        write('durch deine "lantern", unberührt von den Jahrhunderten. Verblasste'), nl,
        write('Zeichen einer Zivilisation, die längst verschwunden ist, bedecken'), nl,
        write('die Wände — Depulsor sammelt noch immer für eine Welt, die es nicht'), nl,
        write('mehr gibt. Ein schmaler Gang führt tiefer hinein; die Luke liegt out.'), nl.

describe(control_room) :-
        write('Der Kontrollkern, eine stille Kammer voller fremdartiger Instrumente,'), nl,
        write('die noch immer schwach leben. Im Zentrum wartet eine einzelne leere'), nl,
        write('Fassung. Die Form ähnelt dem "ancient_component", das du in der Wüste ausgegraben hast.'), nl,
        write('(out führt zurück.)'), nl.
