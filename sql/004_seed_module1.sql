-- Parent Portal — Module 1 seed data
-- Run after 003_policies.sql. Modules 2-6 are seeded separately once their
-- curriculum is supplied (see docs/curriculum.md if it exists, otherwise
-- send the unit/item text and it will be added the same way).

insert into public.modules (number, name) values (1, 'Foundations');

with m as (select id from public.modules where number = 1)
insert into public.units (module_id, number, name, sort_order)
select m.id, u.number, u.name, u.sort_order
from m, (values
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

-- 1.1 The board
with u as (select id from public.units where number = '1.1')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Sets up the starting position from an empty board.', '3/3 correct setups, unprompted', false, 1),
  ('Names every file and rank when the coach points at random squares.', '8/10 squares, under 5 seconds each', false, 2),
  ('Points to a named square (e.g. "e4") without counting aloud.', '8/10 correct', false, 3),
  ('Identifies the four centre squares and says why they matter.', 'names all 4, gives one valid reason', false, 4),
  ('Traces a diagonal, a file and a rank on request.', '6/6 correct across 2 sessions', false, 5),
  ('Checkpoint: sets up the full starting position from memory, correct orientation, unaided.', 'under 2 minutes, correct orientation', true, 6)
) as i(description, pass_standard, is_checkpoint, sort_order);

-- 1.2 How each piece moves
with u as (select id from public.units where number = '1.2')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Demonstrates every legal move of the rook from a mid-board square.', 'shows all 4 directions, stops at first blocker', false, 1),
  ('Demonstrates every legal move of the bishop, including that it stays on one colour.', 'names the colour, shows all diagonals', false, 2),
  ('Demonstrates the queen''s moves as rook-plus-bishop combined.', '8/8 sample squares correct', false, 3),
  ('Demonstrates the knight''s L-shaped move from at least four different squares, including one near the edge.', 'correct from 4/4 squares, including one edge square', false, 4),
  ('Demonstrates the king''s one-square move in all eight directions.', '8/8 directions shown', false, 5),
  ('Demonstrates pawn moves: one square forward, two from its start square, and diagonal capture.', 'shows single push, double push and a diagonal capture', false, 6),
  ('Checkpoint: given any piece on any square, states every legal destination correctly.', 'correct for 5/5 random piece-and-square draws', true, 7)
) as i(description, pass_standard, is_checkpoint, sort_order);

-- 1.3 Check, mate, stalemate
with u as (select id from public.units where number = '1.3')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Recognises when their own king is in check and says how they know.', '5/5 positions identified', false, 1),
  ('Gets out of check three ways: block, capture, move the king.', 'demonstrates all three methods once each', false, 2),
  ('Recognises checkmate and explains why no escape exists.', '4/5 positions, correct reason each time', false, 3),
  ('Recognises stalemate and distinguishes it from checkmate.', '4/5 positions correctly labelled', false, 4),
  ('States the result (win, loss, draw) for a stalemate versus a checkmate.', '3/3 correct', false, 5),
  ('Checkpoint: delivers checkmate in one from a set of practical positions.', '6/8 checkmates found, correct move stated', true, 6)
) as i(description, pass_standard, is_checkpoint, sort_order);

-- 1.4 Special moves
with u as (select id from public.units where number = '1.4')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Performs castling correctly on both sides, king and rook moving together.', 'castles both sides without help', false, 1),
  ('States all three conditions that block castling (king moved, rook moved, squares attacked or occupied).', 'names 3/3 conditions', false, 2),
  ('Performs en passant when the position allows it and explains when it stops being available.', 'executes it correctly, states the one-move window', false, 3),
  ('Promotes a pawn reaching the last rank to a piece of their choice, including under-promotion.', 'promotes correctly in 3/3 examples, explains under-promotion once', false, 4),
  ('Distinguishes moves that look special but aren''t (e.g. a queen ending on the back rank).', '3/3 correct', false, 5),
  ('Checkpoint: given five mixed positions, correctly plays castling, en passant or promotion as required.', '5/5 positions', true, 6)
) as i(description, pass_standard, is_checkpoint, sort_order);

-- 1.5 Notation
with u as (select id from public.units where number = '1.5')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Reads algebraic square names off the board without hesitation.', '10/10 squares, under 5 seconds each', false, 1),
  ('Writes down a short sequence of moves played on the board.', 'records 5 moves with no errors', false, 2),
  ('Reads a short written game and reproduces it correctly on the board.', '10 moves replayed with no errors', false, 3),
  ('Uses the symbols for capture, check and checkmate correctly (x, +, #).', 'uses all three correctly in one recorded game', false, 4),
  ('Checkpoint: keeps a complete, legible scoresheet for one full game, unprompted.', 'full game recorded, coach can replay it', true, 5)
) as i(description, pass_standard, is_checkpoint, sort_order);

-- 1.6 Club conduct and the clock
with u as (select id from public.units where number = '1.6')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Greets an opponent before the game and shakes hands or acknowledges the result after.', 'observed twice, unprompted', false, 1),
  ('Presses the clock with the same hand used to move, after every move.', 'consistent for a full game', false, 2),
  ('States what to do if they touch a piece they didn''t mean to move.', 'states the touch-move rule correctly', false, 3),
  ('Stays silent and doesn''t advise during another player''s game.', 'observed over one full session', false, 4),
  ('Resigns, or offers and accepts a draw appropriately, when a coach sets up the situation.', 'responds appropriately in 2/2 scenarios', false, 5),
  ('Checkpoint: plays one full clocked game following every conduct and clock rule above without a reminder.', 'one full game, zero reminders needed', true, 6)
) as i(description, pass_standard, is_checkpoint, sort_order);

-- 1.7 First checkmates
with u as (select id from public.units where number = '1.7')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Delivers checkmate with king and queen against a lone king.', '6/8 attempts, no stalemate given', false, 1),
  ('Delivers checkmate with king and rook against a lone king.', '6/8 attempts, no stalemate given', false, 2),
  ('Avoids stalemating the lone king while pushing it to the edge.', '3 consecutive attempts with no stalemate', false, 3),
  ('Explains the "box" or "fence" technique used to push the king back.', 'explains it correctly once', false, 4),
  ('Checkpoint: mates with king and queen or king and rook against a coach playing the lone king, from a random start.', '2/3 attempts mated within 15 moves', true, 5)
) as i(description, pass_standard, is_checkpoint, sort_order);

-- 1.8 Seeing one move ahead
with u as (select id from public.units where number = '1.8')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('Spots a hanging (undefended) piece on the board.', '8/10 positions', false, 1),
  ('Spots a one-move checkmate available to them.', '8/10 puzzles', false, 2),
  ('Spots a one-move capture that wins material.', '8/10 puzzles', false, 3),
  ('Checks whether a move they''re about to make hangs a piece, before making it.', 'observed doing this unprompted across one session', false, 4),
  ('Solves one-move puzzles set by the coach within a time limit.', '8/10 puzzles, under 30 seconds each', false, 5),
  ('Checkpoint: in a live game, avoids all one-move blunders for the first ten moves.', 'no one-move blunder in first 10 moves, two games', true, 6)
) as i(description, pass_standard, is_checkpoint, sort_order);

-- 1.9 Starting a game properly
with u as (select id from public.units where number = '1.9')
insert into public.items (unit_id, description, pass_standard, is_checkpoint, sort_order)
select u.id, i.description, i.pass_standard, i.is_checkpoint, i.sort_order from u, (values
  ('States and applies the opening priorities: control the centre, develop pieces, keep the king safe.', 'states all 3, applies at least 2 in a game', false, 1),
  ('Develops a minor piece (knight or bishop) before moving the same piece twice.', 'observed across one full game', false, 2),
  ('Castles within the first ten moves when the position allows it.', 'castles by move 10 in 2/2 games', false, 3),
  ('Avoids moving the queen out early where it can be attacked with a gain of tempo.', 'no early queen sortie in 2/2 games', false, 4),
  ('Explains why moving the same pawn or piece repeatedly in the opening loses time.', 'gives a correct reason', false, 5),
  ('Checkpoint: plays a full opening (first ten moves) against a coach, following every priority above.', '10 moves played, all priorities followed, one game', true, 6)
) as i(description, pass_standard, is_checkpoint, sort_order);
