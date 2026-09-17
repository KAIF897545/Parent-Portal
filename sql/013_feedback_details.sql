-- Parent Portal — richer monthly feedback
--
-- Coaches could only leave a single paragraph of monthly feedback. Adds
-- three optional fields alongside it so a monthly note can carry more
-- than prose: a 1-5 effort/growth rating, a one-line highlight (the
-- month's biggest win), and a one-line focus for next month. All three
-- are nullable — existing feedback rows and the plain-paragraph flow
-- keep working unchanged.

alter table public.feedback
  add column rating     smallint check (rating between 1 and 5),
  add column highlight  text,
  add column next_focus text;
