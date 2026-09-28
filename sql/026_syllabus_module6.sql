-- ===================== 6.1 Owning the repertoire =====================

update public.items set
  how_to_teach = $ht$Teach maintaining a proper opening file: main lines, important side lines, and model games illustrating the resulting middlegame plans, kept organised and current.$ht$,
  how_to_check = $hc$Coach reviews the file for completeness and organisation.$hc$,
  puzzles = $pz$Not applicable -- a record-keeping task.$pz$,
  assignments = $as$Build out the opening file to include main lines, side lines and at least one model game per major line.$as$
where description = 'Maintains an opening file with main lines, side lines and model games.';

update public.items set
  how_to_teach = $ht$Teach the habit of adding any new line met in a real game to the opening file within a week, while it's fresh.$ht$,
  how_to_check = $hc$The file shows dated additions following recent games.$hc$,
  puzzles = $pz$Not applicable -- a record-keeping habit.$pz$,
  assignments = $as$Add any new line met in the next game to the file within a week.$as$
where description = 'Adds every new line met within a week of the game.';

update public.items set
  how_to_teach = $ht$Teach preparing a second option against the opening most commonly faced, to avoid becoming predictable and to have a fallback if the main line is well met.$ht$,
  how_to_check = $hc$Demonstrates the second option and its purpose.$hc$,
  puzzles = $pz$Not applicable -- an opening-preparation task.$pz$,
  assignments = $as$Not required as separate homework -- reinforced through the demonstration.$as$
where description = 'Chooses a second option against her most-met opening.';

update public.items set
  how_to_teach = $ht$Teach selecting which opening to play based on tournament need: a sharper, more ambitious choice in a must-win game, a safer, more solid choice in a must-not-lose game.$ht$,
  how_to_check = $hc$Explains two real opening choices and the tournament-need reasoning behind each.$hc$,
  puzzles = $pz$Not applicable -- a reasoning and reflection task.$pz$,
  assignments = $as$Not required as separate homework -- reinforced through the explanation.$as$
where description = 'Selects openings by tournament need: must-win or must-not-lose.';

update public.items set
  how_to_teach = $ht$Teach recognising when a line in the repertoire consistently produces bad positions and should be retired, with clear reasons rather than abandoning it after one bad result.$ht$,
  how_to_check = $hc$One written decision to retire a line, with reasons.$hc$,
  puzzles = $pz$Not applicable -- a repertoire-review task.$pz$,
  assignments = $as$Not required as separate homework -- produced during the review.$as$
where description = 'Retires a line that keeps producing bad positions, with reasons.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, and the module's test of genuine repertoire ownership rather than memorisation alone.$ht$,
  how_to_check = $hc$Coach reviews the repertoire file and questions any five lines from it; student explains all five, coach record kept.$hc$,
  puzzles = $pz$Not applicable -- this checkpoint is a file review and oral explanation, not puzzles.$pz$,
  assignments = $as$No assignment -- this is the checkpoint itself.$as$
where description = 'Checkpoint: coach reviews the repertoire file and questions any five lines. Student explains all five.';

-- ===================== 6.2 Preparing for an opponent =====================

update public.items set
  how_to_teach = $ht$Teach finding a known opponent's past games using available databases or tournament records, for use in preparation.$ht$,
  how_to_check = $hc$Demonstrates the process for a real upcoming opponent.$hc$,
  puzzles = $pz$Not applicable -- a research-skill task.$pz$,
  assignments = $as$Not required as separate homework -- reinforced through the demonstration.$as$
where description = 'Finds an opponent''s games from past events.';

update public.items set
  how_to_teach = $ht$Teach identifying an opponent's repertoire from their games and finding the line they handle least well.$ht$,
  how_to_check = $hc$Written preparation identifying the opponent's repertoire and weakest line.$hc$,
  puzzles = $pz$Not applicable -- an opponent-preparation task.$pz$,
  assignments = $as$Not required as separate homework -- produced during the preparation.$as$
where description = 'Identifies their repertoire and their weakest line.';

update public.items set
  how_to_teach = $ht$Teach preparing one specific, concrete line to play against the identified weakness, ready to use in the actual game.$ht$,
  how_to_check = $hc$Preparation submitted before the round.$hc$,
  puzzles = $pz$Not applicable -- an opponent-preparation task.$pz$,
  assignments = $as$Submit prepared line before the next relevant round.$as$
where description = 'Prepares a specific line to play against them.';

update public.items set
  how_to_teach = $ht$Teach reviewing honestly, after the game, whether the preparation actually held up against what the opponent played.$ht$,
  how_to_check = $hc$Written review submitted after the game.$hc$,
  puzzles = $pz$Not applicable -- a post-game review task.$pz$,
  assignments = $as$Submit a written review after the prepared game.$as$
where description = 'Reviews afterwards whether the preparation held.';

update public.items set
  how_to_teach = $ht$Teach preparing within a realistic, sustainable time budget rather than working all night before a round, since exhaustion costs more than extra preparation gains.$ht$,
  how_to_check = $hc$Coach observes the time spent preparing stays within a sensible budget.$hc$,
  puzzles = $pz$Not applicable -- a habit observed in practice.$pz$,
  assignments = $as$Not required as separate homework -- observed during the next preparation.$as$
where description = 'Prepares within a realistic time budget, not all night.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, requiring the full preparation cycle -- before and after a real game -- to be documented.$ht$,
  how_to_check = $hc$Submits preparation before a real game and a review after it; both documents required.$hc$,
  puzzles = $pz$Not applicable -- this checkpoint is two written documents, not puzzles.$pz$,
  assignments = $as$No assignment -- this is the checkpoint itself.$as$
where description = 'Checkpoint: submits preparation before a real game and a review after it.';

-- ===================== 6.3 Training herself =====================

update public.items set
  how_to_teach = $ht$Teach structuring a weekly training plan that balances tactics, endgames, and real games, rather than training whatever feels easiest.$ht$,
  how_to_check = $hc$Four weeks of training records showing all three areas covered.$hc$,
  puzzles = $pz$Not applicable -- a planning and record-keeping task.$pz$,
  assignments = $as$Keep a weekly training plan for four weeks covering tactics, endgames and games.$as$
where description = 'Keeps a weekly training plan covering tactics, endgames and games.';

update public.items set
  how_to_teach = $ht$Teach the daily tactics habit with honest accuracy tracking, rather than only counting volume solved.$ht$,
  how_to_check = $hc$A one-month log showing daily tactics with a recorded accuracy rate.$hc$,
  puzzles = $pz$Daily tactics puzzles at an appropriate difficulty level, tracked for accuracy.$pz$,
  assignments = $as$Solve tactics daily for one month, recording the accuracy rate.$as$
where description = 'Solves tactics daily with a recorded accuracy rate.';

update public.items set
  how_to_teach = $ht$Teach selecting model games that arise from the student's own opening repertoire and typical structures, rather than famous games unrelated to what she actually plays.$ht$,
  how_to_check = $hc$Names five model games relevant to her own structures, with reasons for each choice.$hc$,
  puzzles = $pz$Not applicable -- a study-selection task.$pz$,
  assignments = $as$Find and study five model games from her own structures during the month.$as$
where description = 'Studies model games in her own structures, not random ones.';

update public.items set
  how_to_teach = $ht$Teach the value of playing longer time controls deliberately, since blitz alone doesn't build the calculation and endurance longer games require.$ht$,
  how_to_check = $hc$A game log showing regular longer games alongside any blitz played.$hc$,
  puzzles = $pz$Not applicable -- a habit tracked through a game log.$pz$,
  assignments = $as$Play and log at least one longer game per week.$as$
where description = 'Plays longer games deliberately, not only blitz.';

update public.items set
  how_to_teach = $ht$Teach setting a concrete rating or result target and reviewing progress against it honestly, adjusting the target or the training if it isn't being met.$ht$,
  how_to_check = $hc$A written target exists along with an honest review of progress against it.$hc$,
  puzzles = $pz$Not applicable -- a goal-setting and review task.$pz$,
  assignments = $as$Write a target now and review it again at an agreed date.$as$
where description = 'Sets a rating or result target and reviews it honestly.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, and the module's test of sustained self-directed training over an extended period.$ht$,
  how_to_check = $hc$A complete training log for two months with an honest self-assessment at the end.$hc$,
  puzzles = $pz$Not applicable -- this checkpoint is a two-month log and self-assessment, not puzzles.$pz$,
  assignments = $as$No assignment -- this is the checkpoint itself.$as$
where description = 'Checkpoint: a complete training log for two months with an honest self-assessment.';

-- ===================== 6.4 Giving it back =====================

update public.items set
  how_to_teach = $ht$Prepare the student to teach one Module 1 unit to a beginner group under supervision, covering both the content and basic teaching technique.$ht$,
  how_to_check = $hc$Coach observes the session.$hc$,
  puzzles = $pz$Not applicable -- a teaching-practice task.$pz$,
  assignments = $as$Not required as separate homework -- carried out in the observed session.$as$
where description = 'Teaches one Module 1 unit to a beginner group under supervision.';

update public.items set
  how_to_teach = $ht$Teach analysing a younger student's game together with them -- asking questions and guiding their own thinking rather than simply stating the answers or taking over the board.$ht$,
  how_to_check = $hc$Coach observes the session.$hc$,
  puzzles = $pz$Not applicable -- a teaching-practice task.$pz$,
  assignments = $as$Not required as separate homework -- carried out in the observed session.$as$
where description = 'Analyses a younger student''s game with them, without taking over.';

update public.items set
  how_to_teach = $ht$Have the student assist at a real club event with practical organisational tasks: pairings, board setup, and clock management.$ht$,
  how_to_check = $hc$Assists at one club event.$hc$,
  puzzles = $pz$Not applicable -- a practical organisational task.$pz$,
  assignments = $as$Not required as separate homework -- carried out at the event.$as$
where description = 'Assists at a club event: pairings, boards, clocks.';

update public.items set
  how_to_teach = $ht$Teach explaining a rule correctly and patiently to a beginner who currently has it wrong, without embarrassing them.$ht$,
  how_to_check = $hc$Coach observes the explanation.$hc$,
  puzzles = $pz$Not applicable -- a teaching-practice task.$pz$,
  assignments = $as$Not required as separate homework -- carried out when the opportunity arises.$as$
where description = 'Explains a rule correctly to a beginner who has it wrong.';

update public.items set
  how_to_teach = $ht$This is the unit's checkpoint, bringing together the teaching and mentoring skills from this unit into one supervised session.$ht$,
  how_to_check = $hc$Runs one supervised coaching session for beginners; coach observation recorded.$hc$,
  puzzles = $pz$Not applicable -- this checkpoint is a supervised coaching session, not puzzles.$pz$,
  assignments = $as$No assignment -- this is the checkpoint itself.$as$
where description = 'Checkpoint: runs one supervised coaching session for beginners.';

-- ===================== 6.5 Final assessment =====================

update public.items set
  how_to_teach = $ht$Arrange and support a six-game match against a genuinely stronger club player, as the programme's culminating practical test.$ht$,
  how_to_check = $hc$Match completed, all six games recorded on scoresheets.$hc$,
  puzzles = $pz$Not applicable -- this item is the match itself.$pz$,
  assignments = $as$Play the six-game match, one home assignment per scheduled game.$as$
where description = 'Plays a six-game match against a stronger club player.';

update public.items set
  how_to_teach = $ht$Teach annotating the full match, applying the self-annotation skills built throughout the programme to every game rather than just the interesting ones.$ht$,
  how_to_check = $hc$Six annotations submitted, one per match game.$hc$,
  puzzles = $pz$Not applicable -- an own-game review task.$pz$,
  assignments = $as$Annotate each match game within a week of playing it.$as$
where description = 'Annotates every game of that match.';

update public.items set
  how_to_teach = $ht$Prepare the student for a comprehensive mixed examination covering tactics, endgames, evaluation, and rules, drawing on material from across the whole programme.$ht$,
  how_to_check = $hc$Sits the mixed examination; passes with 70% or better overall.$hc$,
  puzzles = $pz$A mixed examination set covering tactics, endgames, evaluation and rules.$pz$,
  assignments = $as$Revise across all four areas ahead of the exam date.$as$
where description = 'Sits a mixed examination: tactics, endgames, evaluation, rules.';

update public.items set
  how_to_teach = $ht$Teach preparing and delivering a short presentation of one of her own games to the club, explaining the plans behind the key decisions to an audience.$ht$,
  how_to_check = $hc$Presentation delivered to the club.$hc$,
  puzzles = $pz$Not applicable -- a presentation task.$pz$,
  assignments = $as$Prepare the presentation ahead of the scheduled date.$as$
where description = 'Presents one of her own games to the club, explaining the plans.';

update public.items set
  how_to_teach = $ht$This is the final checkpoint of the entire two-year programme, requiring all four items of this unit to be complete.$ht$,
  how_to_check = $hc$All four completed: match scoresheets, six annotations, exam score, and presentation date all on record.$hc$,
  puzzles = $pz$Not applicable -- this checkpoint is the culmination of the whole programme, not puzzles.$pz$,
  assignments = $as$No assignment -- this is the checkpoint itself, and the programme's completion.$as$
where description = 'Checkpoint: all four completed. This closes the two-year programme.';
