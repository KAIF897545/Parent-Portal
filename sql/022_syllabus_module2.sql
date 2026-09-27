-- Parent Portal — detailed syllabus content for Module 2 ("A Real Game")
--
-- Continues the syllabus feature from sql/021_syllabus_module1.sql: populates
-- how_to_teach/how_to_check/puzzles/assignments (added in that migration) for
-- all 46 items of Module 2. Matches by exact description text, same as
-- Module 1, since every description in the 298-row items table is unique.

-- ===================== 2.1 Tactics with two pieces =====================

update public.items set
  how_to_teach = $ht$Show a piece pinned against its own king — moving it would expose the king to check, so it's illegal. Demonstrate with a bishop pinning a knight to the king on the back rank, and have the student try to move the pinned piece to confirm it's genuinely not allowed.$ht$,
  how_to_check = $hc$8 puzzles requiring the student to find or exploit an absolute pin; 8/10 or better passes.$hc$,
  puzzles = $pz$"Absolute pin" themed puzzle sets, a standard category in any tactics collection.$pz$,
  assignments = $as$Solve ten absolute-pin puzzles during the week, noting which piece is pinned and to what in each.$as$
where description = 'Absolute pin against the king.';

update public.items set
  how_to_teach = $ht$Contrast with the absolute pin: here the pin is against a bigger piece (queen or rook) rather than the king, so moving the pinned piece is legal but costly. Show an example where moving away allows a favourable capture.$ht$,
  how_to_check = $hc$8 puzzles with relative pins; 8/10 or better passes.$hc$,
  puzzles = $pz$"Relative pin" themed sets, mixed with a few absolute pins so the student has to tell them apart.$pz$,
  assignments = $as$Solve eight relative-pin puzzles, writing one sentence on what would be lost if the pinned piece moved.$as$
where description = 'Relative pin against a bigger piece.';

update public.items set
  how_to_teach = $ht$Teach the "add an attacker" technique: once a piece is pinned, bring another attacker onto the same line to win it outright, since it can't move away. Demonstrate with a rook doubling up behind a bishop's pin.$ht$,
  how_to_check = $hc$5 positions where the correct move adds an attacker to an existing pin; passes all 5.$hc$,
  puzzles = $pz$Search "exploit the pin" or "win the pinned piece" puzzle sets.$pz$,
  assignments = $as$Solve five puzzles that require adding an attacker to a pin, not just spotting the pin itself.$as$
where description = 'Adds an attacker to a pinned piece.';

update public.items set
  how_to_teach = $ht$Teach the three ways to break a pin on your own piece: block the line with another piece, capture the pinning piece, or move the king (for an absolute pin) to unpin. Show all three with quick examples.$ht$,
  how_to_check = $hc$5 positions where the student's own piece is pinned; finds the correct unpinning method in each.$hc$,
  puzzles = $pz$Search "unpin" or "break the pin" puzzles — a less common label, may need to build custom examples.$pz$,
  assignments = $as$Solve five "escape the pin" puzzles, trying each method (block, capture, move the king) at least once.$as$
where description = 'Breaks a pin on her own position.';

update public.items set
  how_to_teach = $ht$Teach the skewer as the pin's mirror image: attack a valuable piece that must move, revealing a less valuable piece behind it on the same line. Have the student explain the pin/skewer distinction in their own words before solving puzzles.$ht$,
  how_to_check = $hc$Student explains the pin/skewer distinction correctly, then solves 8/10 skewer puzzles.$hc$,
  puzzles = $pz$"Skewer" themed puzzle sets, a standard category in any collection.$pz$,
  assignments = $as$Solve eight skewer puzzles, noting which piece is forced to move and what's won behind it.$as$
where description = 'Skewer, and how it differs from a pin.';

update public.items set
  how_to_teach = $ht$Move one piece out of the way of another, revealing an attack from the piece that stayed still. Show that the moving piece can also make its own threat, creating a double problem for the opponent.$ht$,
  how_to_check = $hc$8 discovered-attack puzzles; 8/10 or better passes.$hc$,
  puzzles = $pz$"Discovered attack" themed puzzle sets.$pz$,
  assignments = $as$Solve eight discovered-attack puzzles during the week.$as$
where description = 'Discovered attack.';

update public.items set
  how_to_teach = $ht$Same idea as discovered attack, but the revealed piece gives check. Emphasise that the moving piece is free to do almost anything, even capture something, since the check already forces a response.$ht$,
  how_to_check = $hc$5 discovered-check puzzles; 5/5 passes.$hc$,
  puzzles = $pz$"Discovered check" themed puzzle sets.$pz$,
  assignments = $as$Solve five discovered-check puzzles, paying attention to what the moving piece did with its free move.$as$
where description = 'Discovered check.';

update public.items set
  how_to_teach = $ht$Teach double check as the extreme case: both the moving piece and the revealed piece give check at once, so the only legal response is a king move — blocking or capturing can't address two checks simultaneously.$ht$,
  how_to_check = $hc$Student explains why only king moves answer a double check, then solves 3 puzzles.$hc$,
  puzzles = $pz$"Double check" themed puzzles — fewer available than other patterns; a curated set of classic examples works well.$pz$,
  assignments = $as$Solve three double-check puzzles and write one sentence on why blocking doesn't work in each.$as$
where description = 'Double check, and why only the king can answer it.';

update public.items set
  how_to_teach = $ht$Build the habit of scanning for the opponent's tactical resources (pins, forks, discovered attacks) before committing to a move, not just reacting after. Practise by pausing before each move in a live game and asking "what could go wrong here?"$ht$,
  how_to_check = $hc$Observed in three games — coach watches for the student pausing to check for opponent tactics before moving, not just reacting after a blunder.$hc$,
  puzzles = $pz$Not applicable — this is a live-game habit, best assessed through observed play.$pz$,
  assignments = $as$Play three home games narrating out loud (or to a parent) any tactic checked for before each move.$as$
where description = 'Spots the opponent''s tactic before playing her own move.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, combining pins, skewers, discovered attacks and checks, and double checks in one mixed, unlabelled test.$ht$,
  how_to_check = $hc$30 mixed puzzles covering all the unit's tactics, unlabelled. 24/30 or better passes; record the score.$hc$,
  puzzles = $pz$Build the 30-puzzle set by mixing puzzles already used in items 1-8, in random order, unlabelled.$pz$,
  assignments = $as$No assignment — this is the checkpoint itself, run once the individual tactics above are solid.$as$
where description = 'Checkpoint: thirty mixed two-piece tactics.';

-- ===================== 2.2 Not losing material =====================

update public.items set
  how_to_teach = $ht$Teach the "counting" method for a contested square: list every attacker and defender in order of value, then simulate the capture sequence to see who ends up ahead. Practise on a single square with three or four pieces aiming at it before applying it in a full position.$ht$,
  how_to_check = $hc$5 positions with a contested square; student counts the sequence correctly and states the material result in each.$hc$,
  puzzles = $pz$Not a standard labelled category — build "who wins the exchange on this square" diagrams, or use general tactics positions and ask this specific question.$pz$,
  assignments = $as$Pick five contested squares from any game (own or a book) and count the capture sequence on paper.$as$
where description = 'Counts a sequence of captures on one square accurately.';

update public.items set
  how_to_teach = $ht$Once the student can count a sequence, teach them to use it as a decision tool: only initiate a capture on a square if the count favours them, or is at worst neutral with a clear positional reason.$ht$,
  how_to_check = $hc$5 positions where initiating versus declining the exchange is the key decision; correct choice in all 5.$hc$,
  puzzles = $pz$"Should you take?" style positions — mix genuinely favourable and unfavourable exchanges.$pz$,
  assignments = $as$Solve five "should you take?" positions, writing a one-line count-based justification for each decision.$as$
where description = 'Decides whether to initiate an exchange based on that count.';

update public.items set
  how_to_teach = $ht$Teach the classic guideline: knights are stronger in closed, blocked positions and on defended outposts; bishops are stronger in open positions with long diagonals. Show one closed-structure example where the knight is better and one open-structure example where the bishop is better.$ht$,
  how_to_check = $hc$Student explains the distinction using two example structures shown to them, not memorised ones.$hc$,
  puzzles = $pz$Not applicable — a conceptual, positional judgement rather than a tactical puzzle.$pz$,
  assignments = $as$Not required as homework — best taught through the two worked examples and reinforced by general play.$as$
where description = 'Knows when a knight is worth more than a bishop and when it isn''t.';

update public.items set
  how_to_teach = $ht$Build on the knight-versus-bishop judgement: before any voluntary trade, ask "is my piece doing more work than theirs?" Review a recent game together looking specifically at the voluntary trades made.$ht$,
  how_to_check = $hc$Coach reviews one of the student's own games, checking whether trades offered or accepted were sound by this standard.$hc$,
  puzzles = $pz$Not applicable — assessed through game review.$pz$,
  assignments = $as$Play one home game consciously applying the "which piece is better" question before every trade, then bring the scoresheet in.$as$
where description = 'Avoids trading a good piece for a bad one.';

update public.items set
  how_to_teach = $ht$Teach a simple two-question routine before playing any move: "does this hang anything?" and "is there a check, capture or threat I'm missing?" Model it out loud during a practice game so the student hears the internal monologue.$ht$,
  how_to_check = $hc$Observe a full game where the student narrates the two-question check aloud before every move.$hc$,
  puzzles = $pz$Not applicable — a live-play habit, not a puzzle skill.$pz$,
  assignments = $as$Play one home game narrating the blunder-check routine out loud (or to a parent) before every move.$as$
where description = 'Blunder-check routine before every move: is it hanging, is there a check.';

update public.items set
  how_to_teach = $ht$This item tracks an outcome rather than teaching something new — the routine from the previous item, applied consistently, should show up as fewer blunders over time. Keep a simple blunder count per game to make the trend visible.$ht$,
  how_to_check = $hc$Coach compares two of the student's games a month apart, counting outright blunders (hung pieces, missed one-move tactics) in each; the later game should show fewer.$hc$,
  puzzles = $pz$Not applicable — assessed through game comparison over time.$pz$,
  assignments = $as$Keep playing regularly and let the coach track blunder counts across the month; the routine itself is the only requirement.$as$
where description = 'Reduces blunders across a month.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint — the blunder-check routine applied under real, full-game conditions, narrated the whole way through.$ht$,
  how_to_check = $hc$Coach tallies how many of the student's moves included an audible blunder-check; 80% or better passes.$hc$,
  puzzles = $pz$Not applicable — this checkpoint is a full live game, not puzzles.$pz$,
  assignments = $as$No assignment — this is the checkpoint itself, run once the routine feels automatic in casual play.$as$
where description = 'Checkpoint: plays a full game thinking aloud; coach records the blunder check applied on at least 80% of moves.';

-- ===================== 2.3 Mate patterns =====================

update public.items set
  how_to_teach = $ht$Extend the basic back-rank idea with a deflection: sacrifice a piece to lure the defender off the back rank or away from a key defensive square, then deliver mate. Show one classic example where a rook or queen sacrifice clears the way.$ht$,
  how_to_check = $hc$5 puzzles requiring a deflection sacrifice to set up back-rank mate; passes all 5.$hc$,
  puzzles = $pz$"Back rank mate" puzzle sets filtered for ones requiring a sacrifice first, not just an immediate mate.$pz$,
  assignments = $as$Solve five deflection-sacrifice back-rank puzzles during the week.$as$
where description = 'Back rank with a deflection sacrifice.';

update public.items set
  how_to_teach = $ht$Teach the full classical sequence: queen sacrifice on the corner square, forcing the king into a smothered position, then the knight delivers checkmate supported by nothing but the surrounding pieces. Walk through the Philidor's legacy example move by move.$ht$,
  how_to_check = $hc$Student plays the full sequence unprompted from the standard starting setup.$hc$,
  puzzles = $pz$"Smothered mate" or "Philidor's legacy" themed puzzles — a standard named pattern in most tactics collections.$pz$,
  assignments = $as$Practise the sequence from three different starting setups at home until it's automatic.$as$
where description = 'Smothered mate, the full Philidor sequence.';

update public.items set
  how_to_teach = $ht$Teach the pattern: a knight controls the escape square while a rook or queen delivers mate along a rank or file, with the king trapped against the board edge by its own pawn. Show the named example position.$ht$,
  how_to_check = $hc$3 puzzles using this exact pattern; passes all 3.$hc$,
  puzzles = $pz$"Anastasia's mate" themed puzzles — a standard named pattern in most tactics collections.$pz$,
  assignments = $as$Solve three Anastasia's mate puzzles during the week.$as$
where description = 'Anastasia''s mate.';

update public.items set
  how_to_teach = $ht$Teach the pattern: a knight and rook combine, with the knight controlling flight squares and the rook delivering mate along the edge, king trapped in the corner. Show the named example.$ht$,
  how_to_check = $hc$3 puzzles using this pattern; passes all 3.$hc$,
  puzzles = $pz$"Arabian mate" themed puzzles.$pz$,
  assignments = $as$Solve three Arabian mate puzzles during the week.$as$
where description = 'Arabian mate.';

update public.items set
  how_to_teach = $ht$Teach the "ladder" technique with both queen and rook, a step up from Module 1's two-rook version: alternate checks to walk the king to the edge, being careful not to stalemate, then deliver mate.$ht$,
  how_to_check = $hc$Executes the ladder mate from a set starting position, no hints.$hc$,
  puzzles = $pz$Not a solving puzzle — best practised as a live drill from a set position.$pz$,
  assignments = $as$Practise the queen-and-rook ladder mate from three different starting positions at home.$as$
where description = 'Ladder mate with queen and rook.';

update public.items set
  how_to_teach = $ht$Teach that not every mating sequence starts with a check or a capture — sometimes a quiet move, like cutting off an escape square, sets up an inescapable mate next move. Show one clear example where the first move looks unremarkable but is decisive.$ht$,
  how_to_check = $hc$8/10 or better on mate-in-two puzzles requiring a quiet first move.$hc$,
  puzzles = $pz$"Mate in two, quiet move" themed sets — search for puzzles explicitly labelled this way, since many collections separate quiet-move problems from forcing ones.$pz$,
  assignments = $as$Solve ten mate-in-two puzzles during the week, noting which ones had a quiet first move.$as$
where description = 'Mate in two with a quiet first move.';

update public.items set
  how_to_teach = $ht$This is about transfer from puzzles to real play — remind the student to actively look for these named patterns (back rank, smothered, Anastasia's, Arabian, ladder) during their own games, not just in training.$ht$,
  how_to_check = $hc$Delivers one of these pattern mates in an actual club game, not a puzzle or practice game.$hc$,
  puzzles = $pz$Not applicable — assessed through a real game, not a puzzle.$pz$,
  assignments = $as$No specific puzzle assignment — keep playing club games and watch for a chance to apply one of these patterns.$as$
where description = 'Recognises a pattern in her own game rather than in a puzzle.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, combining all the named patterns above into a single mixed, unlabelled test.$ht$,
  how_to_check = $hc$20 mixed mate-in-one and mate-in-two puzzles, unlabelled. 16/20 or better passes; record the score.$hc$,
  puzzles = $pz$Build the 20-puzzle set from a mix of the named patterns above plus a few fresh ones, in random order.$pz$,
  assignments = $as$No assignment — this is the checkpoint itself.$as$
where description = 'Checkpoint: twenty mate-in-one and mate-in-two problems.';

-- ===================== 2.4 King and pawn endings =====================

update public.items set
  how_to_teach = $ht$Teach the visual shortcut: draw or imagine a square from the pawn to its promotion square — if the defending king can step inside that square, it catches the pawn; if not, the pawn queens. Practise drawing the square on several positions before testing without drawing it.$ht$,
  how_to_check = $hc$10 positions with various pawns and king placements; student correctly judges catch-or-not in all 10, first without drawing then confirming by drawing the square.$hc$,
  puzzles = $pz$"Rule of the square" themed diagrams — a common beginner-to-intermediate category, or build custom positions easily.$pz$,
  assignments = $as$Solve ten rule-of-the-square judgement calls during the week, checking each by actually drawing the square afterward.$as$
where description = 'Rule of the square: can the king catch the pawn.';

update public.items set
  how_to_teach = $ht$Teach opposition as kings facing each other with one square between them on the same file, rank or diagonal: whoever is not forced to move "has the opposition" and controls the position. Demonstrate on the board with simple king-only positions, alternating who's to move.$ht$,
  how_to_check = $hc$Student demonstrates on the board which side has the opposition in several setups, and shows the resulting outcome.$hc$,
  puzzles = $pz$Not applicable — a hands-on concept best shown physically on the board.$pz$,
  assignments = $as$Not required as homework — reinforced through the demonstration and later positions in this unit.$as$
where description = 'Direct opposition, and who wins it.';

update public.items set
  how_to_teach = $ht$Extend direct opposition to kings several squares apart on the same file or rank: teach the rule of counting squares between them (an odd number of squares between the kings on the relevant line means the player to move has the distant opposition).$ht$,
  how_to_check = $hc$3 positions with kings far apart; student correctly identifies who holds the distant opposition and demonstrates the result.$hc$,
  puzzles = $pz$Not applicable — best shown on the board with real king-and-pawn positions.$pz$,
  assignments = $as$Not required as separate homework — folds into the practice positions for converting and holding endings later in this unit.$as$
where description = 'Distant opposition.';

update public.items set
  how_to_teach = $ht$Teach the standard key-square rule for a pawn not yet on the 6th or 7th rank: the key squares are the three squares directly in front of it, two ranks ahead (the rook-pawn case is handled separately). If the attacking king can reach a key square, the pawn queens with correct play.$ht$,
  how_to_check = $hc$Student correctly identifies the key squares for a pawn placed on any file or rank asked.$hc$,
  puzzles = $pz$Not applicable — a rule to apply, best tested through direct questioning and board demonstration.$pz$,
  assignments = $as$Given five random pawn placements during the week (own choosing or from a book), mark the key squares for each.$as$
where description = 'Key squares in front of a pawn.';

update public.items set
  how_to_teach = $ht$Bring together the rule of the square, opposition and key squares: given a winning king-and-pawn-versus-king position, the student should reach a key square or use opposition to escort the pawn home.$ht$,
  how_to_check = $hc$5 winning positions; converts all 5 against the coach.$hc$,
  puzzles = $pz$"King and pawn endgame" themed positions, filtered to winning setups.$pz$,
  assignments = $as$Practise converting five winning king-and-pawn positions at home, against a parent, sibling, or app.$as$
where description = 'Converts king and pawn versus king when winning.';

update public.items set
  how_to_teach = $ht$Teach the defensive side of the same technique: keeping the attacking king off the key squares, or reaching the right corner in a rook-pawn case, to hold a draw in an objectively equal or losing pawn ending.$ht$,
  how_to_check = $hc$5 drawn positions; holds the draw in all 5 against the coach.$hc$,
  puzzles = $pz$"King and pawn endgame" positions filtered to drawn setups.$pz$,
  assignments = $as$Practise holding five drawn king-and-pawn positions at home.$as$
where description = 'Holds the draw when defending.';

update public.items set
  how_to_teach = $ht$Teach the special case: a rook's pawn (a- or h-file) with the defending king in the corner is often a draw even when the general key-square rule would say otherwise, because the attacking king can't get behind the pawn from both sides. Show the exact drawn position.$ht$,
  how_to_check = $hc$Student explains why the exception applies and demonstrates holding the draw from the position.$hc$,
  puzzles = $pz$Not applicable — a specific named exception, best shown directly on the board.$pz$,
  assignments = $as$Not required as separate homework — reinforced through the demonstration.$as$
where description = 'Knows the rook''s pawn exception.';

update public.items set
  how_to_teach = $ht$Teach the shift in the king's role once major pieces are traded: it becomes an active attacking piece rather than staying safe, and should head toward the centre or the action immediately.$ht$,
  how_to_check = $hc$Observed in a real game — coach watches for the student bringing the king forward promptly once queens, or all major pieces, are exchanged.$hc$,
  puzzles = $pz$Not applicable — assessed through live play.$pz$,
  assignments = $as$Play one home game where queens get traded, consciously activating the king afterward, then bring the scoresheet in.$as$
where description = 'Activates the king once queens are off.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, mixing winning and drawing positions unlabelled so the student must judge the correct result themselves, not just execute a known technique.$ht$,
  how_to_check = $hc$10 positions, a mix of winning and drawing, played against the coach; correct result in 8/10 or better passes. Record the score.$hc$,
  puzzles = $pz$Build the 10-position test set from a mix of the converting and holding positions above, plus a few fresh ones.$pz$,
  assignments = $as$No assignment — this is the checkpoint itself.$as$
where description = 'Checkpoint: ten king-and-pawn positions, half winning and half drawing, played against the coach.';

-- ===================== 2.5 Having a plan =====================

update public.items set
  how_to_teach = $ht$Teach the habit of pausing right after the opening phase to state a simple plan in one sentence, such as "I'll aim for the minority attack" or "I'll trade off the bad bishop." Model this out loud in a practice game first.$ht$,
  how_to_check = $hc$Observed across three games — student states a one-sentence plan aloud after the opening in each.$hc$,
  puzzles = $pz$Not applicable — a live-play habit.$pz$,
  assignments = $as$Play three home games, pausing after the opening in each to state a plan aloud or write it on the scoresheet.$as$
where description = 'States a plan aloud after the opening, in one sentence.';

update public.items set
  how_to_teach = $ht$Teach the "worst piece" heuristic: scan your own pieces and ask which one is doing the least, then look for a way to improve it. Practise on a few sample middlegame positions.$ht$,
  how_to_check = $hc$5 positions; student correctly identifies the worst-placed piece and a reasonable improving move in each.$hc$,
  puzzles = $pz$Not a standard labelled category — build custom middlegame diagrams, or use general middlegame positions and ask this specific question.$pz$,
  assignments = $as$Solve five "find the worst piece" positions during the week.$as$
where description = 'Identifies her worst-placed piece and improves it.';

update public.items set
  how_to_teach = $ht$Teach target-finding: look for a weak pawn, a weak square, an uncastled king, or an undeveloped piece in the opponent's camp, and aim the plan at it.$ht$,
  how_to_check = $hc$5 positions; student correctly identifies a genuine target and a plan to exploit it.$hc$,
  puzzles = $pz$General middlegame planning positions — ask "what's the target here?" rather than relying on a specific labelled puzzle type.$pz$,
  assignments = $as$Solve five "find the target" positions during the week.$as$
where description = 'Finds a target in the opponent''s position.';

update public.items set
  how_to_teach = $ht$Teach the basic decision framework: attack on a wing where you have space or the opponent is weak; contest the centre when it's still open or undecided. Show contrasting examples of each.$ht$,
  how_to_check = $hc$3 positions; student explains which choice is correct and why.$hc$,
  puzzles = $pz$Not applicable as solving puzzles — a judgement and explanation task, best done with example positions.$pz$,
  assignments = $as$Not required as separate homework — reinforced through the three worked examples.$as$
where description = 'Chooses between attacking on a wing and playing in the centre.';

update public.items set
  how_to_teach = $ht$Teach flexibility: a plan is a working hypothesis, not a commitment — if the opponent's move changes what the position demands, the plan should change too. Review a game where the student stuck with a plan too long, or use a model game showing correct flexibility.$ht$,
  how_to_check = $hc$Coach reviews one of the student's own games, checking whether the stated plan was reasonably updated as the position changed.$hc$,
  puzzles = $pz$Not applicable — assessed through game review.$pz$,
  assignments = $as$Play one home game consciously re-stating the plan every five or six moves to check it's still relevant, then bring the scoresheet in.$as$
where description = 'Changes plan when the position changes rather than persisting.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, bringing the whole unit together in a written annotation of a real game with at least three distinct stated plans across its course.$ht$,
  how_to_check = $hc$The written annotation itself, showing at least three genuine, distinct plans stated at different points in the game.$hc$,
  puzzles = $pz$Not applicable — this checkpoint is a written annotation, not puzzles.$pz$,
  assignments = $as$No assignment — this is the checkpoint itself.$as$
where description = 'Checkpoint: annotates one of her own games in writing with at least three stated plans.';

-- ===================== 2.6 First tournament =====================

update public.items set
  how_to_teach = $ht$This is a real-world milestone rather than a taught skill — the coach's job is to prepare the student logistically and emotionally: what to expect, how the rounds work, what to bring. Walk through the tournament format before the first round.$ht$,
  how_to_check = $hc$Attendance record showing the student played every round of a real club tournament.$hc$,
  puzzles = $pz$Not applicable — this is a real-world commitment, not a puzzle skill.$pz$,
  assignments = $as$No assignment beyond registering for and attending the tournament itself.$as$
where description = 'Completes a full club tournament, all rounds.';

update public.items set
  how_to_teach = $ht$Reinforce notation habits from Module 1 under real tournament pressure: write clearly, keep the sheet with the game rather than folded away, and fix any move-recording mistake immediately rather than guessing later.$ht$,
  how_to_check = $hc$All scoresheets from the event are legible and complete.$hc$,
  puzzles = $pz$Not applicable.$pz$,
  assignments = $as$No separate assignment — apply existing notation skills consistently across the tournament.$as$
where description = 'Submits legible scoresheets for every round.';

update public.items set
  how_to_teach = $ht$Teach basic time-management awareness for a first event: check the clock periodically, don't spend too long on early moves, and watch the clock especially closely once a position is clearly won so a time-loss doesn't throw away the result.$ht$,
  how_to_check = $hc$No time losses recorded across the event, especially not in objectively won positions.$hc$,
  puzzles = $pz$Not applicable — assessed through the real tournament.$pz$,
  assignments = $as$No separate assignment — a live-event habit to apply during the tournament itself.$as$
where description = 'Manages the clock without flagging in a won position.';

update public.items set
  how_to_teach = $ht$Prepare the student emotionally before the event: losing is part of competing, and the correct response is a handshake and moving on, not tears at the board or blaming external factors. Discuss this explicitly before the first round.$ht$,
  how_to_check = $hc$Coach observes the student's behaviour after any loss during the event: composed, no blaming, shakes hands.$hc$,
  puzzles = $pz$Not applicable.$pz$,
  assignments = $as$No assignment — a conduct expectation for the event itself.$as$
where description = 'Behaves correctly after a loss: no tears at the board, no blaming.';

update public.items set
  how_to_teach = $ht$After the tournament, sit down with the student and go through one game together, discussing what went well and what to work on, modelling how to review objectively without an engine first.$ht$,
  how_to_check = $hc$The review session itself is completed with the coach.$hc$,
  puzzles = $pz$Not applicable.$pz$,
  assignments = $as$No assignment — schedule the review session after the event.$as$
where description = 'Reviews one game from the event with a coach.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint and the module's final checkpoint, combining everything above: a completed event, full legible scoresheets, and a completed review session.$ht$,
  how_to_check = $hc$All of the above confirmed together — the tournament crosstable, the scoresheets, and the completed review session.$hc$,
  puzzles = $pz$Not applicable — this checkpoint is a real event, not puzzles.$pz$,
  assignments = $as$No assignment — this is the checkpoint itself.$as$
where description = 'Checkpoint: one completed tournament with full scoresheets and a review session.';
