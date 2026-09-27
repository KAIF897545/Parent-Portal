-- Parent Portal — detailed syllabus content for Module 3 ("Tactics and Structure")
--
-- Continues the syllabus feature: populates how_to_teach/how_to_check/
-- puzzles/assignments for all 57 items of Module 3. Matches by exact
-- description text, same as Modules 1-2.

-- ===================== 3.1 The full tactical vocabulary =====================

update public.items set
  how_to_teach = $ht$Teach deflection as forcing a defending piece away from its post with a check, capture, or threat, so a follow-up move can exploit the square or piece it was guarding. Show one clear example where the deflecting move looks unrelated to the real point until the defender moves.$ht$,
  how_to_check = $hc$8 deflection puzzles; 8/10 or better passes.$hc$,
  puzzles = $pz$"Deflection" themed puzzle sets.$pz$,
  assignments = $as$Solve eight deflection puzzles during the week.$as$
where description = 'Deflection: forcing a defender away.';

update public.items set
  how_to_teach = $ht$Teach the decoy as luring a piece, often the king or a defender, onto a specific square where it becomes vulnerable to a follow-up tactic, usually with a sacrifice. Contrast with deflection: deflection moves a defender away, decoy moves a piece to a bad square.$ht$,
  how_to_check = $hc$8 decoy puzzles; 8/10 or better passes.$hc$,
  puzzles = $pz$"Decoy" themed puzzle sets.$pz$,
  assignments = $as$Solve eight decoy puzzles, noting for each which square the piece was lured to and why it was bad.$as$
where description = 'Decoy: luring a piece onto a bad square.';

update public.items set
  how_to_teach = $ht$Teach the simplest version of "removing the guard": just capture the piece defending a key square or piece, then follow up on the now-undefended target.$ht$,
  how_to_check = $hc$8 puzzles; 8/10 or better passes.$hc$,
  puzzles = $pz$"Remove the defender" themed puzzle sets.$pz$,
  assignments = $as$Solve eight remove-the-defender puzzles during the week.$as$
where description = 'Removing the defender by capture.';

update public.items set
  how_to_teach = $ht$Teach the overload pattern: a piece defending two things at once can only really do one job, so a move that forces a choice wins the other. Show a rook defending both a back-rank mate and a hanging piece as the classic setup.$ht$,
  how_to_check = $hc$8 puzzles; 8/10 or better passes.$hc$,
  puzzles = $pz$"Overloaded piece" themed puzzle sets.$pz$,
  assignments = $as$Solve eight overload puzzles, identifying both jobs the piece was doing in each.$as$
where description = 'Overloaded piece defending two things at once.';

update public.items set
  how_to_teach = $ht$Teach interference: inserting a piece, often sacrificially, onto the line between a defender and what it's defending, cutting the connection. This is the reverse of clearance — blocking a line rather than opening one.$ht$,
  how_to_check = $hc$5 puzzles; 5/10 or better passes (a harder pattern, lower bar).$hc$,
  puzzles = $pz$"Interference" themed puzzle sets — a less common but standard category.$pz$,
  assignments = $as$Solve five interference puzzles during the week.$as$
where description = 'Interference: blocking a defensive line.';

update public.items set
  how_to_teach = $ht$Teach the "in-between move": instead of playing the expected recapture or response immediately, insert a forcing move (check, capture, or threat) first, then follow up. Show a classic example where the automatic recapture would have been a mistake.$ht$,
  how_to_check = $hc$6 puzzles; 6/10 or better passes.$hc$,
  puzzles = $pz$"Zwischenzug" or "in-between move" themed puzzle sets.$pz$,
  assignments = $as$Solve six zwischenzug puzzles, pausing each time before playing the "obvious" move to check for one first.$as$
where description = 'Zwischenzug, the in-between move.';

update public.items set
  how_to_teach = $ht$Teach clearance as the opposite of interference: sacrifice or move a piece out of the way to clear a square or line for another piece to use. Show one example where the sacrificed piece's departure is what makes the tactic work.$ht$,
  how_to_check = $hc$5 puzzles; 5/10 or better passes.$hc$,
  puzzles = $pz$"Clearance sacrifice" themed puzzle sets.$pz$,
  assignments = $as$Solve five clearance puzzles during the week.$as$
where description = 'Clearance sacrifice.';

update public.items set
  how_to_teach = $ht$Teach two related lining-up patterns: a battery (two or more pieces stacked on the same line, attacking together) and an x-ray (a piece attacking through another piece to a target beyond it, even though the line is technically blocked). Show one example of each.$ht$,
  how_to_check = $hc$6 puzzles mixing both patterns; 6/10 or better passes.$hc$,
  puzzles = $pz$"X-ray attack" and "battery" themed puzzle sets.$pz$,
  assignments = $as$Solve six puzzles during the week, noting for each which pattern (x-ray or battery) applies.$as$
where description = 'X-ray and battery.';

update public.items set
  how_to_teach = $ht$Teach the trapped-piece pattern: a piece with no safe squares to move to can be won by attacking it even without an immediate tactic, simply because it has nowhere to go. Show an example of a bishop or knight caught on the edge of the board.$ht$,
  how_to_check = $hc$8 puzzles; 8/10 or better passes.$hc$,
  puzzles = $pz$"Trapped piece" themed puzzle sets.$pz$,
  assignments = $as$Solve eight trapped-piece puzzles during the week.$as$
where description = 'Trapped piece.';

update public.items set
  how_to_teach = $ht$Teach the desperado idea: a piece that's already lost, about to be captured anyway, might as well capture something valuable itself first, since it has nothing left to lose. Show an example where a doomed piece grabs material on its way out.$ht$,
  how_to_check = $hc$5 puzzles; 5/10 or better passes.$hc$,
  puzzles = $pz$"Desperado" themed puzzle sets.$pz$,
  assignments = $as$Solve five desperado puzzles during the week.$as$
where description = 'Desperado.';

update public.items set
  how_to_teach = $ht$Teach the windmill as a repeating discovered-check pattern: a piece moves to give a discovered check, captures or checks again on the way back, and repeats, racking up material or mating. Walk through the classic Torre-Lasker example move by move.$ht$,
  how_to_check = $hc$Solves the classic windmill position, or an equivalent, unprompted.$hc$,
  puzzles = $pz$"Windmill" themed puzzle sets, or the classic named example specifically.$pz$,
  assignments = $as$Practise the classic windmill sequence at home until the repeating pattern is automatic.$as$
where description = 'Windmill.';

update public.items set
  how_to_teach = $ht$This is about synthesis: many real tactics use two of the unit's patterns together, such as a decoy followed by a fork. Show one worked example combining two motifs, then have the student identify both parts.$ht$,
  how_to_check = $hc$5 puzzles, each requiring two combined motifs; solves all 5.$hc$,
  puzzles = $pz$"Combination" or multi-step puzzle sets — look for puzzles with more than one named tactical idea.$pz$,
  assignments = $as$Solve five combination puzzles during the week, naming both motifs used in each.$as$
where description = 'Combines two motifs in one solution.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, testing all twelve motifs together, unlabelled and under time pressure to simulate real-game conditions.$ht$,
  how_to_check = $hc$40 mixed puzzles across all twelve motifs, unlabelled, 90 seconds each. 30/40 or better passes; record the score.$hc$,
  puzzles = $pz$Build the 40-puzzle set from a mix of all previous items in this unit, in random order, unlabelled, timed.$pz$,
  assignments = $as$No assignment — this is the checkpoint itself, run once all twelve motifs feel solid individually.$as$
where description = 'Checkpoint: forty mixed tactics across all twelve motifs, timed at 90 seconds each.';

-- ===================== 3.2 How to calculate =====================

update public.items set
  how_to_teach = $ht$Teach the discipline of listing two to four candidate moves before calculating any of them in depth, rather than diving into the first idea that looks good. Practise by pausing at a position and asking the student to name their candidates out loud before analysing any.$ht$,
  how_to_check = $hc$Observed on 10 positions — student names candidate moves before calculating in each.$hc$,
  puzzles = $pz$Not a solving puzzle — a process habit, best tested through direct observation on sample positions.$pz$,
  assignments = $as$Not required as separate homework — practised directly in session across the ten positions.$as$
where description = 'Lists candidate moves before calculating any.';

update public.items set
  how_to_teach = $ht$Teach the standard "checks, captures, threats" scanning routine as the first pass over any position, before deeper calculation. Practise by asking the student to list all CCT options aloud before choosing a candidate.$ht$,
  how_to_check = $hc$Observed on 10 positions — student lists all checks, captures and threats before choosing a candidate in each.$hc$,
  puzzles = $pz$Not a solving puzzle — a process habit.$pz$,
  assignments = $as$Not required as separate homework — practised directly in session.$as$
where description = 'Examines all checks, captures and threats first.';

update public.items set
  how_to_teach = $ht$Teach calculating a sequence of forcing moves, checks, captures and threats, all the way to a position with no more forcing moves available, rather than stopping partway.$ht$,
  how_to_check = $hc$5 positions; student calculates the full forcing line to a quiet end position in each.$hc$,
  puzzles = $pz$"Calculation" themed puzzle sets with multi-move forcing sequences.$pz$,
  assignments = $as$Solve five multi-move calculation puzzles during the week, writing out the full line before checking.$as$
where description = 'Calculates a forcing line to a quiet end position.';

update public.items set
  how_to_teach = $ht$Teach the follow-up discipline: once the forcing line ends in a quiet position, actually evaluate whether it's good, rather than assuming the sacrifice worked just because it was forcing.$ht$,
  how_to_check = $hc$5 positions; student correctly evaluates the resulting quiet position in each.$hc$,
  puzzles = $pz$Same set as the previous item, but scored on the evaluation rather than just finding the line.$pz$,
  assignments = $as$For five calculation puzzles, write one sentence evaluating the final position, not just the moves.$as$
where description = 'Evaluates that end position rather than stopping at the sacrifice.';

update public.items set
  how_to_teach = $ht$Teach the discipline of assuming the opponent will find their best defence, not the one that makes the student's plan easiest. Have the coach deliberately play the toughest defence in practice lines to train this.$ht$,
  how_to_check = $hc$Coach challenges the student's calculated line with the toughest defence in 5 lines; student's plan still holds or is reasonably adjusted.$hc$,
  puzzles = $pz$Not a standard labelled category — best tested through coach-challenged calculation lines.$pz$,
  assignments = $as$Not required as separate homework — practised directly in session.$as$
where description = 'Considers the opponent''s best reply, not the hoped-for one.';

update public.items set
  how_to_teach = $ht$Teach visualisation without moving pieces: work up from one move ahead to three, calculating a forcing sequence purely in the head before confirming on the board.$ht$,
  how_to_check = $hc$3 positions; calculates a three-move forcing sequence blindfold correctly in each.$hc$,
  puzzles = $pz$"Blindfold calculation" drills — use existing tactics positions but solved without touching the board.$pz$,
  assignments = $as$Practise blindfold calculation on three positions during the week, checking on the board afterward.$as$
where description = 'Calculates a three-move forcing sequence blindfold.';

update public.items set
  how_to_teach = $ht$Teach the balance between calculating far enough and calculating forever: once the position is clearly good, or clearly the best practical try, stop and play rather than searching for a perfect line.$ht$,
  how_to_check = $hc$3 positions; student explains when they'd stop calculating and why.$hc$,
  puzzles = $pz$Not applicable as solving puzzles — a judgement task.$pz$,
  assignments = $as$Not required as separate homework — reinforced through the three worked examples.$as$
where description = 'Knows when to stop calculating and make a judgement.';

update public.items set
  how_to_teach = $ht$Teach the practical habit of jotting candidate moves on paper, or a scrap sheet, during a real long-time-control game, to keep calculation organised on critical moves.$ht$,
  how_to_check = $hc$One real game where the student used this habit at least once on a critical move.$hc$,
  puzzles = $pz$Not applicable — a real-game habit.$pz$,
  assignments = $as$Play one long home game trying this habit on at least one critical moment, then bring the notes in.$as$
where description = 'Records candidate moves on paper during a long game.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, combining candidate-move listing, CCT scanning, and calculation discipline into one live, narrated test.$ht$,
  how_to_check = $hc$Coach verifies candidate moves were listed before lines were calculated, across five unseen positions. Passes in at least four; coach record.$hc$,
  puzzles = $pz$Not applicable — this checkpoint is a live thinking-aloud exercise, not solved puzzles.$pz$,
  assignments = $as$No assignment — this is the checkpoint itself.$as$
where description = 'Checkpoint: thinks aloud through five unseen positions. Coach verifies candidates listed before lines calculated.';

-- ===================== 3.3 Pawn structure =====================

update public.items set
  how_to_teach = $ht$Teach the standard vocabulary: isolated (no friendly pawns on adjacent files), doubled (two on the same file), backward (behind its neighbours and can't be defended by another pawn), passed (no enemy pawns can stop it reaching promotion), connected (mutually defending pawns), and hanging (two adjacent pawns with no others nearby, strong but vulnerable). Label examples of each on the board.$ht$,
  how_to_check = $hc$5 positions; student correctly labels all pawn types present in each.$hc$,
  puzzles = $pz$Not a solving puzzle — a labelling and identification task on sample positions.$pz$,
  assignments = $as$Given five positions during the week (own choosing or from a book), label every pawn type present.$as$
where description = 'Identifies isolated, doubled, backward, passed, connected and hanging pawns.';

update public.items set
  how_to_teach = $ht$Teach the classic isolated queen's pawn trade-off: it gives open lines and piece activity for the side that has it, a strength, but becomes a long-term weak target once pieces are traded off, a weakness. Show a middlegame example and an endgame example of the same structure.$ht$,
  how_to_check = $hc$Student names the strength and the weakness in their own words, for both sides.$hc$,
  puzzles = $pz$Not applicable — a conceptual explanation task.$pz$,
  assignments = $as$Not required as homework — reinforced through the two worked examples.$as$
where description = 'Names the strength and the weakness of an isolated queen''s pawn.';

update public.items set
  how_to_teach = $ht$Teach the standard plan against an IQP: blockade the square directly in front of it with a piece, ideally a knight, then trade off the opponent's active pieces to reach an endgame where the pawn is just weak.$ht$,
  how_to_check = $hc$One game from a set IQP position, playing the blockading side; converts or holds a clear advantage.$hc$,
  puzzles = $pz$Not applicable — a full-game plan, best tested through play.$pz$,
  assignments = $as$Play one home game from a set IQP position, applying the blockade-and-trade plan.$as$
where description = 'Plays against an IQP: blockade the square, trade pieces.';

update public.items set
  how_to_teach = $ht$Teach the opposing plan: use the piece activity the IQP grants, avoid unnecessary trades, and look for the d4-d5 (or equivalent) pawn break to open the position further while pieces are still on.$ht$,
  how_to_check = $hc$One game from a set IQP position, playing the IQP side; makes good use of activity and looks for the break.$hc$,
  puzzles = $pz$Not applicable — a full-game plan, best tested through play.$pz$,
  assignments = $as$Play one home game from the same set IQP position, this time playing the IQP side.$as$
where description = 'Plays with an IQP: activity, the d4-d5 break.';

update public.items set
  how_to_teach = $ht$Teach the standard technique for turning a pawn majority, such as 3 versus 2 on one wing, into a passed pawn: identify which pawn to advance first and in what order to avoid getting stuck.$ht$,
  how_to_check = $hc$5 positions with a pawn majority; correctly creates a passed pawn in each.$hc$,
  puzzles = $pz$"Pawn majority" themed endgame positions.$pz$,
  assignments = $as$Solve five pawn-majority positions during the week.$as$
where description = 'Creates a passed pawn from a majority.';

update public.items set
  how_to_teach = $ht$Teach the endgame technique of using a passed pawn far from the action to draw the enemy king away, winning material or tempo elsewhere while it's distracted.$ht$,
  how_to_check = $hc$3 positions; correctly uses the outside passer as a decoy in each.$hc$,
  puzzles = $pz$"Outside passed pawn" themed endgame positions.$pz$,
  assignments = $as$Solve three outside-passed-pawn positions during the week.$as$
where description = 'Uses the outside passed pawn as a decoy.';

update public.items set
  how_to_teach = $ht$Teach pawn-break recognition: given a structure, identify which pawn lever (break) is available to each side to open lines, and roughly when it's ready to be played.$ht$,
  how_to_check = $hc$5 positions; correctly identifies the available break(s) for both sides in each.$hc$,
  puzzles = $pz$Not a standard labelled category — build or use structural middlegame positions and ask this specific question.$pz$,
  assignments = $as$Solve five "find the break" positions during the week.$as$
where description = 'Identifies which pawn break is available to each side.';

update public.items set
  how_to_teach = $ht$Teach the trade-off awareness: an attacking pawn advance can create a permanent weakness behind it, so check what's being given up before pushing.$ht$,
  how_to_check = $hc$Coach reviews one of the student's own games, checking whether pawn advances during an attack created avoidable weaknesses.$hc$,
  puzzles = $pz$Not applicable — assessed through game review.$pz$,
  assignments = $as$Play one home game consciously weighing this trade-off before any attacking pawn push, then bring the scoresheet in.$as$
where description = 'Avoids creating a weakness while attacking.';

update public.items set
  how_to_teach = $ht$Teach the recognition of a closed, locked pawn centre and the standard response: play on the wing where you have more space or a ready-made plan, since central breaks are slow to arrive.$ht$,
  how_to_check = $hc$3 positions with a closed centre; correctly identifies the right wing to play on in each.$hc$,
  puzzles = $pz$Not a standard labelled category — use structural middlegame positions with a locked centre.$pz$,
  assignments = $as$Not required as separate homework — reinforced through the three worked examples.$as$
where description = 'Recognises a closed centre and plays on the correct wing.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, combining structural recognition and planning across six different pawn structures presented together.$ht$,
  how_to_check = $hc$Given six structures, states the correct plan for both sides in writing. 5/6 judged sound by the coach.$hc$,
  puzzles = $pz$Build the six-structure test set from a mix of IQP, majority, closed-centre and break-available positions covered in this unit.$pz$,
  assignments = $as$No assignment — this is the checkpoint itself.$as$
where description = 'Checkpoint: given six structures, states the correct plan for both sides in writing.';

-- ===================== 3.4 Pieces and squares =====================

update public.items set
  how_to_teach = $ht$Teach weak-square recognition: a square that can never be defended by a pawn, because the pawns that would guard it are gone or have advanced past it, is a permanent weakness the opponent can target. Show an example of a classic weak square in front of a fianchetto or after a pawn advance.$ht$,
  how_to_check = $hc$5 positions; correctly identifies the weak square(s) in each.$hc$,
  puzzles = $pz$Not a standard labelled category — use structural middlegame positions and ask this specific question.$pz$,
  assignments = $as$Solve five "find the weak square" positions during the week.$as$
where description = 'Identifies a weak square in the opponent''s camp.';

update public.items set
  how_to_teach = $ht$Teach the outpost technique: place a knight on a weak square, from the previous item, that's defended by a pawn, so it can't easily be dislodged, and use it as a long-term strongpoint.$ht$,
  how_to_check = $hc$One game where the student establishes and maintains a knight outpost.$hc$,
  puzzles = $pz$Not applicable — a full-game technique, best tested through play.$pz$,
  assignments = $as$Play one home game specifically looking for a chance to establish a knight outpost.$as$
where description = 'Establishes a knight on an outpost, supported by a pawn.';

update public.items set
  how_to_teach = $ht$Teach deliberate file-opening: choose a pawn trade or advance specifically to open a file for a rook, rather than only reacting to files that open naturally.$ht$,
  how_to_check = $hc$One game where the student deliberately opens a file and uses it.$hc$,
  puzzles = $pz$Not applicable — a full-game technique.$pz$,
  assignments = $as$Play one home game consciously looking for a file to open, then bring the scoresheet in.$as$
where description = 'Opens a file deliberately and occupies it.';

update public.items set
  how_to_teach = $ht$Teach doubling rooks, or rook and queen, on an open or half-open file to multiply pressure down it, and the correct order to avoid getting the rooks tangled.$ht$,
  how_to_check = $hc$One game where the student doubles rooks on a file.$hc$,
  puzzles = $pz$Not applicable — a full-game technique.$pz$,
  assignments = $as$Play one home game looking for a chance to double rooks, then bring the scoresheet in.$as$
where description = 'Doubles rooks on a file.';

update public.items set
  how_to_teach = $ht$Teach the value of a rook on the seventh, or second, rank: it attacks pawns still on their starting squares and can restrict the enemy king, often worth more than its usual activity would suggest.$ht$,
  how_to_check = $hc$Student demonstrates the technique and explains its value on the board.$hc$,
  puzzles = $pz$Not applicable — a conceptual and demonstration task.$pz$,
  assignments = $as$Not required as homework — reinforced through the demonstration.$as$
where description = 'Places a rook on the seventh and explains the value.';

update public.items set
  how_to_teach = $ht$Teach the good-bishop/bad-bishop distinction: a bishop blocked by its own pawns, especially on its own colour, is bad; one with open diagonals is good. Show contrasting examples.$ht$,
  how_to_check = $hc$5 positions; correctly judges good versus bad bishop in each.$hc$,
  puzzles = $pz$Not a standard labelled category — use structural positions and ask this specific question.$pz$,
  assignments = $as$Solve five "good bishop or bad bishop?" positions during the week.$as$
where description = 'Distinguishes a good bishop from a bad one.';

update public.items set
  how_to_teach = $ht$Building on the good-bishop/bad-bishop judgement, teach when it's correct to trade a bad bishop for the opponent's good knight, or good bishop, even though bishops are nominally worth the same as knights.$ht$,
  how_to_check = $hc$3 positions; correctly identifies when this trade is the right choice.$hc$,
  puzzles = $pz$Not a standard labelled category — use structural positions with this specific decision available.$pz$,
  assignments = $as$Not required as separate homework — folds into general game play.$as$
where description = 'Trades a bad bishop for a good knight when correct.';

update public.items set
  how_to_teach = $ht$Teach the value of keeping both bishops, the "bishop pair," in an open position, where their combined diagonal coverage is especially strong, and when it's worth avoiding a trade to keep them.$ht$,
  how_to_check = $hc$Student explains the value and demonstrates avoiding an unfavourable trade in a shown position.$hc$,
  puzzles = $pz$Not applicable — a conceptual and demonstration task.$pz$,
  assignments = $as$Not required as homework — reinforced through the demonstration.$as$
where description = 'Preserves the bishop pair in an open position.';

update public.items set
  how_to_teach = $ht$Teach knight rerouting: sometimes a knight's best square isn't reachable in one move, so plan a short multi-move journey, often through an awkward-looking square, to get it there.$ht$,
  how_to_check = $hc$One game where the student reroutes a knight over three moves to a genuinely better square.$hc$,
  puzzles = $pz$Not applicable — a full-game technique, best tested through play.$pz$,
  assignments = $as$Play one home game looking for a chance to reroute a poorly placed knight.$as$
where description = 'Reroutes a knight over three moves to a better square.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, bringing together weak squares, outposts, files, bishops, and knight rerouting into a single written annotation.$ht$,
  how_to_check = $hc$The written annotation itself, identifying and judging four piece-placement decisions from a real game.$hc$,
  puzzles = $pz$Not applicable — this checkpoint is a written annotation, not puzzles.$pz$,
  assignments = $as$No assignment — this is the checkpoint itself.$as$
where description = 'Checkpoint: annotates one of her own games identifying four piece-placement decisions and judging each.';

-- ===================== 3.5 Rook endings that decide club games =====================

update public.items set
  how_to_teach = $ht$Teach the "building the bridge" technique move by move: use the rook to shield the king from checks so it can escort the pawn to promotion. Walk through it slowly from both sides of the board, since the queenside and kingside rook-pawn versions differ slightly.$ht$,
  how_to_check = $hc$Converts the Lucena position from both sides of the board.$hc$,
  puzzles = $pz$Not a solving puzzle — best practised as a live drill from the set position.$pz$,
  assignments = $as$Practise the Lucena technique from both sides of the board at home until automatic.$as$
where description = 'Lucena position: builds the bridge.';

update public.items set
  how_to_teach = $ht$Teach the third-rank defence: keep the rook on the third rank to stop the enemy king advancing, then switch to checking from behind once the pawn advances to the sixth rank.$ht$,
  how_to_check = $hc$Holds the Philidor position 3 times against the coach.$hc$,
  puzzles = $pz$Not a solving puzzle — best practised as a live drill.$pz$,
  assignments = $as$Practise holding the Philidor position three times at home, against a parent, sibling, or app.$as$
where description = 'Philidor position: third-rank defence.';

update public.items set
  how_to_teach = $ht$Teach the general principle "rook belongs behind the passed pawn" — whether it's your own pawn, supporting its advance, or the opponent's, attacking it from behind as it advances. Show both cases.$ht$,
  how_to_check = $hc$Student explains and demonstrates the principle for both cases on the board.$hc$,
  puzzles = $pz$Not applicable — a conceptual and demonstration task.$pz$,
  assignments = $as$Not required as homework — reinforced through the demonstration.$as$
where description = 'Rook behind the passed pawn, hers and the opponent''s.';

update public.items set
  how_to_teach = $ht$Teach using a rook to cut the enemy king off along a file, not just a rank, keeping it away from the action while a pawn advances or another plan proceeds.$ht$,
  how_to_check = $hc$3 positions; correctly cuts off the king in each.$hc$,
  puzzles = $pz$"Rook endgame" positions specifically requiring a file cut-off.$pz$,
  assignments = $as$Solve three cut-off positions during the week.$as$
where description = 'Cuts the enemy king along a file.';

update public.items set
  how_to_teach = $ht$Teach the general principle that an active rook, giving checks, attacking pawns, defends better than a passive one tied down to guarding a single weakness, even in an objectively worse position.$ht$,
  how_to_check = $hc$3 positions; chooses active rook play over passive defence in each, with a sound result.$hc$,
  puzzles = $pz$"Rook endgame" defensive positions contrasting active versus passive choices.$pz$,
  assignments = $as$Solve three positions during the week, explaining why the active choice is better in each.$as$
where description = 'Active rook defence rather than passive.';

update public.items set
  how_to_teach = $ht$Teach the two named defensive setups for rook endings with a pawn one file away from a rook's pawn: short-side (rook in front, king on the short side) and long-side (rook checking from the long side). Show both with the standard named positions.$ht$,
  how_to_check = $hc$Demonstrates both defences correctly from set positions.$hc$,
  puzzles = $pz$Not a solving puzzle — best practised as live drills from set positions.$pz$,
  assignments = $as$Practise both defences from set positions at home.$as$
where description = 'Knows the short-side and long-side defence.';

update public.items set
  how_to_teach = $ht$Teach the standard winning technique for this material edge: advance the extra pawn's side carefully, use the rook actively, and avoid unnecessary pawn trades that simplify toward a draw.$ht$,
  how_to_check = $hc$3 positions; converts the win in each.$hc$,
  puzzles = $pz$"Rook and pawns endgame" positions with this exact material balance.$pz$,
  assignments = $as$Practise converting three such positions at home.$as$
where description = 'Converts rook and two pawns versus rook and one.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, testing the two most important rook-ending techniques from both the winning and defending side, with no hints.$ht$,
  how_to_check = $hc$Plays Lucena and Philidor against the coach, both colours, four games total, no hints. All four correct, coach signature.$hc$,
  puzzles = $pz$Not applicable — this checkpoint is four live games, not puzzles.$pz$,
  assignments = $as$No assignment — this is the checkpoint itself.$as$
where description = 'Checkpoint: plays Lucena and Philidor against the coach, both colours, no hints.';

-- ===================== 3.6 A repertoire as White =====================

update public.items set
  how_to_teach = $ht$Teach the value of committing to one opening move as White for a sustained period, to build real experience and pattern recognition rather than trying something new every game.$ht$,
  how_to_check = $hc$All scoresheets from a month of games show the same first move.$hc$,
  puzzles = $pz$Not applicable — a real-game commitment.$pz$,
  assignments = $as$Play games over the month using the chosen first move every time; no separate puzzle assignment.$as$
where description = 'Plays one first move consistently for a month.';

update public.items set
  how_to_teach = $ht$Teach the main line of the chosen opening to around move eight, explaining the purpose of each move rather than just memorising it, so the student understands what to do if the opponent deviates.$ht$,
  how_to_check = $hc$Student explains each move's purpose aloud through the main line.$hc$,
  puzzles = $pz$Not applicable — an opening-knowledge task.$pz$,
  assignments = $as$Not required as separate homework — reinforced through repeated play and review.$as$
where description = 'Knows the main line to move eight and the purpose of each move.';

update public.items set
  how_to_teach = $ht$Identify the two defences the student meets most often in real games, from their own scoresheets, and prepare a specific reply to each.$ht$,
  how_to_check = $hc$Demonstrates the reply to both defences over the board.$hc$,
  puzzles = $pz$Not applicable — an opening-preparation task.$pz$,
  assignments = $as$Not required as separate homework — reinforced through the demonstration.$as$
where description = 'Has a reply to the two most common defences she meets.';

update public.items set
  how_to_teach = $ht$Teach one common trap within the chosen line, either one the student could fall into or one they could spring on an unwary opponent, and how to recognise and avoid the dangerous version.$ht$,
  how_to_check = $hc$Student explains the trap and how to avoid it.$hc$,
  puzzles = $pz$Not applicable — a specific opening-knowledge item.$pz$,
  assignments = $as$Not required as separate homework.$as$
where description = 'Knows one trap in the line and how to avoid falling into it.';

update public.items set
  how_to_teach = $ht$Teach general opening principles as the fallback once the opponent leaves known theory: develop, control the centre, get the king safe, rather than trying to remember a line that no longer applies.$ht$,
  how_to_check = $hc$Coach sets three off-book positions from the repertoire; student plays sensibly, by general principles, in each.$hc$,
  puzzles = $pz$Not a standard labelled category — build custom off-book test positions from the student's own repertoire.$pz$,
  assignments = $as$Not required as separate homework — tested directly in session.$as$
where description = 'Plays sensibly when the opponent leaves book on move five.';

update public.items set
  how_to_teach = $ht$Teach the habit of adding any genuinely new line encountered in a real game to the opening file after each event, keeping the repertoire current and complete.$ht$,
  how_to_check = $hc$The file shows at least three new additions after real events.$hc$,
  puzzles = $pz$Not applicable — a record-keeping habit.$pz$,
  assignments = $as$No separate assignment — apply the habit after every event played.$as$
where description = 'Records a new line met and adds it to her file after each event.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint and the module's final checkpoint, testing the whole repertoire under real conditions with no notes.$ht$,
  how_to_check = $hc$Plays the repertoire in five consecutive games, no notes, reaching a playable middlegame in each. Passes if achieved in at least four; the five scoresheets as evidence.$hc$,
  puzzles = $pz$Not applicable — this checkpoint is five real games, not puzzles.$pz$,
  assignments = $as$No assignment — this is the checkpoint itself.$as$
where description = 'Checkpoint: plays the repertoire in five consecutive games, no notes, reaching a playable middlegame.';
