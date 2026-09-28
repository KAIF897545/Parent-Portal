-- ===================== 5.1 Evaluation =====================

update public.items set
  how_to_teach = $ht$Teach a structured evaluation method covering all five factors -- material, king safety, structure, activity, space -- so the student assesses a position systematically rather than by feel alone.$ht$,
  how_to_check = $hc$5 positions; produces a written evaluation covering all five factors in each.$hc$,
  puzzles = $pz$Not a standard labelled category -- use varied middlegame positions for structured evaluation practice.$pz$,
  assignments = $as$Write evaluations for five positions during the week, covering all five factors in each.$as$
where description = 'Evaluates a position across material, king safety, structure, activity and space.';

update public.items set
  how_to_teach = $ht$Teach the distinction between static advantages (structural, permanent, e.g. pawn weaknesses) and dynamic advantages (temporary, e.g. lead in development, king safety window) that must be used before they fade.$ht$,
  how_to_check = $hc$Explains the distinction with two contrasting examples, one static and one dynamic.$hc$,
  puzzles = $pz$Not applicable -- a conceptual explanation task.$pz$,
  assignments = $as$Not required as separate homework -- reinforced through the explanation.$as$
where description = 'Distinguishes static from dynamic advantages.';

update public.items set
  how_to_teach = $ht$Teach recognising when a dynamic advantage is time-limited and must be converted into something permanent (material, structural, or a decisive attack) before the opponent consolidates.$ht$,
  how_to_check = $hc$3 positions; correctly identifies that the dynamic advantage must be converted now, and finds the way to do it.$hc$,
  puzzles = $pz$Not a standard labelled category -- use positions with a fleeting dynamic edge.$pz$,
  assignments = $as$Solve three such positions during the week.$as$
where description = 'Knows when a dynamic advantage must be converted before it evaporates.';

update public.items set
  how_to_teach = $ht$Teach judging compensation for sacrificed material: weigh the concrete factors -- activity, king safety, structure -- gained against the material given up, rather than assuming any sacrifice must be either clearly sound or clearly unsound.$ht$,
  how_to_check = $hc$5 positions; correctly judges whether the compensation is sufficient in each.$hc$,
  puzzles = $pz$"Judge the compensation" themed positions.$pz$,
  assignments = $as$Solve five such positions during the week.$as$
where description = 'Judges compensation for sacrificed material.';

update public.items set
  how_to_teach = $ht$Teach healthy skepticism toward engine evaluations: work through a position where the engine's number doesn't match human practical chances, and explain why.$ht$,
  how_to_check = $hc$One written example where the student disagrees with an engine evaluation and explains her reasoning.$hc$,
  puzzles = $pz$Not applicable -- a written reasoning task.$pz$,
  assignments = $as$Not required as separate homework -- produced during the exercise.$as$
where description = 'Disagrees with an engine evaluation and explains her reasoning.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, testing evaluation skill on positions the student hasn't seen before.$ht$,
  how_to_check = $hc$Written evaluations of five unseen positions; the coach judges at least four as sound.$hc$,
  puzzles = $pz$Not applicable -- this checkpoint is five written evaluations, not puzzles.$pz$,
  assignments = $as$No assignment -- this is the checkpoint itself.$as$
where description = 'Checkpoint: written evaluations of five unseen positions. Coach judges four as sound.';

-- ===================== 5.2 Sacrifices and imbalance =====================

update public.items set
  how_to_teach = $ht$Teach the positional exchange sacrifice (rook for bishop or knight) to gain a strong square or favourable structure, evaluating the long-term positional gain rather than the immediate material loss.$ht$,
  how_to_check = $hc$3 positions; correctly identifies and justifies the exchange sacrifice in each.$hc$,
  puzzles = $pz$"Exchange sacrifice" themed positions.$pz$,
  assignments = $as$Solve three such positions during the week.$as$
where description = 'Positional exchange sacrifice for a square or a structure.';

update public.items set
  how_to_teach = $ht$Teach sacrificing a pawn purely for development or initiative -- faster piece activity and tempo rather than any direct attack.$ht$,
  how_to_check = $hc$3 positions; correctly identifies and justifies the pawn sacrifice in each.$hc$,
  puzzles = $pz$"Gambit" / development-sacrifice themed positions.$pz$,
  assignments = $as$Solve three such positions during the week.$as$
where description = 'Pawn sacrifice for development or initiative.';

update public.items set
  how_to_teach = $ht$Teach the practical handling of rook versus two minor pieces from both sides -- the minor pieces' coordination potential against the rook's open-file activity.$ht$,
  how_to_check = $hc$One game from a set rook-versus-two-minors position, playing each side once.$hc$,
  puzzles = $pz$Not applicable -- a full-game material imbalance, best tested through play.$pz$,
  assignments = $as$Play one home game from the same set position, from each side.$as$
where description = 'Playing rook against two minor pieces.';

update public.items set
  how_to_teach = $ht$Teach the practical handling of queen versus rook, bishop and pawn -- a specific, well-known material imbalance with its own typical plans for both sides.$ht$,
  how_to_check = $hc$One game from a set queen-versus-rook-bishop-pawn position.$hc$,
  puzzles = $pz$Not applicable -- a full-game material imbalance, best tested through play.$pz$,
  assignments = $as$Play one home game from the same set position.$as$
where description = 'Playing queen against rook, bishop and pawn.';

update public.items set
  how_to_teach = $ht$Teach the practical distinction between a sacrifice that's objectively sound and one that's merely a good practical try -- creating problems the opponent is likely to fail to solve at the board.$ht$,
  how_to_check = $hc$Explains the distinction with a real example from her own games or a known game.$hc$,
  puzzles = $pz$Not applicable -- a written/verbal reasoning task.$pz$,
  assignments = $as$Not required as separate homework -- reinforced through the explanation.$as$
where description = 'Knows when an unclear sacrifice is a practical weapon rather than a sound one.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, testing comfort with material imbalance across four set positions against a live opponent.$ht$,
  how_to_check = $hc$Plays four imbalanced positions against the coach from both sides; results recorded.$hc$,
  puzzles = $pz$Not applicable -- this checkpoint is four live games, not puzzles.$pz$,
  assignments = $as$No assignment -- this is the checkpoint itself.$as$
where description = 'Checkpoint: plays four imbalanced positions against the coach from both sides.';

-- ===================== 5.3 Complex endgames =====================

update public.items set
  how_to_teach = $ht$Teach rook endings with equal pawns all on one side (rook and three versus rook and three): the drawing tendency and the specific technical tries each side has to unbalance it.$ht$,
  how_to_check = $hc$3 positions; correctly navigates the position, attacker or defender as required, in each.$hc$,
  puzzles = $pz$"Rook endgame" themed positions with equal same-side pawns.$pz$,
  assignments = $as$Solve three such positions during the week.$as$
where description = 'Rook and three pawns versus rook and three, same side.';

update public.items set
  how_to_teach = $ht$Teach rook endings with pawns on both wings, where the extra width of the board gives the stronger side more winning chances than a same-side structure.$ht$,
  how_to_check = $hc$3 positions; correctly converts or defends as required in each.$hc$,
  puzzles = $pz$"Rook endgame" themed positions with pawns on both wings.$pz$,
  assignments = $as$Solve three such positions during the week.$as$
where description = 'Rook endings with pawns on both wings.';

update public.items set
  how_to_teach = $ht$Teach fortress recognition: a position where the defender can construct an impenetrable barrier despite being materially worse, and how to recognise, build, or break one.$ht$,
  how_to_check = $hc$Builds two fortress positions successfully and breaks one set up by the coach.$hc$,
  puzzles = $pz$"Fortress" themed endgame positions.$pz$,
  assignments = $as$Practise building two fortress positions and breaking one at home.$as$
where description = 'Fortress recognition and construction.';

update public.items set
  how_to_teach = $ht$Teach creating zugzwang deliberately: manoeuvring so the opponent runs out of useful moves and must weaken their position.$ht$,
  how_to_check = $hc$5 positions; correctly creates zugzwang in each.$hc$,
  puzzles = $pz$"Zugzwang" themed endgame positions.$pz$,
  assignments = $as$Solve five such positions during the week.$as$
where description = 'Zugzwang: creates it deliberately.';

update public.items set
  how_to_teach = $ht$Teach triangulation: losing a tempo with the king to force the opponent into the move they didn't want to make, most commonly in king and pawn endings.$ht$,
  how_to_check = $hc$Demonstrates triangulation correctly in 2 positions.$hc$,
  puzzles = $pz$Not a solving puzzle -- best practised as live drills from set positions.$pz$,
  assignments = $as$Practise triangulation from two set positions at home.$as$
where description = 'Triangulation.';

update public.items set
  how_to_teach = $ht$Teach choosing which endgame to steer toward from a middlegame, when several trades are available, based on which resulting structure favours the student.$ht$,
  how_to_check = $hc$5 positions; correctly chooses which endgame to transition into in each.$hc$,
  puzzles = $pz$"Choose the transition" themed positions from a middlegame with multiple trade options.$pz$,
  assignments = $as$Solve five such positions during the week.$as$
where description = 'Transitions: chooses which endgame to enter from a middlegame.';

update public.items set
  how_to_teach = $ht$Teach the practical grind of converting a one-pawn advantage against a resisting, well-defended opponent, rather than only against a passive one.$ht$,
  how_to_check = $hc$3 games against the coach, defending stubbornly; converts the advantage in each.$hc$,
  puzzles = $pz$Not applicable -- a full-game technique, best tested through live play.$pz$,
  assignments = $as$Not required as separate homework -- carried out in the three coach games.$as$
where description = 'Converts a one-pawn advantage against real resistance.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, testing the full range of complex endgame techniques from this unit under live conditions.$ht$,
  how_to_check = $hc$Six assigned endings played out; correct result in at least five, score recorded.$hc$,
  puzzles = $pz$Not applicable -- this checkpoint is six live games, not puzzles.$pz$,
  assignments = $as$No assignment -- this is the checkpoint itself.$as$
where description = 'Checkpoint: six assigned endings, played to the correct result in at least five.';

-- ===================== 5.4 Clock and nerves =====================

update public.items set
  how_to_teach = $ht$Teach planning time budgets across a long time control before the round starts -- roughly how much time to allow the opening, middlegame, and time-trouble buffer.$ht$,
  how_to_check = $hc$A written time-use plan exists for one tournament event.$hc$,
  puzzles = $pz$Not applicable -- a planning task.$pz$,
  assignments = $as$Write a time-use plan before the next tournament event.$as$
where description = 'Plans time use across a long control before the round.';

update public.items set
  how_to_teach = $ht$Teach allocating thinking time to genuinely critical moves rather than spending it evenly, including on obvious recaptures or forced moves.$ht$,
  how_to_check = $hc$Coach reviews clock times recorded on a scoresheet, checking time was spent on critical moments rather than obvious ones.$hc$,
  puzzles = $pz$Not applicable -- assessed through scoresheet and clock review.$pz$,
  assignments = $as$Bring a scoresheet with clock times noted from the next game played.$as$
where description = 'Spends time on critical moves, not obvious recaptures.';

update public.items set
  how_to_teach = $ht$Teach practical increment-endgame technique: using the increment to avoid flagging, including simplified or repetitive move sequences when genuinely low on time.$ht$,
  how_to_check = $hc$Three games reaching an increment endgame; doesn't flag in any.$hc$,
  puzzles = $pz$Not applicable -- a full-game clock-management skill, best tested through play.$pz$,
  assignments = $as$Play three home games with increment time control, aiming to reach the ending without flagging.$as$
where description = 'Plays an increment endgame without flagging.';

update public.items set
  how_to_teach = $ht$Teach recovering emotionally and practically from a loss before the next round -- a short routine to reset rather than carrying the loss into the next game.$ht$,
  how_to_check = $hc$Coach observes the student's recovery routine and demeanour across a tournament event after a loss.$hc$,
  puzzles = $pz$Not applicable -- a habit observed in practice.$pz$,
  assignments = $as$Not required as separate homework -- observed during the next event.$as$
where description = 'Recovers from a loss before the next round.';

update public.items set
  how_to_teach = $ht$Teach establishing a pre-round routine covering sleep, food, arrival time, and warm-up, to arrive at the board in the best possible state.$ht$,
  how_to_check = $hc$A written routine exists and is followed for one tournament event.$hc$,
  puzzles = $pz$Not applicable -- a routine-building task.$pz$,
  assignments = $as$Write and follow a pre-round routine for the next tournament event.$as$
where description = 'Keeps a pre-round routine: sleep, food, arrival, warm-up.';

update public.items set
  how_to_teach = $ht$Teach deciding whether to offer, accept, or decline a draw based on tournament standings and objective needs, not mood or fatigue in the moment.$ht$,
  how_to_check = $hc$Explains two real draw decisions and the standings-based reasoning behind each.$hc$,
  puzzles = $pz$Not applicable -- a reasoning and reflection task.$pz$,
  assignments = $as$Not required as separate homework -- reinforced through the explanation.$as$
where description = 'Decides draws on standings, not mood.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, and requires applying all six items from this unit across a genuine full-length tournament weekend.$ht$,
  how_to_check = $hc$Completes a full weekend tournament and submits a written self-review against all six items from this unit.$hc$,
  puzzles = $pz$Not applicable -- this checkpoint is a tournament weekend plus self-review, not puzzles.$pz$,
  assignments = $as$No assignment -- this is the checkpoint itself.$as$
where description = 'Checkpoint: completes a full weekend tournament and submits a written self-review against these six items.';

-- ===================== 5.5 The rules in full =====================

update public.items set
  how_to_teach = $ht$Teach the illegal-move rule and its penalties under the FIDE Laws of Chess -- what counts as an illegal move and the time penalty or other consequence.$ht$,
  how_to_check = $hc$States the rule and its penalties correctly.$hc$,
  puzzles = $pz$Not applicable -- a rules-knowledge item.$pz$,
  assignments = $as$Not required as separate homework.$as$
where description = 'Knows the illegal-move rule and its penalties.';

update public.items set
  how_to_teach = $ht$Teach the correct procedure for claiming a threefold repetition: stopping the clock, writing the claim, and calling the arbiter rather than just announcing it.$ht$,
  how_to_check = $hc$Performs a correct mock claim from a set repeated position.$hc$,
  puzzles = $pz$Not a solving puzzle -- best practised as a live drill.$pz$,
  assignments = $as$Not required as separate homework -- reinforced through the drill.$as$
where description = 'Claims a threefold repetition correctly, with the arbiter.';

update public.items set
  how_to_teach = $ht$Teach the correct procedure for claiming the fifty-move rule, distinct from threefold repetition, including counting the moves correctly.$ht$,
  how_to_check = $hc$Performs a correct mock claim from a set position.$hc$,
  puzzles = $pz$Not a solving puzzle -- best practised as a live drill.$pz$,
  assignments = $as$Not required as separate homework -- reinforced through the drill.$as$
where description = 'Claims the fifty-move rule correctly.';

update public.items set
  how_to_teach = $ht$Teach the tournament rules on phones, written notes, and leaving the playing area during a game.$ht$,
  how_to_check = $hc$States the rules correctly.$hc$,
  puzzles = $pz$Not applicable -- a rules-knowledge item.$pz$,
  assignments = $as$Not required as separate homework.$as$
where description = 'Knows the rules on phones, notes and leaving the playing area.';

update public.items set
  how_to_teach = $ht$Teach the rule for a flag fall when the opponent has insufficient mating material -- the game is drawn rather than lost on time.$ht$,
  how_to_check = $hc$States the rule correctly.$hc$,
  puzzles = $pz$Not applicable -- a rules-knowledge item.$pz$,
  assignments = $as$Not required as separate homework.$as$
where description = 'Knows what happens when a flag falls with insufficient mating material.';

update public.items set
  how_to_teach = $ht$Teach handling a dispute correctly: call the arbiter without stopping the clock improperly for the situation, and wait for a ruling rather than self-adjudicating.$ht$,
  how_to_check = $hc$Performs a correct mock dispute-handling drill.$hc$,
  puzzles = $pz$Not a solving puzzle -- best practised as a live drill.$pz$,
  assignments = $as$Not required as separate homework -- reinforced through the drill.$as$
where description = 'Handles a dispute by calling the arbiter without stopping the clock improperly.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, and the module's final checkpoint, testing rules knowledge comprehensively.$ht$,
  how_to_check = $hc$Twenty-question rules test drawn from the FIDE Laws; passes with 17/20 or better, score recorded.$hc$,
  puzzles = $pz$A twenty-question written rules test drawn from the FIDE Laws.$pz$,
  assignments = $as$No assignment -- this is the checkpoint itself.$as$
where description = 'Checkpoint: twenty-question rules test drawn from the FIDE Laws.';
