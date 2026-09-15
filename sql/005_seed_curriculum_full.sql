-- Parent Portal — full curriculum seed (supersedes 004_seed_module1.sql)
-- Source: docs/curriculum.md. Replaces the placeholder Module 1 with the
-- authoritative six-module, two-year curriculum supplied by the club.

delete from public.items where unit_id in (
  select id from public.units where module_id in (
    select id from public.modules where number in (1,2,3,4,5,6)
  )
);
delete from public.units where module_id in (
  select id from public.modules where number in (1,2,3,4,5,6)
);
delete from public.modules where number in (1,2,3,4,5,6);

insert into public.modules (number, name) values
  (1, 'First Moves'),
  (2, 'A Real Game'),
  (3, 'Tactics and Structure'),
  (4, 'Plans and Preparation'),
  (5, 'Competitive Player'),
  (6, 'Independent Player');

-- =======================================================================
-- MODULE 1 — First Moves
-- =======================================================================
with m as (select id from public.modules where number = 1)
insert into public.units (module_id, number, name, sort_order)
select m.id, u.number, u.name, u.sort_order from m, (values
  ('1.1', 'The board', 1),
  ('1.2', 'How each piece moves', 2),
  ('1.3', 'Check, mate, stalemate', 3),
  ('1.4', 'Special moves', 4),
  ('1.5', 'Notation', 5),
  ('1.6', 'Club conduct and the clock', 6),
  ('1.7', 'First checkmates', 7),
  ('1.8', 'Seeing one move ahead', 8),
  ('1.9', 'Starting a game properly', 9)
) as u(number, name, sort_order);

with u as (select id from public.units where number = '1.1')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Sets up a board with the white square bottom-right.', 'three times, unprompted', false, 1),
  ('Places all sixteen pieces correctly, queen on her own colour.', 'under 60 seconds, no corrections', false, 2),
  ('Names files a to h and ranks 1 to 8 from either side of the board.', '10/10 asked at random', false, 3),
  ('Locates any named square.', '15 squares, under 5 seconds each', false, 4),
  ('Names the square a piece stands on.', '10/10', false, 5),
  ('Identifies the four centre squares and the extended centre.', 'points them out on a bare board', false, 6),
  ('Identifies a diagonal by its end squares, for example a1-h8.', '5/5', false, 7),
  ('Checkpoint: sets up the board and answers twenty square-naming questions with at most one error.', 'score recorded', true, 8)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '1.2')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Rook: moves and captures along rank and file.', 'marks all legal moves in 3 positions', false, 1),
  ('Bishop: stays on its starting colour.', 'states the colour of each bishop without looking', false, 2),
  ('Queen: combines rook and bishop.', 'marks all legal moves in 3 positions', false, 3),
  ('King: one square, any direction.', 'marks legal moves including at the edge', false, 4),
  ('Knight: the L, and that it jumps over pieces.', 'from a centre square, finds all eight destinations', false, 5),
  ('Knight from a corner and from an edge.', 'states the reduced count correctly', false, 6),
  ('Pawn: one square forward, two from its start, never backwards.', '5 positions', false, 7),
  ('Pawn captures diagonally, not forwards.', 'identifies a blocked pawn that cannot move', false, 8),
  ('Knows which pieces can be blocked and which cannot.', 'explains aloud with a board', false, 9),
  ('Plays a full game using only legal moves.', 'one game, no illegal move', false, 10),
  ('Checkpoint: plays a complete game against another student with a coach watching. Zero illegal moves.', 'coach signature, date', true, 11)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '1.3')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Recognises when a king is in check.', '10 positions, 10 correct', false, 1),
  ('Lists the three ways out of check: move, block, capture.', 'recites unprompted', false, 2),
  ('Finds all legal escapes in a given check.', '5 positions', false, 3),
  ('Knows a king may never move into check.', 'spots the illegal escape offered by the coach', false, 4),
  ('Knows two kings may never stand adjacent.', 'demonstrated in a king-and-pawn position', false, 5),
  ('Distinguishes checkmate from check.', '10 positions', false, 6),
  ('Distinguishes stalemate from checkmate.', '10 positions, 9 correct', false, 7),
  ('Explains why stalemate is a draw, not a win.', 'in her own words', false, 8),
  ('Checkpoint: twenty mixed positions labelled check, checkmate, stalemate or none.', '17/20, score recorded', true, 9)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '1.4')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Castles kingside correctly, king first.', 'demonstrated 3 times', false, 1),
  ('Castles queenside correctly.', 'demonstrated 3 times', false, 2),
  ('States the four conditions that prevent castling.', 'lists all four unprompted', false, 3),
  ('Identifies a position where castling is illegal and says why.', '4 positions, 4 correct', false, 4),
  ('Executes an en passant capture.', '3 times from a set position', false, 5),
  ('Explains that the right is lost if not used immediately.', 'in her own words', false, 6),
  ('Promotes a pawn to a queen.', 'demonstrated in a game', false, 7),
  ('Underpromotes to a knight to deliver check or mate.', 'from a set puzzle', false, 8),
  ('Lists the five ways a game is drawn.', 'stalemate, repetition, fifty-move, insufficient material, agreement', false, 9),
  ('Checkpoint: a coach-arranged game in which castling, en passant and promotion all occur, executed correctly.', 'scoresheet', true, 10)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '1.5')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Reads a single move in algebraic notation and plays it.', '10 moves', false, 1),
  ('Reads capture, check and mate symbols.', 'explains x, + and #', false, 2),
  ('Reads castling notation, both sides.', 'plays O-O and O-O-O on demand', false, 3),
  ('Plays through a ten-move annotated game from notation alone.', 'reaches the right position', false, 4),
  ('Writes a single move correctly.', '10 moves written, 9 correct', false, 5),
  ('Disambiguates when two pieces can reach the same square, as in Nbd2.', '3 positions', false, 6),
  ('Records a full game on a scoresheet while playing.', 'scoresheet reconstructs the game exactly', false, 7),
  ('Writes the result and signs the scoresheet.', 'done correctly after a game', false, 8),
  ('Checkpoint: plays a game recording every move. A second person replays it from the scoresheet without ambiguity.', 'the scoresheet', true, 9)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '1.6')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Starts a digital clock and presses with the same hand that moved.', 'observed over a full game', false, 1),
  ('Recognises flag fall and knows what it means.', 'states the outcome correctly', false, 2),
  ('Observes touch-move.', 'observed across three games', false, 3),
  ('Says j''adoube before adjusting a piece.', 'observed', false, 4),
  ('Offers a draw correctly: after moving, before pressing the clock.', 'demonstrated', false, 5),
  ('Resigns properly rather than abandoning the board.', 'observed once', false, 6),
  ('Shakes hands before and after, and stays silent during play.', 'observed across a session', false, 7),
  ('Raises a hand for the arbiter rather than arguing.', 'demonstrated in a mock dispute', false, 8),
  ('Checkpoint: one full game under tournament conditions: clock, scoresheet, silence, handshake.', 'coach signature', true, 9)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '1.7')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Understands that mate needs the king pushed to an edge.', 'explains why a centre king cannot be mated by queen and king alone', false, 1),
  ('Two rooks: the lawnmower, rank by rank.', 'mates from 3 starts, under 15 moves', false, 2),
  ('Queen and king: walks the king to the edge with the box method.', 'reduces the box in 3 positions', false, 3),
  ('Queen and king: delivers mate without stalemating.', '3 starts, under 20 moves, no stalemate', false, 4),
  ('Rook and king: uses opposition to force the king back.', 'demonstrates opposition in the ending', false, 5),
  ('Rook and king: delivers mate.', '3 starts, under 25 moves', false, 6),
  ('Back-rank mate with a rook or queen.', 'finds it in 5 puzzles', false, 7),
  ('Makes luft to prevent back-rank mate.', 'spots the danger in her own position and fixes it', false, 8),
  ('Checkpoint: converts all three basic mates against the coach in one sitting, no hints, no stalemate.', 'coach signature, move counts', true, 9)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '1.8')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Identifies every undefended enemy piece in a position.', '5 positions, all found', false, 1),
  ('Takes a free piece when offered.', '10 puzzles', false, 2),
  ('Checks whether a capture is really free before taking.', 'declines 3 poisoned captures', false, 3),
  ('Counts attackers and defenders on a square.', '5 positions', false, 4),
  ('Knight fork on two undefended pieces.', '8/10 puzzles', false, 5),
  ('Pawn fork.', '5/5 puzzles', false, 6),
  ('Queen fork, including the check-and-win pattern.', '8/10', false, 7),
  ('Asks what the opponent''s move threatens, every move.', 'observed thinking aloud for a full game', false, 8),
  ('Checkpoint: twenty one-move puzzles mixing free pieces and forks.', '16/20, score', true, 9)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '1.9')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Opens with a centre pawn.', 'three games in a row', false, 1),
  ('Develops a knight before a rook.', 'observed across three scoresheets', false, 2),
  ('Avoids moving the same piece twice in the opening without reason.', 'coach review of three games', false, 3),
  ('Castles within the first twelve moves.', 'three games', false, 4),
  ('Explains why the early queen sortie loses time.', 'in her own words, with a board', false, 5),
  ('Defends against Scholar''s Mate.', 'survives three attempts by the coach', false, 6),
  ('Connects the rooks.', 'identifies the moment in her own game', false, 7),
  ('Checkpoint: coach reviews three consecutive scoresheets and can see all the principles followed.', 'the three scoresheets', true, 8)
) as i(description, pass_standard, is_checkpoint, sort_order);

-- =======================================================================
-- MODULE 2 — A Real Game
-- =======================================================================
with m as (select id from public.modules where number = 2)
insert into public.units (module_id, number, name, sort_order)
select m.id, u.number, u.name, u.sort_order from m, (values
  ('2.1', 'Tactics with two pieces', 1),
  ('2.2', 'Not losing material', 2),
  ('2.3', 'Mate patterns', 3),
  ('2.4', 'King and pawn endings', 4),
  ('2.5', 'Having a plan', 5),
  ('2.6', 'First tournament', 6)
) as u(number, name, sort_order);

with u as (select id from public.units where number = '2.1')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Absolute pin against the king.', '8/10 puzzles', false, 1),
  ('Relative pin against a bigger piece.', '8/10', false, 2),
  ('Adds an attacker to a pinned piece.', '5 puzzles', false, 3),
  ('Breaks a pin on her own position.', '5 puzzles', false, 4),
  ('Skewer, and how it differs from a pin.', 'explains, then solves 8/10', false, 5),
  ('Discovered attack.', '8/10', false, 6),
  ('Discovered check.', '5/5', false, 7),
  ('Double check, and why only the king can answer it.', 'explains and solves 3 puzzles', false, 8),
  ('Spots the opponent''s tactic before playing her own move.', 'observed in three games', false, 9),
  ('Checkpoint: thirty mixed two-piece tactics.', '24/30, score', true, 10)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '2.2')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Counts a sequence of captures on one square accurately.', '5 positions, correct material count', false, 1),
  ('Decides whether to initiate an exchange based on that count.', '5 positions', false, 2),
  ('Knows when a knight is worth more than a bishop and when it isn''t.', 'explains with two example structures', false, 3),
  ('Avoids trading a good piece for a bad one.', 'coach review of one game', false, 4),
  ('Blunder-check routine before every move: is it hanging, is there a check.', 'observed thinking aloud, full game', false, 5),
  ('Reduces blunders across a month.', 'coach compares two games a month apart', false, 6),
  ('Checkpoint: plays a full game thinking aloud; coach records the blunder check applied on at least 80% of moves.', 'coach tally', true, 7)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '2.3')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Back rank with a deflection sacrifice.', '5 puzzles', false, 1),
  ('Smothered mate, the full Philidor sequence.', 'plays it unprompted', false, 2),
  ('Anastasia''s mate.', '3 puzzles', false, 3),
  ('Arabian mate.', '3 puzzles', false, 4),
  ('Ladder mate with queen and rook.', 'executes from a set position', false, 5),
  ('Mate in two with a quiet first move.', '8/10', false, 6),
  ('Recognises a pattern in her own game rather than in a puzzle.', 'delivers one pattern mate in a club game', false, 7),
  ('Checkpoint: twenty mate-in-one and mate-in-two problems.', '16/20, score', true, 8)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '2.4')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Rule of the square: can the king catch the pawn.', '10/10', false, 1),
  ('Direct opposition, and who wins it.', 'demonstrates on the board', false, 2),
  ('Distant opposition.', '3 positions', false, 3),
  ('Key squares in front of a pawn.', 'identifies them for a pawn on any file', false, 4),
  ('Converts king and pawn versus king when winning.', '5 positions, all converted', false, 5),
  ('Holds the draw when defending.', '5 positions, all held', false, 6),
  ('Knows the rook''s pawn exception.', 'explains and demonstrates the draw', false, 7),
  ('Activates the king once queens are off.', 'observed in a game', false, 8),
  ('Checkpoint: ten king-and-pawn positions, half winning and half drawing, played against the coach.', '8/10 correct results, score', true, 9)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '2.5')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('States a plan aloud after the opening, in one sentence.', 'three games', false, 1),
  ('Identifies her worst-placed piece and improves it.', '5 positions', false, 2),
  ('Finds a target in the opponent''s position.', '5 positions', false, 3),
  ('Chooses between attacking on a wing and playing in the centre.', 'explains the choice in 3 positions', false, 4),
  ('Changes plan when the position changes rather than persisting.', 'coach review of one game', false, 5),
  ('Checkpoint: annotates one of her own games in writing with at least three stated plans.', 'the annotation', true, 6)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '2.6')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Completes a full club tournament, all rounds.', 'attendance record', false, 1),
  ('Submits legible scoresheets for every round.', 'all sheets readable', false, 2),
  ('Manages the clock without flagging in a won position.', 'no time losses in the event', false, 3),
  ('Behaves correctly after a loss: no tears at the board, no blaming.', 'coach observation', false, 4),
  ('Reviews one game from the event with a coach.', 'session completed', false, 5),
  ('Checkpoint: one completed tournament with full scoresheets and a review session.', 'crosstable and scoresheets', true, 6)
) as i(description, pass_standard, is_checkpoint, sort_order);

-- =======================================================================
-- MODULE 3 — Tactics and Structure
-- =======================================================================
with m as (select id from public.modules where number = 3)
insert into public.units (module_id, number, name, sort_order)
select m.id, u.number, u.name, u.sort_order from m, (values
  ('3.1', 'The full tactical vocabulary', 1),
  ('3.2', 'How to calculate', 2),
  ('3.3', 'Pawn structure', 3),
  ('3.4', 'Pieces and squares', 4),
  ('3.5', 'Rook endings that decide club games', 5),
  ('3.6', 'A repertoire as White', 6)
) as u(number, name, sort_order);

with u as (select id from public.units where number = '3.1')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Deflection: forcing a defender away.', '8/10', false, 1),
  ('Decoy: luring a piece onto a bad square.', '8/10', false, 2),
  ('Removing the defender by capture.', '8/10', false, 3),
  ('Overloaded piece defending two things at once.', '8/10', false, 4),
  ('Interference: blocking a defensive line.', '5/10', false, 5),
  ('Zwischenzug, the in-between move.', '6/10', false, 6),
  ('Clearance sacrifice.', '5/10', false, 7),
  ('X-ray and battery.', '6/10', false, 8),
  ('Trapped piece.', '8/10', false, 9),
  ('Desperado.', '5/10', false, 10),
  ('Windmill.', 'solves the classic position', false, 11),
  ('Combines two motifs in one solution.', '5 puzzles', false, 12),
  ('Checkpoint: forty mixed tactics across all twelve motifs, timed at 90 seconds each.', '30/40, score', true, 13)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '3.2')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Lists candidate moves before calculating any.', 'observed on 10 positions', false, 1),
  ('Examines all checks, captures and threats first.', 'observed on 10 positions', false, 2),
  ('Calculates a forcing line to a quiet end position.', '5 positions', false, 3),
  ('Evaluates that end position rather than stopping at the sacrifice.', '5 positions', false, 4),
  ('Considers the opponent''s best reply, not the hoped-for one.', 'coach challenges 5 lines', false, 5),
  ('Calculates a three-move forcing sequence blindfold.', '3 positions', false, 6),
  ('Knows when to stop calculating and make a judgement.', 'explains in 3 positions', false, 7),
  ('Records candidate moves on paper during a long game.', 'one game', false, 8),
  ('Checkpoint: thinks aloud through five unseen positions. Coach verifies candidates listed before lines calculated.', 'in at least four, coach record', true, 9)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '3.3')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Identifies isolated, doubled, backward, passed, connected and hanging pawns.', 'labels all in 5 positions', false, 1),
  ('Names the strength and the weakness of an isolated queen''s pawn.', 'both sides, in her own words', false, 2),
  ('Plays against an IQP: blockade the square, trade pieces.', 'one game from a set position', false, 3),
  ('Plays with an IQP: activity, the d4-d5 break.', 'one game from a set position', false, 4),
  ('Creates a passed pawn from a majority.', '5 positions', false, 5),
  ('Uses the outside passed pawn as a decoy.', '3 positions', false, 6),
  ('Identifies which pawn break is available to each side.', '5 positions', false, 7),
  ('Avoids creating a weakness while attacking.', 'coach review of one game', false, 8),
  ('Recognises a closed centre and plays on the correct wing.', '3 positions', false, 9),
  ('Checkpoint: given six structures, states the correct plan for both sides in writing.', '5/6 judged sound, the written plans', true, 10)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '3.4')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Identifies a weak square in the opponent''s camp.', '5 positions', false, 1),
  ('Establishes a knight on an outpost, supported by a pawn.', 'one game', false, 2),
  ('Opens a file deliberately and occupies it.', 'one game', false, 3),
  ('Doubles rooks on a file.', 'one game', false, 4),
  ('Places a rook on the seventh and explains the value.', 'demonstrated', false, 5),
  ('Distinguishes a good bishop from a bad one.', '5 positions', false, 6),
  ('Trades a bad bishop for a good knight when correct.', '3 positions', false, 7),
  ('Preserves the bishop pair in an open position.', 'explains and demonstrates', false, 8),
  ('Reroutes a knight over three moves to a better square.', 'one game', false, 9),
  ('Checkpoint: annotates one of her own games identifying four piece-placement decisions and judging each.', 'the annotation', true, 10)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '3.5')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Lucena position: builds the bridge.', 'converts from both sides of the board', false, 1),
  ('Philidor position: third-rank defence.', 'holds 3 times', false, 2),
  ('Rook behind the passed pawn, hers and the opponent''s.', 'explains and demonstrates', false, 3),
  ('Cuts the enemy king along a file.', '3 positions', false, 4),
  ('Active rook defence rather than passive.', '3 positions', false, 5),
  ('Knows the short-side and long-side defence.', 'demonstrates both', false, 6),
  ('Converts rook and two pawns versus rook and one.', '3 positions', false, 7),
  ('Checkpoint: plays Lucena and Philidor against the coach, both colours, no hints.', 'all four correct, coach signature', true, 8)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '3.6')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Plays one first move consistently for a month.', 'all scoresheets agree', false, 1),
  ('Knows the main line to move eight and the purpose of each move.', 'explains each move aloud', false, 2),
  ('Has a reply to the two most common defences she meets.', 'demonstrated over the board', false, 3),
  ('Knows one trap in the line and how to avoid falling into it.', 'explains', false, 4),
  ('Plays sensibly when the opponent leaves book on move five.', 'coach sets three off-book positions', false, 5),
  ('Records a new line met and adds it to her file after each event.', 'file shows at least three additions', false, 6),
  ('Checkpoint: plays the repertoire in five consecutive games, no notes, reaching a playable middlegame.', 'in at least four, the five scoresheets', true, 7)
) as i(description, pass_standard, is_checkpoint, sort_order);

-- =======================================================================
-- MODULE 4 — Plans and Preparation
-- =======================================================================
with m as (select id from public.modules where number = 4)
insert into public.units (module_id, number, name, sort_order)
select m.id, u.number, u.name, u.sort_order from m, (values
  ('4.1', 'A repertoire as Black', 1),
  ('4.2', 'Middlegame plans by structure', 2),
  ('4.3', 'Attacking a castled king', 3),
  ('4.4', 'Defence', 4),
  ('4.5', 'Prophylaxis', 5),
  ('4.6', 'More endgames', 6),
  ('4.7', 'Learning from her own games', 7)
) as u(number, name, sort_order);

with u as (select id from public.units where number = '4.1')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Has a defence to 1.e4 and states its main idea.', 'explains the structure it aims for', false, 1),
  ('Knows that defence to move eight in the main line.', 'demonstrated', false, 2),
  ('Has a defence to 1.d4 and states its main idea.', 'explains', false, 3),
  ('Knows that defence to move eight.', 'demonstrated', false, 4),
  ('Has an answer to 1.c4 and 1.Nf3.', 'explains the transposition plan', false, 5),
  ('Knows the typical middlegame plan arising from each defence.', 'explains both', false, 6),
  ('Handles the gambit lines she is likely to meet.', 'coach tests three', false, 7),
  ('Checkpoint: plays her full Black repertoire across five games without notes.', 'scoresheets and the opening file', true, 8)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '4.2')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Carlsbad structure: plays the minority attack as White.', 'one game from the set position', false, 1),
  ('Carlsbad structure: defends as Black with the kingside plan.', 'one game', false, 2),
  ('Hanging pawns: plays with them and against them.', 'two games', false, 3),
  ('Closed centre: plays the correct wing and prepares the break.', 'one game', false, 4),
  ('Open centre: prioritises piece activity over structure.', 'one game', false, 5),
  ('Space advantage: avoids trades and squeezes.', 'one game', false, 6),
  ('Recognises which of these structures her own openings produce.', 'names them for her whole repertoire', false, 7),
  ('Checkpoint: plays five assigned structure positions against the coach, one per structure, then states the correct plan for each.', 'coach record', true, 8)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '4.3')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Counts attackers and defenders around the king before committing.', '5 positions', false, 1),
  ('Greek gift sacrifice: knows the conditions that make it work.', 'lists all three, solves 5 puzzles', false, 2),
  ('Rook lift into the attack.', 'one game', false, 3),
  ('Opens a file towards the king with a pawn sacrifice.', '3 positions', false, 4),
  ('Opposite-side castling: counts tempi in the pawn race.', '3 positions, correct judgement', false, 5),
  ('Knows when not to attack, and improves pieces instead.', '3 positions', false, 6),
  ('Sacrifices on h7, h6 or g7 with a calculated follow-up.', '5 puzzles', false, 7),
  ('Checkpoint: twenty attacking puzzles requiring calculation to mate or decisive material.', '15/20, score', true, 8)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '4.4')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Identifies the opponent''s threat before it lands.', '5 positions', false, 1),
  ('Trades the opponent''s most dangerous attacking piece.', '3 positions', false, 2),
  ('Returns material to kill an attack.', '3 positions', false, 3),
  ('Finds the only move in a forced sequence.', '5 positions', false, 4),
  ('Counterattacks in the centre against a wing attack.', '3 positions', false, 5),
  ('Plays on in a worse position rather than collapsing.', 'coach review of one game', false, 6),
  ('Sets a practical problem for the opponent when objectively lost.', '3 positions', false, 7),
  ('Checkpoint: defends four difficult positions against the coach, holding at least two.', 'results recorded', true, 8)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '4.5')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Asks what the opponent wants to do, every move.', 'observed thinking aloud, full game', false, 1),
  ('Names the opponent''s plan in one sentence.', '5 positions', false, 2),
  ('Plays a move that stops that plan before continuing her own.', '5 positions', false, 3),
  ('Recognises when prevention costs too much.', 'explains in 3 positions', false, 4),
  ('Checkpoint: five positions where the best move is prophylactic. Finds at least three.', 'score', true, 5)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '4.6')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Opposite-coloured bishops: draws a pawn down.', 'holds 3 positions', false, 1),
  ('Opposite-coloured bishops with rooks: knows it favours the attacker.', 'explains, demonstrates', false, 2),
  ('Bishop versus knight in an open position.', 'converts 3 positions', false, 3),
  ('Knight versus bishop in a closed position.', 'converts 3 positions', false, 4),
  ('Queen versus pawn on the seventh: knows which files draw.', 'states the rook and bishop pawn exception, demonstrates', false, 5),
  ('Two bishops versus a lone king.', 'mates inside 25 moves', false, 6),
  ('Trades into a won endgame rather than keeping an unclear middlegame.', 'one game', false, 7),
  ('Checkpoint: eight assigned endings played out against the coach. Correct result in 6.', 'score', true, 8)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '4.7')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Reviews every tournament game within a week.', 'review log complete for one event', false, 1),
  ('Identifies the single move where the game turned.', '3 games, coach agrees with 2', false, 2),
  ('Annotates without an engine first, then checks.', 'two annotations submitted in both forms', false, 3),
  ('Keeps a list of recurring mistakes.', 'list exists with at least five entries', false, 4),
  ('Reviews that list before each event.', 'observed before two events', false, 5),
  ('Checkpoint: submits three annotated games, one win, one draw, one loss, each with the critical moment marked.', 'the annotations', true, 6)
) as i(description, pass_standard, is_checkpoint, sort_order);

-- =======================================================================
-- MODULE 5 — Competitive Player
-- =======================================================================
with m as (select id from public.modules where number = 5)
insert into public.units (module_id, number, name, sort_order)
select m.id, u.number, u.name, u.sort_order from m, (values
  ('5.1', 'Evaluation', 1),
  ('5.2', 'Sacrifices and imbalance', 2),
  ('5.3', 'Complex endgames', 3),
  ('5.4', 'Clock and nerves', 4),
  ('5.5', 'The rules in full', 5)
) as u(number, name, sort_order);

with u as (select id from public.units where number = '5.1')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Evaluates a position across material, king safety, structure, activity and space.', '5 positions, written', false, 1),
  ('Distinguishes static from dynamic advantages.', 'explains with two examples', false, 2),
  ('Knows when a dynamic advantage must be converted before it evaporates.', '3 positions', false, 3),
  ('Judges compensation for sacrificed material.', '5 positions', false, 4),
  ('Disagrees with an engine evaluation and explains her reasoning.', 'one written example', false, 5),
  ('Checkpoint: written evaluations of five unseen positions. Coach judges four as sound.', 'the evaluations', true, 6)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '5.2')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Positional exchange sacrifice for a square or a structure.', '3 positions', false, 1),
  ('Pawn sacrifice for development or initiative.', '3 positions', false, 2),
  ('Playing rook against two minor pieces.', 'one game each side', false, 3),
  ('Playing queen against rook, bishop and pawn.', 'one game', false, 4),
  ('Knows when an unclear sacrifice is a practical weapon rather than a sound one.', 'explains with a real example', false, 5),
  ('Checkpoint: plays four imbalanced positions against the coach from both sides.', 'results recorded', true, 6)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '5.3')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Rook and three pawns versus rook and three, same side.', '3 positions', false, 1),
  ('Rook endings with pawns on both wings.', '3 positions', false, 2),
  ('Fortress recognition and construction.', 'builds two, breaks one', false, 3),
  ('Zugzwang: creates it deliberately.', '5 positions', false, 4),
  ('Triangulation.', 'demonstrates in 2 positions', false, 5),
  ('Transitions: chooses which endgame to enter from a middlegame.', '5 positions', false, 6),
  ('Converts a one-pawn advantage against real resistance.', '3 games against the coach', false, 7),
  ('Checkpoint: six assigned endings, played to the correct result in at least five.', 'score', true, 8)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '5.4')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Plans time use across a long control before the round.', 'written plan for one event', false, 1),
  ('Spends time on critical moves, not obvious recaptures.', 'coach reviews clock times on a scoresheet', false, 2),
  ('Plays an increment endgame without flagging.', 'three games', false, 3),
  ('Recovers from a loss before the next round.', 'coach observation across an event', false, 4),
  ('Keeps a pre-round routine: sleep, food, arrival, warm-up.', 'routine written and followed for one event', false, 5),
  ('Decides draws on standings, not mood.', 'explains two real decisions', false, 6),
  ('Checkpoint: completes a full weekend tournament and submits a written self-review against these six items.', 'the self-review', true, 7)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '5.5')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Knows the illegal-move rule and its penalties.', 'states correctly', false, 1),
  ('Claims a threefold repetition correctly, with the arbiter.', 'mock claim performed', false, 2),
  ('Claims the fifty-move rule correctly.', 'mock claim', false, 3),
  ('Knows the rules on phones, notes and leaving the playing area.', 'states correctly', false, 4),
  ('Knows what happens when a flag falls with insufficient mating material.', 'states correctly', false, 5),
  ('Handles a dispute by calling the arbiter without stopping the clock improperly.', 'mock dispute', false, 6),
  ('Checkpoint: twenty-question rules test drawn from the FIDE Laws.', '17/20, score', true, 7)
) as i(description, pass_standard, is_checkpoint, sort_order);

-- =======================================================================
-- MODULE 6 — Independent Player
-- =======================================================================
with m as (select id from public.modules where number = 6)
insert into public.units (module_id, number, name, sort_order)
select m.id, u.number, u.name, u.sort_order from m, (values
  ('6.1', 'Owning the repertoire', 1),
  ('6.2', 'Preparing for an opponent', 2),
  ('6.3', 'Training herself', 3),
  ('6.4', 'Giving it back', 4),
  ('6.5', 'Final assessment', 5)
) as u(number, name, sort_order);

with u as (select id from public.units where number = '6.1')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Maintains an opening file with main lines, side lines and model games.', 'file reviewed by coach', false, 1),
  ('Adds every new line met within a week of the game.', 'file shows dated additions', false, 2),
  ('Chooses a second option against her most-met opening.', 'demonstrated', false, 3),
  ('Selects openings by tournament need: must-win or must-not-lose.', 'explains two real choices', false, 4),
  ('Retires a line that keeps producing bad positions, with reasons.', 'one written decision', false, 5),
  ('Checkpoint: coach reviews the repertoire file and questions any five lines. Student explains all five.', 'coach record', true, 6)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '6.2')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Finds an opponent''s games from past events.', 'demonstrated for a real opponent', false, 1),
  ('Identifies their repertoire and their weakest line.', 'written preparation', false, 2),
  ('Prepares a specific line to play against them.', 'preparation submitted before the round', false, 3),
  ('Reviews afterwards whether the preparation held.', 'written review', false, 4),
  ('Prepares within a realistic time budget, not all night.', 'coach observation', false, 5),
  ('Checkpoint: submits preparation before a real game and a review after it.', 'both documents', true, 6)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '6.3')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Keeps a weekly training plan covering tactics, endgames and games.', 'four weeks of records', false, 1),
  ('Solves tactics daily with a recorded accuracy rate.', 'log for one month', false, 2),
  ('Studies model games in her own structures, not random ones.', 'names five with reasons', false, 3),
  ('Plays longer games deliberately, not only blitz.', 'game log', false, 4),
  ('Sets a rating or result target and reviews it honestly.', 'written target and review', false, 5),
  ('Checkpoint: a complete training log for two months with an honest self-assessment.', 'the log', true, 6)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '6.4')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Teaches one Module 1 unit to a beginner group under supervision.', 'session observed', false, 1),
  ('Analyses a younger student''s game with them, without taking over.', 'session observed', false, 2),
  ('Assists at a club event: pairings, boards, clocks.', 'one event', false, 3),
  ('Explains a rule correctly to a beginner who has it wrong.', 'observed', false, 4),
  ('Checkpoint: runs one supervised coaching session for beginners.', 'coach observation', true, 5)
) as i(description, pass_standard, is_checkpoint, sort_order);

with u as (select id from public.units where number = '6.5')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Plays a six-game match against a stronger club player.', 'match completed, all games recorded', false, 1),
  ('Annotates every game of that match.', 'six annotations', false, 2),
  ('Sits a mixed examination: tactics, endgames, evaluation, rules.', '70% overall', false, 3),
  ('Presents one of her own games to the club, explaining the plans.', 'presentation delivered', false, 4),
  ('Checkpoint: all four completed. This closes the two-year programme.', 'match scoresheets, annotations, exam score, presentation date', true, 5)
) as i(description, pass_standard, is_checkpoint, sort_order);
