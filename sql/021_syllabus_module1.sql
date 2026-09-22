-- Parent Portal — coach syllabus content (pilot: Module 1, "First Moves")
--
-- Adds four text fields to items for a readable "how to teach this"
-- reference: how_to_teach (method/explanation), how_to_check (the
-- assessment script, distinct from the terse pass_standard already on
-- the item), puzzles (practice material), and assignments (take-home
-- work). All nullable -- only Module 1's 82 items are populated here as
-- a pilot; the other five modules stay null until reviewed and written
-- the same way.
--
-- Matched by exact description text rather than unit_id + sort_order,
-- since every description in this curriculum is long and specific
-- enough that a collision across the table's 298 rows is not a real
-- risk, and it keeps this file readable as plain content rather than
-- id lookups.

alter table public.items add column if not exists how_to_teach text;
alter table public.items add column if not exists how_to_check text;
alter table public.items add column if not exists puzzles text;
alter table public.items add column if not exists assignments text;

-- ===================== 1.1 The board =====================

update public.items set
  how_to_teach = $ht$Teach the rhyme "white on the right": standing behind the board, the corner square nearest the student's right hand must be light. Have them set up an empty board from a random starting orientation and self-correct using the rhyme rather than copying your board.$ht$,
  how_to_check = $hc$Rotate the board out of the student's sight, then ask them to set it up from scratch. Repeat on three different days so it becomes a habit, not a one-off.$hc$,
  puzzles = $pz$Not a solving item — do a "spot the error" drill instead: set the board up wrong (white on the left) and ask what's wrong before they touch it.$pz$,
  assignments = $as$Set up the board at home before every practice session for two weeks, unprompted. A parent only needs to check the light square is on the student's right.$as$
where description = 'Sets up a board with the white square bottom-right.';

update public.items set
  how_to_teach = $ht$Teach the layout in three passes: the back-rank pattern ("rook, knight, bishop, queen-on-her-colour, king, bishop, knight, rook"), then the pawn wall, then a final "queen on her own colour" check. Let them place pieces from a jumbled pile, not a pre-sorted one.$ht$,
  how_to_check = $hc$Time a full set-up from a shuffled pile of all 32 pieces. It should finish under 60 seconds with no corrections needed afterward.$hc$,
  puzzles = $pz$Speed drills: race the student against a stopwatch, best of three attempts in a session.$pz$,
  assignments = $as$Have them set up and pack away the full board five times over the week, timing themselves and writing down each time.$as$
where description = 'Places all sixteen pieces correctly, queen on her own colour.';

update public.items set
  how_to_teach = $ht$Files are letters (a-h) read left to right from White's side; ranks are numbers (1-8) read bottom to top from White's side. Walk a finger along the bottom edge naming files, then up the left edge naming ranks, from both sides of the board so it isn't memorised from one seat only.$ht$,
  how_to_check = $hc$Point to files and ranks in random order, asking "what file/rank is this?" from both sides of the board — 10 questions, all 10 correct.$hc$,
  puzzles = $pz$Flash-card style: call out "file e" or "rank 3" and have them slap the row/column with an open hand.$pz$,
  assignments = $as$Practise naming files and ranks on a home set (or printed board) from both ends, five minutes a day.$as$
where description = 'Names files a to h and ranks 1 to 8 from either side of the board.';

update public.items set
  how_to_teach = $ht$Show that any square is the intersection of one file and one rank — "e4" is where file e crosses rank 4. Practise by having them trace a finger along the file, then along the rank, to where they meet.$ht$,
  how_to_check = $hc$Call out 15 squares one at a time and time each; every square found under 5 seconds.$hc$,
  puzzles = $pz$"Square scramble": call squares in a random order that crosses the board diagonally, not systematically, so they can't just count along one edge.$pz$,
  assignments = $as$Ask a family member to call out five random squares each day for them to point to on a home board.$as$
where description = 'Locates any named square.';

update public.items set
  how_to_teach = $ht$Reverse the previous skill: point at a piece and ask which file and rank it sits on, reading the coordinates off the board's edges rather than guessing.$ht$,
  how_to_check = $hc$Place 10 pieces on the board one at a time and ask "what square is this on?" — 10/10 correct.$hc$,
  puzzles = $pz$Set up a random middlegame-looking position (no need for it to be legal) and ask them to call out every occupied square in 60 seconds.$pz$,
  assignments = $as$Using any home position (even a mid-game one from a family game), name every square that has a piece on it.$as$
where description = 'Names the square a piece stands on.';

update public.items set
  how_to_teach = $ht$Point out d4, d5, e4, e5 as the centre, then c3 through f6 as the extended centre. Explain in one sentence why it matters: pieces posted here reach the most squares, which is why openings fight over them.$ht$,
  how_to_check = $hc$On a bare board, ask the student to point out the four centre squares, then the extended centre boundary, without hints.$hc$,
  puzzles = $pz$Not applicable — this is a labelling task. As a variant, ask them to count how many squares a knight on d4 attacks versus a knight on a1, to make the "centre is powerful" point concrete.$pz$,
  assignments = $as$Have them draw a blank 8x8 grid from memory and shade in the centre and extended centre squares.$as$
where description = 'Identifies the four centre squares and the extended centre.';

update public.items set
  how_to_teach = $ht$Show that a diagonal is named by its two end squares, e.g. a1-h8 is the long diagonal. Trace a few diagonals of different lengths so they see diagonals can be short (b1-a2) as well as the long ones.$ht$,
  how_to_check = $hc$Point to a diagonal on the board and ask them to name it by its endpoints — 5 diagonals, 5 correct.$hc$,
  puzzles = $pz$Ask which diagonal a given bishop sits on and how long it is (how many squares), reinforcing file/rank naming at the same time.$pz$,
  assignments = $as$Have them find and name three different diagonals on a home board, writing each one down as "a1-h8" style notation.$as$
where description = 'Identifies a diagonal by its end squares, for example a1-h8.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint — no new teaching, just a combined test of everything above under mild pressure (being watched and scored).$ht$,
  how_to_check = $hc$Student sets up a full board from a shuffled pile, then answers 20 square-naming questions (files, ranks, named squares, piece squares, diagonals mixed together). At most one error passes.$hc$,
  puzzles = $pz$Use the same square-naming drills from items 3-5 above, mixed together and unannounced, to simulate the checkpoint format before running it for real.$pz$,
  assignments = $as$No assignment — this is the checkpoint itself. Schedule it once the coach is confident from the unit's other items that the student is ready.$as$
where description = 'Checkpoint: sets up the board and answers twenty square-naming questions with at most one error.';

-- ===================== 1.2 How each piece moves =====================

update public.items set
  how_to_teach = $ht$Place a lone rook on d4 on an empty board and have the student mark every square it attacks with a coin or scrap of paper — the whole rank and file. Repeat with the rook in a corner so they see the count doesn't change, only the shape.$ht$,
  how_to_check = $hc$Set up 3 different positions with a rook and ask the student to mark (point to or place markers on) every legal move in each.$hc$,
  puzzles = $pz$"How many squares?" drill: rook on a1 vs rook on d4 on an empty board — count attacked squares in each (should be the same, 14).$pz$,
  assignments = $as$Draw a rook on a blank grid at home and shade every square it could move to from three different starting squares.$as$
where description = 'Rook: moves and captures along rank and file.';

update public.items set
  how_to_teach = $ht$Point out that each side starts with one light-squared and one dark-squared bishop, and a bishop can never change colour because diagonals never cross between colours. Have them trace a bishop's full diagonal reach from several squares.$ht$,
  how_to_check = $hc$Without looking at a board, ask the student to state which colour each of their bishops starts on and stays on — should be instant and correct.$hc$,
  puzzles = $pz$Show a bishop mid-diagonal and ask "can this bishop ever reach [named square]?" — answer depends only on matching square colours.$pz$,
  assignments = $as$Have them colour in (on paper) every square one bishop could reach over a whole game, starting from c1 or f1.$as$
where description = 'Bishop: stays on its starting colour.';

update public.items set
  how_to_teach = $ht$Frame the queen as "rook plus bishop from the same square" — she can do everything a rook can and everything a bishop can, just not a knight's L-shape. Have them mark her reach from d4 and compare it to a rook's and a bishop's marked separately.$ht$,
  how_to_check = $hc$3 positions, mark every legal queen move in each — should combine correctly with no L-shaped or forward-pawn-style errors.$hc$,
  puzzles = $pz$"Queen vs two pieces": place a queen on d4, then a rook and bishop also on d4 in two separate diagrams, and confirm the queen's marked squares equal the union of the other two.$pz$,
  assignments = $as$Practise finding the queen's longest possible move from five different starting squares on a home board.$as$
where description = 'Queen: combines rook and bishop.';

update public.items set
  how_to_teach = $ht$The king moves one square in any of the eight directions. The common error is forgetting the edge/corner cases, so deliberately place the king on an edge and in a corner and ask what changes (fewer squares, not a different pattern).$ht$,
  how_to_check = $hc$Mark legal king moves from a centre square, an edge square, and a corner square — all three correct, including the reduced counts at the edge/corner.$hc$,
  puzzles = $pz$"Count the king's moves": centre (8), edge (5), corner (3) — have the student predict the count before marking.$pz$,
  assignments = $as$Walk the king one square at a time around the full border of the board at home, naming each square as they go.$as$
where description = 'King: one square, any direction.';

update public.items set
  how_to_teach = $ht$Teach the knight's move as "two then one, like a capital L" in any of the four rotations, or as "the only piece that jumps." From a centre square, walk through all eight landing squares one at a time before asking them to find all eight unprompted.$ht$,
  how_to_check = $hc$From a centre square (e.g. d4 or e5), the student finds all eight legal knight moves without help.$hc$,
  puzzles = $pz$"Find all eight": repeat from d4, e5, and c6 to build the pattern beyond a single memorised square.$pz$,
  assignments = $as$Have them hop a knight around the board at home landing on every square exactly once if they can (a simplified knight's tour), just for pattern familiarity — it doesn't need to be solved perfectly.$as$
where description = 'Knight: the L, and that it jumps over pieces.';

update public.items set
  how_to_teach = $ht$Show that a knight in a corner has only 2 legal moves and on an edge has 3 or 4, using the same L-shape rule — nothing new to learn, just fewer squares fit on the board. Compare directly against the 8 available from the centre.$ht$,
  how_to_check = $hc$Place a knight in a corner and on an edge and ask the student to state the correct reduced move count for each, then verify by marking them.$hc$,
  puzzles = $pz$"Best square for a knight": given a choice of a1, e4, or h8 to place a new knight, ask which is strongest and why (this previews the "knights on the rim are dim" opening principle).$pz$,
  assignments = $as$Have them place a knight on all four corners of a home board in turn and count/mark its legal moves each time.$as$
where description = 'Knight from a corner and from an edge.';

update public.items set
  how_to_teach = $ht$Pawns move straight ahead, never sideways or backwards, one square normally and two squares only from their starting square. Emphasise "never backwards" early — it is the single most common beginner mistake.$ht$,
  how_to_check = $hc$5 positions with pawns at various stages of the board; student correctly marks legal forward moves in each, including recognising which pawns still have the two-square option.$hc$,
  puzzles = $pz$"Can it move two?" drill: show pawns that have already moved and pawns still on their home square, and ask which have the two-square option.$pz$,
  assignments = $as$Set up just the pawns on a home board and play through the first few moves of a game touching only pawns, narrating "one square" or "two squares" aloud each time.$as$
where description = 'Pawn: one square forward, two from its start, never backwards.';

update public.items set
  how_to_teach = $ht$Contrast pawn movement (straight) with pawn capturing (diagonal only) — a pawn can never capture the piece directly in front of it. Set up a pawn blocked by an enemy piece directly ahead and ask if it can move (no) or capture it (no, wrong direction).$ht$,
  how_to_check = $hc$Show a blocked pawn (enemy piece directly ahead, nothing diagonally) and ask the student to identify that it cannot move at all — this is the specific trap the pass standard checks for.$hc$,
  puzzles = $pz$Mixed diagram: some pawns have diagonal capture targets, some are blocked straight ahead with no diagonal targets — sort which pawns can act and how.$pz$,
  assignments = $as$Set up five mini positions at home with one pawn each in different situations (free to advance, blocked, with a capture available) and have the student explain each aloud.$as$
where description = 'Pawn captures diagonally, not forwards.';

update public.items set
  how_to_teach = $ht$Tie together items 7 and 8: a pawn can be blocked (piece directly ahead, stops it moving) but can never be "blocked" from capturing diagonally since a capture needs an enemy piece there in the first place. Every other piece can simply be blocked by anything in its path.$ht$,
  how_to_check = $hc$Ask the student to explain, using the board, which pieces can be physically blocked by pieces in between (everything except the knight) and why a pawn's diagonal capture is a special case.$hc$,
  puzzles = $pz$Not a solving item — a short oral-explanation check using a live board as a prop.$pz$,
  assignments = $as$Have them explain the blocking rule to a parent or sibling using the home set as a prop, which doubles as a natural check for the coach next session.$as$
where description = 'Knows which pieces can be blocked and which cannot.';

update public.items set
  how_to_teach = $ht$Play a full, relaxed game together where the only goal is legality, not strategy — gently correct any illegal move in the moment rather than after the fact, so the rule sticks immediately.$ht$,
  how_to_check = $hc$Observe one complete game start to finish; zero illegal moves is the pass standard.$hc$,
  puzzles = $pz$Not applicable — this item is assessed through live play, not puzzles.$pz$,
  assignments = $as$Play one full game at home with a parent or sibling, with instructions to gently flag anything that looks like it might be an illegal move for the coach to review next session.$as$
where description = 'Plays a full game using only legal moves.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint. Pair the student with another student at a similar stage and referee the game yourself, intervening only to record illegal moves, not to coach.$ht$,
  how_to_check = $hc$Watch a complete game between two students. Zero illegal moves passes; sign and date the scoresheet or record as evidence.$hc$,
  puzzles = $pz$Before the checkpoint, run one or two practice games under the same "coach watching, zero illegal moves" conditions so the format isn't a surprise.$pz$,
  assignments = $as$No assignment — schedule this once both paired students are individually ready on item 10.$as$
where description = 'Checkpoint: plays a complete game against another student with a coach watching. Zero illegal moves.';

-- ===================== 1.3 Check, mate, stalemate =====================

update public.items set
  how_to_teach = $ht$Define check simply: the king is under direct attack right now. Show several checks from different piece types (rook, bishop, knight, queen, pawn) so the student learns to recognise the pattern, not just one example.$ht$,
  how_to_check = $hc$10 positions, some in check and some not; student correctly identifies each — 10/10.$hc$,
  puzzles = $pz$Mixed "in check or not?" flash positions, including near-misses (attacking piece one square short of giving check) to sharpen discrimination.$pz$,
  assignments = $as$Set up five positions at home (can be invented) and label each "check" or "not check," then have a parent verify using the rules explained by the student.$as$
where description = 'Recognises when a king is in check.';

update public.items set
  how_to_teach = $ht$Teach the three escapes as a fixed list to recite: move the king, block the check, capture the checking piece. Show one example of each so the words attach to real positions.$ht$,
  how_to_check = $hc$Ask the student to recite the three ways out of check unprompted, in any order.$hc$,
  puzzles = $pz$Not a solving item on its own — pairs naturally with the next item's puzzles.$pz$,
  assignments = $as$Have them teach the three escapes to a family member using the home board, which reinforces recall through explanation.$as$
where description = 'Lists the three ways out of check: move, block, capture.';

update public.items set
  how_to_teach = $ht$Set up checks where only one of the three escapes is available, then ones where two or three are available, so the student practises scanning for all legal options rather than grabbing the first one they see.$ht$,
  how_to_check = $hc$5 check positions; student finds every legal escape in each, not just one.$hc$,
  puzzles = $pz$Lichess-style "escape the check" puzzles, or hand-set positions with 1-3 legal escapes each, mixing move/block/capture.$pz$,
  assignments = $as$Solve five check-escape positions set up by a parent (or copied from a puzzle book/app) over the week.$as$
where description = 'Finds all legal escapes in a given check.';

update public.items set
  how_to_teach = $ht$Set up a position where the "obvious" king move actually walks into a different check, and let the student make the mistake once under supervision — this rule sticks best after one corrected error.$ht$,
  how_to_check = $hc$Offer the student a king move that looks legal but walks into check; they should correctly identify it as illegal and explain why.$hc$,
  puzzles = $pz$"Spot the illegal king move": present 3-4 tempting-but-illegal king escapes and have them explain what square is actually guarded.$pz$,
  assignments = $as$No standalone assignment — reinforced naturally within item 3's escape-finding practice.$as$
where description = 'Knows a king may never move into check.';

update public.items set
  how_to_teach = $ht$Demonstrate with two kings on the board that neither can step adjacent to the other, since doing so would put the moving king in check from the opposing king itself. This becomes important later for king-and-pawn endgames.$ht$,
  how_to_check = $hc$In a king-and-pawn position, ask the student to identify which squares their king cannot step to because the enemy king guards them.$hc$,
  puzzles = $pz$Simple two-king positions asking "can White's king move here?" with some squares adjacent to Black's king as traps.$pz$,
  assignments = $as$Not required as homework — this is best reinforced live, in the endgame practice that comes later in Module 1.$as$
where description = 'Knows two kings may never stand adjacent.';

update public.items set
  how_to_teach = $ht$Contrast the two directly: check means the king is attacked but has a legal escape; checkmate means attacked with no legal escape at all. Show one of each side by side on two boards or in quick succession.$ht$,
  how_to_check = $hc$10 positions labelled ambiguously; student sorts each correctly into check or checkmate.$hc$,
  puzzles = $pz$Mate-in-1 puzzles work well here since solving one naturally requires distinguishing "still checked" from "now mated."$pz$,
  assignments = $as$Sort ten position diagrams (from a puzzle book, app, or hand-drawn) into "check" and "checkmate" piles.$as$
where description = 'Distinguishes checkmate from check.';

update public.items set
  how_to_teach = $ht$Introduce stalemate as "not in check, but no legal moves at all" — the critical difference from checkmate is the absence of check. This is the single most common source of confusion at this level, so spend real time on it.$ht$,
  how_to_check = $hc$10 positions mixing checkmate and stalemate closely; 9/10 correct passes, allowing for the genuine difficulty of this discrimination.$hc$,
  puzzles = $pz$Classic king-vs-king-and-queen stalemate traps (queen too close to a cornered king) contrasted with the same position adjusted to be checkmate instead.$pz$,
  assignments = $as$Review five near-identical position pairs (one stalemate, one checkmate) and explain out loud what's different in each pair.$as$
where description = 'Distinguishes stalemate from checkmate.';

update public.items set
  how_to_teach = $ht$Ask the student why it might seem unfair that a much stronger side can accidentally "let the game off" — then explain the rule exists so a player with no legal move is never forced to move illegally. It's a safety valve, not a reward.$ht$,
  how_to_check = $hc$Ask the student to explain in their own words why stalemate is scored as a draw rather than a win for the stronger side.$hc$,
  puzzles = $pz$Not applicable — this is a concept-explanation item.$pz$,
  assignments = $as$Have them explain stalemate to a parent, including a real or invented example, as a natural rehearsal before the checkpoint.$as$
where description = 'Explains why stalemate is a draw, not a win.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint. Prepare 20 varied positions in advance mixing check, checkmate, stalemate, and plain "none of the above" so the student cannot pattern-match from repetition.$ht$,
  how_to_check = $hc$20 mixed positions, labelled check / checkmate / stalemate / none by the student. 17/20 or better passes; record the score.$hc$,
  puzzles = $pz$Build the 20-position test bank from a mix of puzzle apps, books, and hand-set positions so the checkpoint itself doubles as fresh material.$pz$,
  assignments = $as$No assignment — this is the checkpoint itself, run once the earlier items in this unit are solid.$as$
where description = 'Checkpoint: twenty mixed positions labelled check, checkmate, stalemate or none.';

-- ===================== 1.4 Special moves =====================

update public.items set
  how_to_teach = $ht$Demonstrate kingside castling as a single action: king moves two squares toward the rook, then the rook hops over to sit beside it. Stress "king first" — touching the rook first can be read as a rook move under touch-move rules later.$ht$,
  how_to_check = $hc$Student demonstrates kingside castling correctly, king moved first, three separate times.$hc$,
  puzzles = $pz$Not a solving item — a physical-execution drill repeated until it's automatic.$pz$,
  assignments = $as$Practise castling kingside from the starting position on a home board five times, saying "king first" each time.$as$
where description = 'Castles kingside correctly, king first.';

update public.items set
  how_to_teach = $ht$Show queenside castling as the same idea with a longer king hop (still only two squares) and the rook coming from further away, landing on d1/d8. Point out this is why it's sometimes called "long castling."$ht$,
  how_to_check = $hc$Student demonstrates queenside castling correctly, three separate times.$hc$,
  puzzles = $pz$Not a solving item — a physical-execution drill, same format as kingside.$pz$,
  assignments = $as$Practise queenside castling five times at home, then castle both ways in the same game for extra repetition.$as$
where description = 'Castles queenside correctly.';

update public.items set
  how_to_teach = $ht$Teach the four conditions as a checklist: neither king nor that rook has moved before; no pieces stand between them; the king is not currently in check; and the king does not pass through or land on an attacked square. Repeat the list often — it needs to become automatic recall.$ht$,
  how_to_check = $hc$Ask the student to list all four conditions unprompted, without looking at notes or the board.$hc$,
  puzzles = $pz$Not applicable directly — pairs with the next item's puzzle-style positions.$pz$,
  assignments = $as$Have them write the four conditions from memory once a day for a week until it's automatic.$as$
where description = 'States the four conditions that prevent castling.';

update public.items set
  how_to_teach = $ht$Set up four separate positions, each breaking exactly one of the four conditions, and have the student diagnose which rule is broken in each — this turns the memorised list into something they can actually apply.$ht$,
  how_to_check = $hc$4 positions, one broken condition each; student identifies the correct reason castling is illegal in all 4.$hc$,
  puzzles = $pz$"Why can't White castle here?" diagrams — a great small puzzle set to build ahead of the check.$pz$,
  assignments = $as$Solve four "why can't castling happen" diagrams set by a parent or found in a beginner puzzle book.$as$
where description = 'Identifies a position where castling is illegal and says why.';

update public.items set
  how_to_teach = $ht$Set up the specific pawn structure required for en passant (enemy pawn just advanced two squares, landing beside yours) and walk through the capture step by step, emphasising it must happen immediately, on the very next move.$ht$,
  how_to_check = $hc$From a set starting position, student executes the en passant capture correctly, three times.$hc$,
  puzzles = $pz$Not a solving item at this stage — pure mechanical repetition of the capture from a fixed setup.$pz$,
  assignments = $as$Practise the en passant capture from the same set position five times at home until the hand motion is automatic.$as$
where description = 'Executes an en passant capture.';

update public.items set
  how_to_teach = $ht$Show that if the student plays any other move instead of capturing en passant right away, the right disappears permanently — even one move later it's gone. This is the rule's single trickiest point.$ht$,
  how_to_check = $hc$Ask the student to explain, in their own words, why en passant must be played immediately or not at all.$hc$,
  puzzles = $pz$Not applicable — a spoken-explanation check.$pz$,
  assignments = $as$Have them explain the "use it immediately or lose it" rule to a parent, using the home board to show a missed-window example.$as$
where description = 'Explains that the right is lost if not used immediately.';

update public.items set
  how_to_teach = $ht$Play out a simple pawn-race position where a pawn reaches the eighth (or first) rank and show it must immediately become a queen (or another piece) — it cannot stay a pawn or wait.$ht$,
  how_to_check = $hc$Within a live game, the student correctly promotes a pawn to a queen when it reaches the last rank.$hc$,
  puzzles = $pz$Simple pawn-endgame positions where the pawn just needs pushing home to promote, to isolate the mechanic before adding tactics.$pz$,
  assignments = $as$Play a short home game or set position specifically designed to reach promotion, and promote correctly.$as$
where description = 'Promotes a pawn to a queen.';

update public.items set
  how_to_teach = $ht$Introduce underpromotion with a concrete example: a knight promotion that gives check or delivers mate where a queen would only stalemate or fail to check. This is a rare but memorable exception worth a dedicated puzzle.$ht$,
  how_to_check = $hc$From a set puzzle position, the student finds and plays the underpromoting move (to a knight) that a queen promotion would not achieve.$hc$,
  puzzles = $pz$Classic "queen promotion stalemates, knight promotion mates" puzzle — search for or construct one specific position that makes the point unambiguously.$pz$,
  assignments = $as$Solve one or two underpromotion puzzles during the week so the exception isn't forgotten between sessions.$as$
where description = 'Underpromotes to a knight to deliver check or mate.';

update public.items set
  how_to_teach = $ht$Teach the five draw types as a memorable list: stalemate, threefold repetition, the fifty-move rule, insufficient material, and agreement between players. One sentence of explanation for each is enough at this stage.$ht$,
  how_to_check = $hc$Ask the student to list all five ways a game can be drawn, unprompted.$hc$,
  puzzles = $pz$Not applicable — a recall item, though pairs well with real examples shown on the board (e.g. king vs king for insufficient material).$pz$,
  assignments = $as$Have them write all five draw types from memory once a day for a week.$as$
where description = 'Lists the five ways a game is drawn.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint. Arrange (not force artificially, but steer) a coach-vs-student game where all three special moves are likely to come up naturally, so the checkpoint feels like real play rather than a scripted test.$ht$,
  how_to_check = $hc$Watch a full game in which castling, en passant, and promotion all occur and are executed correctly. Keep the scoresheet as evidence.$hc$,
  puzzles = $pz$Warm up with a few short practice games first, deliberately steering toward positions where each special move is likely to arise.$pz$,
  assignments = $as$No assignment — this is the checkpoint itself, arranged once the student is comfortable with each special move individually.$as$
where description = 'Checkpoint: a coach-arranged game in which castling, en passant and promotion all occur, executed correctly.';

-- ===================== 1.5 Notation =====================

update public.items set
  how_to_teach = $ht$Teach algebraic notation as "piece letter, then destination square" (Nf3 = knight to f3), with pawn moves having no letter at all (just e4). Start with pawn moves since they need no piece letter, then add pieces one at a time.$ht$,
  how_to_check = $hc$Read out 10 individual moves in notation and have the student physically play each one on the board correctly.$hc$,
  puzzles = $pz$Simple "read and play" drills using moves from any real game, one move at a time out of context.$pz$,
  assignments = $as$Practise reading and playing 10 notated moves a day from any source (a book, app, or moves the coach writes out).$as$
where description = 'Reads a single move in algebraic notation and plays it.';

update public.items set
  how_to_teach = $ht$Introduce the three symbols together since they're easy to confuse: x means capture, + means check, # means checkmate. Show one real example of each in sequence.$ht$,
  how_to_check = $hc$Ask the student to explain what x, +, and # each mean in a notated move.$hc$,
  puzzles = $pz$Show a short sequence of notated moves containing all three symbols and have them narrate what happens in plain English.$pz$,
  assignments = $as$Find and circle every x, +, and # in a printed game score, and label what each one means.$as$
where description = 'Reads capture, check and mate symbols.';

update public.items set
  how_to_teach = $ht$Teach O-O for kingside and O-O-O for queenside castling notation, and connect it back to Unit 1.4's physical castling moves so the notation isn't learned in isolation.$ht$,
  how_to_check = $hc$Give the student the notation O-O and separately O-O-O and have them play each correctly on the board on demand.$hc$,
  puzzles = $pz$Not applicable — a direct notation-to-move drill.$pz$,
  assignments = $as$Play both O-O and O-O-O from the starting position at home, saying the notation aloud each time.$as$
where description = 'Reads castling notation, both sides.';

update public.items set
  how_to_teach = $ht$Give the student a full ten-move sequence written in notation (a real short opening works well) and have them play it through on the board move by move without any other guidance.$ht$,
  how_to_check = $hc$Student plays through a prepared ten-move notated sequence and reaches the exact correct final position.$hc$,
  puzzles = $pz$Use a short, well-known opening line (or any coach-prepared ten-move sequence) as the test material — no need to invent puzzles specifically.$pz$,
  assignments = $as$Play through one or two short annotated openings from a book or app at home, checking the final position looks right.$as$
where description = 'Plays through a ten-move annotated game from notation alone.';

update public.items set
  how_to_teach = $ht$Reverse the earlier skill: the student makes a move on the board and must write it correctly in notation themselves, including piece letter (or none for pawns) and destination square.$ht$,
  how_to_check = $hc$Student writes 10 moves as they're played; 9 or more correct passes.$hc$,
  puzzles = $pz$Not applicable — a live writing-while-playing drill, best done during item 7's scoresheet practice.$pz$,
  assignments = $as$Write down every move of one home game as it's played, even an informal one, as notation practice.$as$
where description = 'Writes a single move correctly.';

update public.items set
  how_to_teach = $ht$Introduce disambiguation only once basic notation is solid: when two identical pieces could reach the same square, add the piece's starting file or rank, e.g. Nbd2 means "the knight from the b-file moves to d2." Show a real position where this is needed so it isn't abstract.$ht$,
  how_to_check = $hc$3 positions where two identical pieces could reach the same square; student writes the correctly disambiguated notation for the intended move.$hc$,
  puzzles = $pz$Construct or find three positions with doubled knights or rooks that could both reach one square, and have the student write the correct notation for each.$pz$,
  assignments = $as$Not essential as standalone homework — reinforced naturally through general scorekeeping practice in the next item.$as$
where description = 'Disambiguates when two pieces can reach the same square, as in Nbd2.';

update public.items set
  how_to_teach = $ht$Have the student keep a scoresheet during an actual game rather than a drill — this is where notation becomes a real skill rather than an exercise. Sit beside them the first few times to catch slips immediately.$ht$,
  how_to_check = $hc$After a full game, replay the student's scoresheet on a separate board; it must reconstruct the game exactly with no missing or wrong moves.$hc$,
  puzzles = $pz$Not applicable — assessed through a real recorded game, not puzzles.$pz$,
  assignments = $as$Record one full home game on a scoresheet (informal paper is fine) and bring it to the next session for the coach to replay.$as$
where description = 'Records a full game on a scoresheet while playing.';

update public.items set
  how_to_teach = $ht$Teach the standard result notations (1-0, 0-1, 1/2-1/2) and show that a signed, dated scoresheet is the accepted record of a tournament game — this connects notation to the club-conduct unit that follows.$ht$,
  how_to_check = $hc$After a game, the student correctly writes the result and signs the scoresheet without being told the exact format each time.$hc$,
  puzzles = $pz$Not applicable — a real-game procedural check.$pz$,
  assignments = $as$Finish and correctly sign off the scoresheet from the previous item's home game if not already done.$as$
where description = 'Writes the result and signs the scoresheet.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint. Explain up front that a second person (another student, coach, or parent) will try to replay their scoresheet afterward — this raises the stakes for accuracy in a way that focuses attention.$ht$,
  how_to_check = $hc$Student plays a full game recording every move. A second person replays the game from the scoresheet alone with no ambiguity or missing information.$hc$,
  puzzles = $pz$Practise with one lower-stakes recorded game first, checking it for gaps before running the checkpoint for real.$pz$,
  assignments = $as$No assignment — this is the checkpoint itself, once general scorekeeping (items 5-8) is reliable.$as$
where description = 'Checkpoint: plays a game recording every move. A second person replays it from the scoresheet without ambiguity.';

-- ===================== 1.6 Club conduct and the clock =====================

update public.items set
  how_to_teach = $ht$Demonstrate starting a digital clock and the rule that you always press it with the same hand you moved a piece with — this prevents distracting cross-body movements during a game. Let the student practise starting/pressing a real clock a few times before a game.$ht$,
  how_to_check = $hc$Observe a full game on a clock; the student consistently presses with the moving hand throughout.$hc$,
  puzzles = $pz$Not applicable — an observed-behaviour item over a real game.$pz$,
  assignments = $as$If a clock is available at home, play one timed game practising the same-hand press rule.$as$
where description = 'Starts a digital clock and presses with the same hand that moved.';

update public.items set
  how_to_teach = $ht$Show what a flag fall looks like on a clock and explain the outcome: running out of time normally loses the game outright, regardless of the position on the board (with narrow exceptions for insufficient mating material, worth a brief mention).$ht$,
  how_to_check = $hc$Show the student a clock reading zero on one side and ask them to state the correct outcome.$hc$,
  puzzles = $pz$Not applicable — a rules-recall item.$pz$,
  assignments = $as$Not required as homework — best reinforced live during timed practice games.$as$
where description = 'Recognises flag fall and knows what it means.';

update public.items set
  how_to_teach = $ht$Explain touch-move plainly: if you touch a piece with intent to move it, you must move it if it has a legal move. Demonstrate the exception — adjusting a piece's position on its square is fine only after announcing "j'adoube" first.$ht$,
  how_to_check = $hc$Observe touch-move being correctly followed (or correctly invoked by an opponent) across three separate games.$hc$,
  puzzles = $pz$Not applicable — an observed-behaviour item over real games.$pz$,
  assignments = $as$Play three home games under touch-move rules, with a parent or sibling gently enforcing it.$as$
where description = 'Observes touch-move.';

update public.items set
  how_to_teach = $ht$Practise the phrase "j'adoube" (or "I adjust") before touching a piece just to straighten it, not move it — this is the one exception to touch-move and needs to become an automatic habit before a real tournament.$ht$,
  how_to_check = $hc$Observe the student say "j'adoube" before adjusting a piece at least once during a session.$hc$,
  puzzles = $pz$Not applicable — an observed-behaviour item.$pz$,
  assignments = $as$Not required as standalone homework — naturally reinforced across any home games under touch-move rules.$as$
where description = 'Says j''adoube before adjusting a piece.';

update public.items set
  how_to_teach = $ht$Teach the correct draw-offer sequence: make your move first, then offer the draw, then press the clock. Offering before moving, or offering repeatedly after a decline, are both considered poor etiquette.$ht$,
  how_to_check = $hc$Student demonstrates offering a draw in the correct order: move, then offer, then press clock.$hc$,
  puzzles = $pz$Not applicable — a procedural demonstration item.$pz$,
  assignments = $as$Not required as homework — best taught and checked live in a practice game.$as$
where description = 'Offers a draw correctly: after moving, before pressing the clock.';

update public.items set
  how_to_teach = $ht$Explain that resigning (a clear verbal statement, a handshake, or tipping over the king) is the respectful way to end a lost game, rather than just walking away or refusing to continue — abandoning the board is considered poor sportsmanship.$ht$,
  how_to_check = $hc$Observe the student resign properly at least once, when a position is genuinely lost, rather than abandoning the game.$hc$,
  puzzles = $pz$Not applicable — an observed-behaviour item, best captured naturally rather than staged.$pz$,
  assignments = $as$Not required as homework — this arises naturally across games and doesn't need to be forced.$as$
where description = 'Resigns properly rather than abandoning the board.';

update public.items set
  how_to_teach = $ht$Model the full etiquette sequence yourself first: handshake before, silence during play (no coaching, no commentary from either side), handshake after regardless of result. Make this the standard for every practice game from now on.$ht$,
  how_to_check = $hc$Observe the student shake hands before and after a game, and remain silent throughout the game itself.$hc$,
  puzzles = $pz$Not applicable — an observed-behaviour item over a full session.$pz$,
  assignments = $as$Not required as homework — reinforce as the default standard for every game, home or club.$as$
where description = 'Shakes hands before and after, and stays silent during play.';

update public.items set
  how_to_teach = $ht$Run a mock dispute (e.g. a disagreement over whether a touch-move claim is valid) and show the correct response: raise a hand calmly and wait for the arbiter, rather than arguing directly with the opponent.$ht$,
  how_to_check = $hc$In a staged mock dispute, the student correctly raises a hand for the arbiter instead of arguing.$hc$,
  puzzles = $pz$Not applicable — a role-play/behavioural item.$pz$,
  assignments = $as$Not required as homework — this is best rehearsed live, once, under the coach's supervision.$as$
where description = 'Raises a hand for the arbiter rather than arguing.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint. Run one full game under genuine tournament conditions — clock running, scoresheet being kept, silence enforced, handshake at both ends — so every conduct item from this unit is exercised together.$ht$,
  how_to_check = $hc$Observe one complete game meeting all four conditions at once: clock, scoresheet, silence, handshake. Sign as evidence.$hc$,
  puzzles = $pz$Not applicable — assessed through a single combined live game, not puzzles.$pz$,
  assignments = $as$No assignment — schedule this once every individual conduct item in the unit has been observed separately.$as$
where description = 'Checkpoint: one full game under tournament conditions: clock, scoresheet, silence, handshake.';

-- ===================== 1.7 First checkmates =====================

update public.items set
  how_to_teach = $ht$Show that a lone king in the centre has too many escape squares to be trapped, but a king pinned to an edge or corner has far fewer — this single idea underlies every basic mate that follows, so make sure it's genuinely understood, not just memorised.$ht$,
  how_to_check = $hc$Ask the student to explain, using the board, why a king in the centre with just a king and queen against it cannot be mated but one driven to the edge can.$hc$,
  puzzles = $pz$Compare king safety on d4 versus a1 by counting escape squares in each position side by side.$pz$,
  assignments = $as$Not required as standalone homework — this concept is reinforced directly by practising the mating techniques below.$as$
where description = 'Understands that mate needs the king pushed to an edge.';

update public.items set
  how_to_teach = $ht$Teach the "lawnmower" or "ladder" technique: two rooks take turns cutting off ranks, walking the enemy king toward the edge one row at a time until it's mated on the back rank. Demonstrate slowly first, narrating each rook's job.$ht$,
  how_to_check = $hc$From 3 different starting positions, the student delivers mate with two rooks in under 15 moves each.$hc$,
  puzzles = $pz$Set up two rooks and a lone king from various starting squares and have the student practise the ladder technique repeatedly until it's fluent.$pz$,
  assignments = $as$Practise the two-rook mate from three different starting positions at home, timing/counting moves each time.$as$
where description = 'Two rooks: the lawnmower, rank by rank.';

update public.items set
  how_to_teach = $ht$Teach the "box method": the queen shrinks a square around the enemy king one step at a time, always staying a knight's-move distance away so the king can't approach and capture her, while the king walks up to help finish the mate.$ht$,
  how_to_check = $hc$From 3 positions, student correctly shrinks the box, demonstrating the technique rather than just cornering the king by luck.$hc$,
  puzzles = $pz$Queen-and-king vs lone king positions at various starting box sizes, practising the shrinking technique specifically (not the final mate yet).$pz$,
  assignments = $as$Practise shrinking the box (without delivering mate yet) from three different starting positions.$as$
where description = 'Queen and king: walks the king to the edge with the box method.';

update public.items set
  how_to_teach = $ht$Once the box is small, bring the king up to support the queen and deliver mate — stress the most common beginner error here explicitly: putting the queen too close and stalemating the enemy king instead of mating it.$ht$,
  how_to_check = $hc$From 3 starting positions, student delivers mate in under 20 moves with zero stalemates.$hc$,
  puzzles = $pz$Deliberately include one "stalemate trap" position in practice (queen adjacent to a cornered king with no checks available) so the error is seen and corrected once under supervision.$pz$,
  assignments = $as$Practise the full queen-and-king mate from three starting positions, checking carefully for accidental stalemate each time.$as$
where description = 'Queen and king: delivers mate without stalemating.';

update public.items set
  how_to_teach = $ht$Introduce opposition: when the two kings face each other with one square between them, the player NOT to move controls the position ("has the opposition") and can force the other king backward. Demonstrate with just two kings on the board before adding a rook.$ht$,
  how_to_check = $hc$In a rook endgame position, student correctly uses opposition to force the enemy king back rather than the king wandering randomly.$hc$,
  puzzles = $pz$Simple two-king opposition drills (no other pieces) before combining with the rook, to isolate the concept.$pz$,
  assignments = $as$Practise the two-king opposition drill at home, then add a rook once it feels automatic.$as$
where description = 'Rook and king: uses opposition to force the king back.';

update public.items set
  how_to_teach = $ht$Combine opposition with the rook cutting off an entire rank or file, gradually squeezing the king to the edge and then delivering mate along the edge with the rook, king supporting from close by.$ht$,
  how_to_check = $hc$From 3 starting positions, student delivers rook-and-king mate in under 25 moves.$hc$,
  puzzles = $pz$Rook-and-king vs lone king from various starting positions, practising the full technique end to end.$pz$,
  assignments = $as$Practise the full rook-and-king mate from three starting positions at home.$as$
where description = 'Rook and king: delivers mate.';

update public.items set
  how_to_teach = $ht$Show the classic back-rank pattern: a king trapped behind its own pawns with no escape square, mated by a rook or queen landing safely on the back rank. This is one of the most common mating patterns in real games, so it's worth extra repetition.$ht$,
  how_to_check = $hc$Student finds the back-rank mate in 5 separate puzzle positions.$hc$,
  puzzles = $pz$Search any puzzle app or book for "back rank mate" — these are extremely common and easy to find in quantity; use 5-10 for practice before the pass check.$pz$,
  assignments = $as$Solve five back-rank mate puzzles during the week, from an app, book, or coach-prepared set.$as$
where description = 'Back-rank mate with a rook or queen.';

update public.items set
  how_to_teach = $ht$Flip the previous item around: show how to prevent being back-rank mated by making "luft" — moving one pawn in front of the king to create an escape square before it's needed, not after.$ht$,
  how_to_check = $hc$In their own game or a set position, the student spots the back-rank danger themselves and plays a move to fix it.$hc$,
  puzzles = $pz$Present positions where back-rank mate is one move away and ask "what should you play right now to prevent this?" rather than asking them to deliver the mate.$pz$,
  assignments = $as$Review a recent home game (their own if available) and check whether luft was ever needed and whether it was played in time.$as$
where description = 'Makes luft to prevent back-rank mate.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, combining everything above. Set up all three basic mates (two rooks, queen and king, rook and king) in one sitting against the coach, with no hints given.$ht$,
  how_to_check = $hc$Student converts all three basic mates against the coach in one sitting, unaided, with no stalemates along the way. Record move counts for each.$hc$,
  puzzles = $pz$Run a full practice sitting first, all three mates back to back, before attempting the checkpoint for real.$pz$,
  assignments = $as$No assignment — schedule this once all three mating techniques are individually solid.$as$
where description = 'Checkpoint: converts all three basic mates against the coach in one sitting, no hints, no stalemate.';

-- ===================== 1.8 Seeing one move ahead =====================

update public.items set
  how_to_teach = $ht$Teach the student to scan the whole board systematically (left to right, rank by rank) asking "is this piece defended?" for every enemy piece, rather than only noticing the first undefended piece they spot.$ht$,
  how_to_check = $hc$5 positions; student correctly identifies every undefended enemy piece in each, not just one or two.$hc$,
  puzzles = $pz$"Find them all" diagrams with 2-4 undefended pieces scattered across the board, requiring a full scan rather than a glance.$pz$,
  assignments = $as$Scan five positions (own games, a book, or an app) specifically hunting for every undefended piece before checking answers.$as$
where description = 'Identifies every undefended enemy piece in a position.';

update public.items set
  how_to_teach = $ht$Once a student can spot an undefended piece, the habit to build is actually taking it rather than hesitating or getting distracted. Reinforce with quick, low-pressure puzzles that reward decisive captures.$ht$,
  how_to_check = $hc$10 puzzles offering a free piece; student takes it correctly in each.$hc$,
  puzzles = $pz$"Free piece" puzzle sets — widely available in any beginner puzzle collection or app, filtered to single free captures.$pz$,
  assignments = $as$Solve ten free-piece puzzles during the week from an app or book.$as$
where description = 'Takes a free piece when offered.';

update public.items set
  how_to_teach = $ht$Introduce the idea of a "poisoned" capture: a piece that looks free but is actually defended, or capturing it opens the student's own king to danger. Teach a habit: before capturing, ask "what recaptures, and is that okay for me?"$ht$,
  how_to_check = $hc$3 positions where the "obvious" free piece is actually poisoned; student correctly declines each and explains why.$hc$,
  puzzles = $pz$"Trap puzzles" — a piece appears undefended but taking it loses material or walks into a tactic; search for "don't take the bait" style beginner puzzles.$pz$,
  assignments = $as$Solve three poisoned-piece puzzles where the tempting capture is actually a trap.$as$
where description = 'Checks whether a capture is really free before taking.';

update public.items set
  how_to_teach = $ht$Teach counting attackers and defenders on a single square as a simple tally: more attackers than defenders usually means a piece (or square) can be won by force. Practise on a single contested square before applying it in a full position.$ht$,
  how_to_check = $hc$5 positions; student correctly counts attackers and defenders on a marked square in each.$hc$,
  puzzles = $pz$Mark a single square in various positions and ask "who controls this square, and by how much?"$pz$,
  assignments = $as$Pick five squares in any game (own or from a book) and count attackers/defenders on each.$as$
where description = 'Counts attackers and defenders on a square.';

update public.items set
  how_to_teach = $ht$Teach the knight fork pattern explicitly: a single knight move attacking two undefended enemy pieces at once, so the opponent can only save one. Show a few classic fork squares (like a knight forking a king and rook) as memorable examples.$ht$,
  how_to_check = $hc$10 knight fork puzzles; 8/10 or better passes.$hc$,
  puzzles = $pz$"Knight fork" is a standard theme in nearly every puzzle app or book — use a filtered set of 10-15 for practice ahead of the check.$pz$,
  assignments = $as$Solve ten knight fork puzzles during the week.$as$
where description = 'Knight fork on two undefended pieces.';

update public.items set
  how_to_teach = $ht$Show that even a humble pawn can fork two pieces by advancing to attack them both diagonally at once — often overlooked by beginners because the pawn seems too weak to threaten much.$ht$,
  how_to_check = $hc$5 pawn fork puzzles; 5/5 passes.$hc$,
  puzzles = $pz$Search "pawn fork" themed puzzles in any app or book — a smaller but still findable category.$pz$,
  assignments = $as$Solve five pawn fork puzzles during the week.$as$
where description = 'Pawn fork.';

update public.items set
  how_to_teach = $ht$Teach the queen fork, including the specific "fork with check" pattern where the queen forks two pieces while also giving check — this is especially strong because the opponent must deal with the check first, losing time to save both pieces.$ht$,
  how_to_check = $hc$10 queen fork puzzles including some check-and-fork patterns; 8/10 or better passes.$hc$,
  puzzles = $pz$"Queen fork" or "royal fork" themed puzzle sets, including check-combined examples, from any standard puzzle source.$pz$,
  assignments = $as$Solve ten queen fork puzzles during the week, noting which ones also involved check.$as$
where description = 'Queen fork, including the check-and-win pattern.';

update public.items set
  how_to_teach = $ht$Build the habit of asking "what did that move threaten?" after every single opponent move, not just when something looks obviously dangerous. Model this out loud yourself during a practice game so the student hears the internal monologue.$ht$,
  how_to_check = $hc$Observe a full game where the student narrates the opponent's threat aloud after each of the opponent's moves.$hc$,
  puzzles = $pz$Not applicable — this is a habit observed through live, narrated play rather than solved puzzles.$pz$,
  assignments = $as$Play one home game narrating "what does that move threaten?" out loud after every opponent move, for practice.$as$
where description = 'Asks what the opponent''s move threatens, every move.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint. Mix free-piece and fork puzzles together, unlabelled, so the student has to recognise the pattern themselves rather than being told which tactic to look for in advance.$ht$,
  how_to_check = $hc$20 one-move puzzles mixing free pieces and forks, unlabelled. 16/20 or better passes; record the score.$hc$,
  puzzles = $pz$Build the 20-puzzle test set by mixing puzzles already used in items 1-7, plus a few fresh ones, in random order.$pz$,
  assignments = $as$No assignment — this is the checkpoint itself, run once the individual tactical skills above are solid.$as$
where description = 'Checkpoint: twenty one-move puzzles mixing free pieces and forks.';

-- ===================== 1.9 Starting a game properly =====================

update public.items set
  how_to_teach = $ht$Teach the opening principle simply: claim central squares early with a pawn (e4 or d4 are the classic choices) so pieces have room to develop toward the centre, where they're strongest.$ht$,
  how_to_check = $hc$Observe the student open with a centre pawn in three consecutive games.$hc$,
  puzzles = $pz$Not applicable — assessed through real games, not puzzles.$pz$,
  assignments = $as$Play three home games, opening with a centre pawn each time, and note which one they preferred.$as$
where description = 'Opens with a centre pawn.';

update public.items set
  how_to_teach = $ht$Teach the general development order: knights before rooks, because knights need to hop into the game while rooks work best after the position opens up. This doesn't need to be rigid, just a sensible default.$ht$,
  how_to_check = $hc$Review three of the student's own scoresheets; knights are consistently developed before rooks.$hc$,
  puzzles = $pz$Not applicable — assessed through review of real recorded games.$pz$,
  assignments = $as$Play and record three home games, consciously developing knights before rooks, then bring the scoresheets to the next session.$as$
where description = 'Develops a knight before a rook.';

update public.items set
  how_to_teach = $ht$Explain that moving the same piece twice early (without a good reason like escaping a threat or winning material) wastes time that could have brought a new piece into the game — this is called "losing a tempo."$ht$,
  how_to_check = $hc$Coach reviews three of the student's own games for unnecessary repeated piece moves in the opening.$hc$,
  puzzles = $pz$Not applicable — assessed through game review rather than puzzles.$pz$,
  assignments = $as$Play three home games trying to develop a different piece each move in the opening unless forced otherwise, then bring the scoresheets in.$as$
where description = 'Avoids moving the same piece twice in the opening without reason.';

update public.items set
  how_to_teach = $ht$Reinforce castling as a standing opening habit, not just a mechanical skill from Unit 1.4 — the goal now is doing it early and reliably in real games to get the king to safety before the position gets sharp.$ht$,
  how_to_check = $hc$Review three games; the student castles within the first twelve moves in each.$hc$,
  puzzles = $pz$Not applicable — assessed through real games.$pz$,
  assignments = $as$Play three home games with a personal goal of castling by move twelve each time.$as$
where description = 'Castles within the first twelve moves.';

update public.items set
  how_to_teach = $ht$Show a simple example of an early queen sortie being chased around the board by developing enemy pieces, each chase costing the queen's side a tempo — the queen's activity is real but pieces gaining tempo attacking her is a bigger cost early on.$ht$,
  how_to_check = $hc$Ask the student to explain, using the board, why bringing the queen out too early usually backfires.$hc$,
  puzzles = $pz$Set up a short demonstration line (e.g. an early Qh5 chased by developing moves) and walk through it together as a worked example rather than a puzzle to solve.$pz$,
  assignments = $as$Not required as homework — best taught through the worked example above and reinforced by general play.$as$
where description = 'Explains why the early queen sortie loses time.';

update public.items set
  how_to_teach = $ht$Show the Scholar's Mate pattern once as the attacker so the student recognises the threat, then teach the standard defence (blocking or defending f7/f2 in time, often with a knight developing to defend and attack the queen).$ht$,
  how_to_check = $hc$Coach attempts Scholar's Mate against the student three times; the student successfully defends all three.$hc$,
  puzzles = $pz$Not applicable as puzzles — this is best practised as live mini-games specifically set up for the attack.$pz$,
  assignments = $as$Ask a parent or sibling to attempt Scholar's Mate against them at home a few times for extra repetition.$as$
where description = 'Defends against Scholar''s Mate.';

update public.items set
  how_to_teach = $ht$Teach "connecting the rooks" as a marker of a well-developed position: once all the pieces between the two rooks have moved (and the king has castled), the rooks defend each other along the back rank and are ready to work together.$ht$,
  how_to_check = $hc$In their own game, the student correctly identifies the moment their rooks become connected.$hc$,
  puzzles = $pz$Not applicable — assessed through spotting the moment within a real game.$pz$,
  assignments = $as$Review a recent home game and mark the exact move where the rooks became connected, if it happened.$as$
where description = 'Connects the rooks.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint and the final checkpoint of Module 1. Collect three of the student's own recent scoresheets and review them together for every principle from this unit: centre pawn, knight before rook, no wasted moves, timely castling, and connected rooks.$ht$,
  how_to_check = $hc$Review three consecutive scoresheets together; the coach can identify all the opening principles from this unit being followed. Keep the three scoresheets as evidence.$hc$,
  puzzles = $pz$Not applicable — this checkpoint is a review of real games, not puzzles.$pz$,
  assignments = $as$No assignment — collect three recent games (playing more if needed) once the individual principles above are being applied consistently.$as$
where description = 'Checkpoint: coach reviews three consecutive scoresheets and can see all the principles followed.';
