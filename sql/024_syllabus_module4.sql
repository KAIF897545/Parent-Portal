-- ===================== 4.1 A repertoire as Black =====================

update public.items set
  how_to_teach = $ht$Help the student choose one defence to 1.e4 (e.g. Caro-Kann, French, Sicilian) suited to her style, and teach its core structural idea -- what pawn formation and piece placement it aims for, not just the moves.$ht$,
  how_to_check = $hc$Explains the chosen defence's main idea and structural aim in her own words.$hc$,
  puzzles = $pz$Not applicable -- an opening-choice and understanding task.$pz$,
  assignments = $as$Not required as separate homework -- reinforced through the explanation and later play.$as$
where description = 'Has a defence to 1.e4 and states its main idea.';

update public.items set
  how_to_teach = $ht$Teach the main line of the chosen 1.e4 defence move by move to around move eight, explaining the purpose of each move.$ht$,
  how_to_check = $hc$Demonstrates the main line to move eight from memory, unprompted.$hc$,
  puzzles = $pz$Not applicable -- an opening-memorisation task.$pz$,
  assignments = $as$Not required as separate homework -- reinforced through repetition until automatic.$as$
where description = 'Knows that defence to move eight in the main line.';

update public.items set
  how_to_teach = $ht$Help the student choose one defence to 1.d4 (e.g. Queen's Gambit Declined, Slav, King's Indian) suited to her style and teach its core structural idea, as with the 1.e4 defence.$ht$,
  how_to_check = $hc$Explains the chosen defence's main idea and structural aim in her own words.$hc$,
  puzzles = $pz$Not applicable -- an opening-choice and understanding task.$pz$,
  assignments = $as$Not required as separate homework -- reinforced through the explanation and later play.$as$
where description = 'Has a defence to 1.d4 and states its main idea.';

update public.items set
  how_to_teach = $ht$Teach the main line of the chosen 1.d4 defence to move eight, again explaining each move's purpose.$ht$,
  how_to_check = $hc$Demonstrates the main line to move eight from memory, unprompted.$hc$,
  puzzles = $pz$Not applicable -- an opening-memorisation task.$pz$,
  assignments = $as$Not required as separate homework -- reinforced through repetition until automatic.$as$
where description = 'Knows that defence to move eight.';

update public.items set
  how_to_teach = $ht$Teach how the chosen repertoire against 1.e4 and 1.d4 handles these move orders by transposition, and cover the one or two independent lines White can choose to avoid transposing.$ht$,
  how_to_check = $hc$Explains the transposition plan against 1.c4 and 1.Nf3, and knows the independent lines she might meet.$hc$,
  puzzles = $pz$Not applicable -- an opening move-order task.$pz$,
  assignments = $as$Not required as separate homework -- reinforced through the explanation.$as$
where description = 'Has an answer to 1.c4 and 1.Nf3.';

update public.items set
  how_to_teach = $ht$Teach the typical middlegame plan -- pawn breaks, piece placement, common trades -- that each of the two chosen defences leads to.$ht$,
  how_to_check = $hc$Explains both middlegame plans, one per defence, in her own words.$hc$,
  puzzles = $pz$Not a standard labelled category -- use structural middlegame positions from the repertoire's typical structures.$pz$,
  assignments = $as$Not required as separate homework -- reinforced through play.$as$
where description = 'Knows the typical middlegame plan arising from each defence.';

update public.items set
  how_to_teach = $ht$Identify the one or two gambits most likely to be tried against each defence and teach the correct response -- when to accept, when to decline, and the resulting plan.$ht$,
  how_to_check = $hc$Coach tests three gambit lines across the board; student finds the correct response in each.$hc$,
  puzzles = $pz$"Gambit" themed opening positions matching the repertoire.$pz$,
  assignments = $as$Solve three gambit-response positions during the week.$as$
where description = 'Handles the gambit lines she is likely to meet.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, testing the whole Black repertoire under real conditions with no notes.$ht$,
  how_to_check = $hc$Plays the full Black repertoire across five real games with no notes. Scoresheets show the repertoire followed, alongside a complete, current opening file.$hc$,
  puzzles = $pz$Not applicable -- this checkpoint is five real games, not puzzles.$pz$,
  assignments = $as$No assignment -- this is the checkpoint itself.$as$
where description = 'Checkpoint: plays her full Black repertoire across five games without notes.';

-- ===================== 4.2 Middlegame plans by structure =====================

update public.items set
  how_to_teach = $ht$Teach the minority attack in the Carlsbad structure: advance the queenside pawn minority to create a weakness on c6 or b6, using a set starting position.$ht$,
  how_to_check = $hc$One game from the set Carlsbad position, playing White with the minority attack.$hc$,
  puzzles = $pz$Not applicable -- a full-game plan, best tested through play.$pz$,
  assignments = $as$Play one home game from the same set position, playing White.$as$
where description = 'Carlsbad structure: plays the minority attack as White.';

update public.items set
  how_to_teach = $ht$Teach the standard Black defensive plan in the Carlsbad structure: a kingside minority attack or piece play, racing the queenside advance.$ht$,
  how_to_check = $hc$One game from the set Carlsbad position, playing Black with the kingside plan.$hc$,
  puzzles = $pz$Not applicable -- a full-game plan, best tested through play.$pz$,
  assignments = $as$Play one home game from the same set position, playing Black.$as$
where description = 'Carlsbad structure: defends as Black with the kingside plan.';

update public.items set
  how_to_teach = $ht$Teach hanging pawns (adjacent pawns, e.g. c/d-pawns, with open files either side): their dynamic potential for the side that has them, and the standard blockading/undermining plan against them.$ht$,
  how_to_check = $hc$Two games from a set hanging-pawns position, one from each side.$hc$,
  puzzles = $pz$Not applicable -- a full-game plan, best tested through play.$pz$,
  assignments = $as$Play two home games from the same set position, one per side.$as$
where description = 'Hanging pawns: plays with them and against them.';

update public.items set
  how_to_teach = $ht$Reinforce the closed-centre wing choice from Module 3, this time requiring the student to also prepare and time the eventual pawn break rather than just picking the right wing.$ht$,
  how_to_check = $hc$One game from a set closed-centre position; plays on the correct wing and prepares the break.$hc$,
  puzzles = $pz$Not applicable -- a full-game plan, best tested through play.$pz$,
  assignments = $as$Play one home game from the same set position.$as$
where description = 'Closed centre: plays the correct wing and prepares the break.';

update public.items set
  how_to_teach = $ht$Teach that in an open centre, piece activity and king safety generally outweigh minor structural concerns -- don't get distracted by small weaknesses when pieces are active.$ht$,
  how_to_check = $hc$One game from a set open-centre position; prioritises activity correctly.$hc$,
  puzzles = $pz$Not applicable -- a full-game plan, best tested through play.$pz$,
  assignments = $as$Play one home game from the same set position.$as$
where description = 'Open centre: prioritises piece activity over structure.';

update public.items set
  how_to_teach = $ht$Teach the standard space-advantage technique: avoid trading pieces, which eases the cramped side's game, and instead squeeze by restricting the opponent's pieces further.$ht$,
  how_to_check = $hc$One game from a set space-advantage position; avoids trades and squeezes correctly.$hc$,
  puzzles = $pz$Not applicable -- a full-game plan, best tested through play.$pz$,
  assignments = $as$Play one home game from the same set position.$as$
where description = 'Space advantage: avoids trades and squeezes.';

update public.items set
  how_to_teach = $ht$Go through the student's own repertoire, both colours, and identify which of the five structures above each line typically leads to.$ht$,
  how_to_check = $hc$Names the correct structure for her whole repertoire, line by line.$hc$,
  puzzles = $pz$Not applicable -- a repertoire-review task.$pz$,
  assignments = $as$Not required as separate homework -- produced during the review itself.$as$
where description = 'Recognises which of these structures her own openings produce.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, testing recognition and planning across all five structures from set positions.$ht$,
  how_to_check = $hc$Plays five assigned structure positions against the coach, one per structure, then states the correct plan for each; coach records the result.$hc$,
  puzzles = $pz$Not applicable -- this checkpoint is five live games plus explanation, not puzzles.$pz$,
  assignments = $as$No assignment -- this is the checkpoint itself.$as$
where description = 'Checkpoint: plays five assigned structure positions against the coach, one per structure, then states the correct plan for each.';

-- ===================== 4.3 Attacking a castled king =====================

update public.items set
  how_to_teach = $ht$Teach the attacker/defender count as the first check before any sacrifice or attacking commitment: count pieces bearing on the king's position versus pieces defending it.$ht$,
  how_to_check = $hc$5 positions; correctly counts attackers and defenders and judges whether to commit in each.$hc$,
  puzzles = $pz$"Attacking the king" themed positions requiring this specific judgement.$pz$,
  assignments = $as$Solve five count-and-judge positions during the week.$as$
where description = 'Counts attackers and defenders around the king before committing.';

update public.items set
  how_to_teach = $ht$Teach the classic Greek gift sacrifice (Bxh7+) and its three conditions: the bishop's diagonal, the knight ready to jump to g5, and the queen's route to h5 or h4.$ht$,
  how_to_check = $hc$Lists all three conditions from memory and solves 5 Greek gift puzzles.$hc$,
  puzzles = $pz$"Greek gift" / Bxh7+ themed puzzles.$pz$,
  assignments = $as$Solve five Greek gift puzzles during the week.$as$
where description = 'Greek gift sacrifice: knows the conditions that make it work.';

update public.items set
  how_to_teach = $ht$Teach the rook lift (e.g. Rf3-h3 or Re1-e3-h3) as a way to bring a rook into a kingside attack when the other pieces alone aren't enough.$ht$,
  how_to_check = $hc$One game where the student executes a rook lift as part of an attack.$hc$,
  puzzles = $pz$Not applicable -- a full-game technique, best tested through play.$pz$,
  assignments = $as$Play one home game looking for a chance to use a rook lift.$as$
where description = 'Rook lift into the attack.';

update public.items set
  how_to_teach = $ht$Teach sacrificing a pawn specifically to open a file toward the enemy king, evaluating the resulting attack rather than the material.$ht$,
  how_to_check = $hc$3 positions; correctly opens the file with the pawn sacrifice in each.$hc$,
  puzzles = $pz$"Attacking the king" themed positions with a file-opening pawn sacrifice available.$pz$,
  assignments = $as$Solve three such positions during the week.$as$
where description = 'Opens a file towards the king with a pawn sacrifice.';

update public.items set
  how_to_teach = $ht$Teach tempo-counting in opposite-side castling races: count moves needed for each side's attack to land and judge whether there's time to include a slower move.$ht$,
  how_to_check = $hc$3 positions; correctly counts tempi and judges the race in each.$hc$,
  puzzles = $pz$"Opposite side castling" pawn-storm race themed positions.$pz$,
  assignments = $as$Solve three tempo-counting positions during the week.$as$
where description = 'Opposite-side castling: counts tempi in the pawn race.';

update public.items set
  how_to_teach = $ht$Teach recognising when an attack isn't yet justified by the attacker/defender count, and the correct response is to improve pieces first rather than sacrifice prematurely.$ht$,
  how_to_check = $hc$3 positions; correctly identifies that the attack isn't ready and finds the improving move instead.$hc$,
  puzzles = $pz$"Attacking the king" themed positions where the tempting sacrifice is unsound.$pz$,
  assignments = $as$Solve three such positions during the week.$as$
where description = 'Knows when not to attack, and improves pieces instead.';

update public.items set
  how_to_teach = $ht$Teach the classical sacrifices on h7, h6 or g7 (beyond the basic Greek gift) with their calculated follow-up, requiring full calculation rather than pattern alone.$ht$,
  how_to_check = $hc$5 puzzles requiring the sacrifice and its calculated follow-up to mate or win material.$hc$,
  puzzles = $pz$"Sacrifice on h7/h6/g7" themed puzzles.$pz$,
  assignments = $as$Solve five such puzzles during the week.$as$
where description = 'Sacrifices on h7, h6 or g7 with a calculated follow-up.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, combining all the attacking motifs from this unit into a single timed puzzle set.$ht$,
  how_to_check = $hc$Twenty attacking puzzles requiring calculation to mate or decisive material; passes with 15/20 or better, score recorded.$hc$,
  puzzles = $pz$A mixed set of twenty attacking puzzles drawn from this unit's themes.$pz$,
  assignments = $as$No assignment -- this is the checkpoint itself.$as$
where description = 'Checkpoint: twenty attacking puzzles requiring calculation to mate or decisive material.';

-- ===================== 4.4 Defence =====================

update public.items set
  how_to_teach = $ht$Teach threat recognition as the first defensive habit: before playing a move, ask what the opponent's last move threatens.$ht$,
  how_to_check = $hc$5 positions; correctly identifies the threat before it lands in each.$hc$,
  puzzles = $pz$"Find the threat" themed positions.$pz$,
  assignments = $as$Solve five find-the-threat positions during the week.$as$
where description = 'Identifies the opponent''s threat before it lands.';

update public.items set
  how_to_teach = $ht$Teach trading off the opponent's most dangerous attacking piece as a defensive resource, even at the cost of the bishop pair or a small positional concession.$ht$,
  how_to_check = $hc$3 positions; correctly identifies and trades the key attacking piece in each.$hc$,
  puzzles = $pz$"Defence" themed positions with a clear key attacker to trade.$pz$,
  assignments = $as$Solve three such positions during the week.$as$
where description = 'Trades the opponent''s most dangerous attacking piece.';

update public.items set
  how_to_teach = $ht$Teach giving back material -- a pawn, exchange, or piece -- specifically to defuse an attack, rather than clinging to material in a losing attack.$ht$,
  how_to_check = $hc$3 positions; correctly returns material to kill the attack in each.$hc$,
  puzzles = $pz$"Give back material to defend" themed positions.$pz$,
  assignments = $as$Solve three such positions during the week.$as$
where description = 'Returns material to kill an attack.';

update public.items set
  how_to_teach = $ht$Teach finding forced-only moves under pressure: in a forcing sequence with one legal or clearly-best defence, calculate accurately rather than guessing.$ht$,
  how_to_check = $hc$5 positions; finds the only move in each forced sequence.$hc$,
  puzzles = $pz$"Only move" forced-defence themed puzzles.$pz$,
  assignments = $as$Solve five only-move positions during the week.$as$
where description = 'Finds the only move in a forced sequence.';

update public.items set
  how_to_teach = $ht$Teach counterattacking in the centre as the classic response to a wing attack: open the centre while the opponent's pieces are committed to the wing.$ht$,
  how_to_check = $hc$3 positions; correctly finds and executes the central counterattack in each.$hc$,
  puzzles = $pz$"Counterattack in the centre" themed positions.$pz$,
  assignments = $as$Solve three such positions during the week.$as$
where description = 'Counterattacks in the centre against a wing attack.';

update public.items set
  how_to_teach = $ht$Teach the practical habit of continuing to fight in a worse position rather than collapsing emotionally or making the position worse through passivity.$ht$,
  how_to_check = $hc$Coach reviews one of the student's own games where the position was worse, checking whether she kept setting problems rather than giving up.$hc$,
  puzzles = $pz$Not applicable -- assessed through game review.$pz$,
  assignments = $as$Play one home game, aiming to keep fighting if the position turns worse, then bring the scoresheet in.$as$
where description = 'Plays on in a worse position rather than collapsing.';

update public.items set
  how_to_teach = $ht$Teach setting a practical problem when objectively lost: choose the move most likely to cause the opponent difficulty, not necessarily the computer's best move.$ht$,
  how_to_check = $hc$3 positions, objectively lost; finds the most practically challenging try in each.$hc$,
  puzzles = $pz$"Practical chances when lost" themed positions.$pz$,
  assignments = $as$Solve three such positions during the week.$as$
where description = 'Sets a practical problem for the opponent when objectively lost.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, testing defensive resourcefulness across four difficult positions against a live opponent.$ht$,
  how_to_check = $hc$Defends four difficult positions against the coach, holding at least two; results recorded.$hc$,
  puzzles = $pz$Not applicable -- this checkpoint is four live defensive games, not puzzles.$pz$,
  assignments = $as$No assignment -- this is the checkpoint itself.$as$
where description = 'Checkpoint: defends four difficult positions against the coach, holding at least two.';

-- ===================== 4.5 Prophylaxis =====================

update public.items set
  how_to_teach = $ht$Teach the prophylactic habit itself: before every move, ask "what does my opponent want to do?" as a standing question, not just when something looks dangerous.$ht$,
  how_to_check = $hc$Coach observes the student thinking aloud through a full game, asking the question consistently.$hc$,
  puzzles = $pz$Not applicable -- a habit observed through live play.$pz$,
  assignments = $as$Play one home game thinking aloud into a recording or to a parent, asking the question each move.$as$
where description = 'Asks what the opponent wants to do, every move.';

update public.items set
  how_to_teach = $ht$Teach condensing the opponent's plan into one clear sentence, forcing real understanding rather than vague unease.$ht$,
  how_to_check = $hc$5 positions; states the opponent's plan in one sentence in each.$hc$,
  puzzles = $pz$Not a standard labelled category -- use middlegame positions with a clear plan for the side to move against.$pz$,
  assignments = $as$Solve five "name the plan" positions during the week.$as$
where description = 'Names the opponent''s plan in one sentence.';

update public.items set
  how_to_teach = $ht$Teach playing a prophylactic move that stops the identified plan before returning to her own plan, rather than only reacting once the plan has started.$ht$,
  how_to_check = $hc$5 positions; finds the prophylactic move that stops the plan in each.$hc$,
  puzzles = $pz$"Prophylaxis" themed positions.$pz$,
  assignments = $as$Solve five such positions during the week.$as$
where description = 'Plays a move that stops that plan before continuing her own.';

update public.items set
  how_to_teach = $ht$Teach judging when prevention isn't worth it: sometimes stopping a plan costs too much time or weakens the position more than the plan itself would.$ht$,
  how_to_check = $hc$3 positions; explains why prevention is or isn't worth the cost in each.$hc$,
  puzzles = $pz$Not a standard labelled category -- use positions with a costly prophylactic option and a better alternative.$pz$,
  assignments = $as$Not required as separate homework -- reinforced through the explanation.$as$
where description = 'Recognises when prevention costs too much.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, testing prophylactic recognition across five positions with no other clue given.$ht$,
  how_to_check = $hc$Five positions where the best move is prophylactic; finds at least three, score recorded.$hc$,
  puzzles = $pz$A mixed set of five prophylaxis-themed positions.$pz$,
  assignments = $as$No assignment -- this is the checkpoint itself.$as$
where description = 'Checkpoint: five positions where the best move is prophylactic. Finds at least three.';

-- ===================== 4.6 More endgames =====================

update public.items set
  how_to_teach = $ht$Teach the drawing tendency of opposite-coloured bishop endgames: a pawn down, even two, can often be held because the defending bishop can blockade a key square the attacker's bishop can't touch.$ht$,
  how_to_check = $hc$Holds 3 opposite-coloured-bishop positions a pawn down.$hc$,
  puzzles = $pz$Not a solving puzzle -- best practised as live drills from set positions.$pz$,
  assignments = $as$Practise holding three such positions at home.$as$
where description = 'Opposite-coloured bishops: draws a pawn down.';

update public.items set
  how_to_teach = $ht$Teach the contrast with the previous item: once rooks are added to opposite-coloured bishops, the drawing tendency reverses and the position favours the attacker, since rooks can generate threats the bishop can't stop alone.$ht$,
  how_to_check = $hc$Student explains the contrast and demonstrates the attacker's technique in a shown position.$hc$,
  puzzles = $pz$Not applicable -- a conceptual and demonstration task.$pz$,
  assignments = $as$Not required as homework -- reinforced through the demonstration.$as$
where description = 'Opposite-coloured bishops with rooks: knows it favours the attacker.';

update public.items set
  how_to_teach = $ht$Teach converting a bishop-versus-knight edge in an open position, where the bishop's long-range activity dominates.$ht$,
  how_to_check = $hc$3 positions; converts the win with the bishop in each.$hc$,
  puzzles = $pz$"Bishop versus knight" endgame themed positions, open type.$pz$,
  assignments = $as$Practise converting three such positions at home.$as$
where description = 'Bishop versus knight in an open position.';

update public.items set
  how_to_teach = $ht$Teach converting a knight-versus-bishop edge in a closed position, where the knight's ability to reach both colours of square and hop over pawns dominates.$ht$,
  how_to_check = $hc$3 positions; converts the win with the knight in each.$hc$,
  puzzles = $pz$"Knight versus bishop" endgame themed positions, closed type.$pz$,
  assignments = $as$Practise converting three such positions at home.$as$
where description = 'Knight versus bishop in a closed position.';

update public.items set
  how_to_teach = $ht$Teach the queen-versus-pawn-on-the-seventh technique and its exception: the rook pawn and bishop pawn (a- and c/f-files) draw in certain king positions, unlike the other files.$ht$,
  how_to_check = $hc$States the rook- and bishop-pawn exception and demonstrates the winning technique on the other files.$hc$,
  puzzles = $pz$Not a solving puzzle -- best practised as a live drill from set positions.$pz$,
  assignments = $as$Practise the technique and the exception at home until secure.$as$
where description = 'Queen versus pawn on the seventh: knows which files draw.';

update public.items set
  how_to_teach = $ht$Teach the two-bishops-versus-lone-king mate: cornering the king using the bishops' combined diagonals, driving it to a corner matching either bishop's colour.$ht$,
  how_to_check = $hc$Mates inside 25 moves from a set starting position.$hc$,
  puzzles = $pz$Not a solving puzzle -- best practised as a live drill.$pz$,
  assignments = $as$Practise the two-bishop mate at home until reliably under 25 moves.$as$
where description = 'Two bishops versus a lone king.';

update public.items set
  how_to_teach = $ht$Teach recognising when trading down into a won, if technical, endgame is the correct practical choice over keeping pieces on in an unclear middlegame.$ht$,
  how_to_check = $hc$One game where the student trades into a won endgame rather than keeping an unclear middlegame.$hc$,
  puzzles = $pz$Not applicable -- a full-game decision, best tested through play.$pz$,
  assignments = $as$Play one home game looking for a chance to make this trade-down decision.$as$
where description = 'Trades into a won endgame rather than keeping an unclear middlegame.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, testing the endgame techniques from this unit under live conditions against the coach.$ht$,
  how_to_check = $hc$Eight assigned endings played out against the coach; correct result in at least 6, score recorded.$hc$,
  puzzles = $pz$Not applicable -- this checkpoint is eight live games, not puzzles.$pz$,
  assignments = $as$No assignment -- this is the checkpoint itself.$as$
where description = 'Checkpoint: eight assigned endings played out against the coach. Correct result in 6.';

-- ===================== 4.7 Learning from her own games =====================

update public.items set
  how_to_teach = $ht$Teach the habit of reviewing every tournament game within a week of playing it, while the memory and the reasoning behind each move are still fresh.$ht$,
  how_to_check = $hc$A complete review log exists covering every game from one tournament event.$hc$,
  puzzles = $pz$Not applicable -- a record-keeping habit.$pz$,
  assignments = $as$Review every game from the next event within a week of playing it.$as$
where description = 'Reviews every tournament game within a week.';

update public.items set
  how_to_teach = $ht$Teach identifying the single critical moment where a game's result was effectively decided, distinguishing it from the many roughly-equal moves around it.$ht$,
  how_to_check = $hc$3 of the student's own games; the coach agrees with the identified turning point in at least 2.$hc$,
  puzzles = $pz$Not applicable -- an own-game review task.$pz$,
  assignments = $as$Not required as separate homework -- carried out during the review sessions.$as$
where description = 'Identifies the single move where the game turned.';

update public.items set
  how_to_teach = $ht$Teach annotating without engine assistance first -- writing down her own assessment and reasoning -- then checking against the engine afterward to see where her judgement differed.$ht$,
  how_to_check = $hc$Two annotations submitted in both forms: the unaided version and the engine-checked version.$hc$,
  puzzles = $pz$Not applicable -- an own-game review task.$pz$,
  assignments = $as$Annotate two games this way during the week.$as$
where description = 'Annotates without an engine first, then checks.';

update public.items set
  how_to_teach = $ht$Teach keeping a running list of recurring mistakes spotted across game reviews -- patterns, not one-off blunders -- to focus future training.$ht$,
  how_to_check = $hc$The list exists with at least five entries.$hc$,
  puzzles = $pz$Not applicable -- a record-keeping habit.$pz$,
  assignments = $as$Add to the mistake list after every game review until it has at least five entries.$as$
where description = 'Keeps a list of recurring mistakes.';

update public.items set
  how_to_teach = $ht$Teach reviewing the recurring-mistakes list before each tournament event, as a final reminder of what to watch for.$ht$,
  how_to_check = $hc$Coach observes the student reviewing the list before two separate events.$hc$,
  puzzles = $pz$Not applicable -- a habit observed in practice.$pz$,
  assignments = $as$Review the mistake list the day before each of the next two events.$as$
where description = 'Reviews that list before each event.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, and the module's final checkpoint, requiring genuine self-annotation across a full emotional range of results.$ht$,
  how_to_check = $hc$Submits three annotated games -- one win, one draw, one loss -- each with the critical moment clearly marked; the annotations themselves are the evidence.$hc$,
  puzzles = $pz$Not applicable -- this checkpoint is three annotated games, not puzzles.$pz$,
  assignments = $as$No assignment -- this is the checkpoint itself.$as$
where description = 'Checkpoint: submits three annotated games, one win, one draw, one loss, each with the critical moment marked.';
