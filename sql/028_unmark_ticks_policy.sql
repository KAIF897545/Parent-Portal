-- Parent Portal -- allow coaches to unmark an accidental tick / checkpoint pass
--
-- item_ticks and checkpoint_passes had select/insert/update policies but no
-- delete policy, so a mis-tapped checklist item could never be undone. Uses
-- the same can_manage_student authorization as the existing update policies
-- (any coach/admin at the student's school), matching feedback_delete in 015.

create policy item_ticks_delete on public.item_ticks
  for delete to authenticated
  using (public.can_manage_student(student_id));

create policy checkpoint_passes_delete on public.checkpoint_passes
  for delete to authenticated
  using (public.can_manage_student(student_id));
