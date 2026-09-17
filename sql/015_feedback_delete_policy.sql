-- Parent Portal — allow coaches to delete a feedback entry
--
-- feedback already has select/insert/update policies (003_policies.sql),
-- added ahead of an editing UI that never shipped until now, but no delete
-- policy — a coach could never remove a mistaken entry. Uses the same
-- can_manage_student authorization as feedback_update (any coach/admin at
-- the school, not just the original author), for consistency.

create policy feedback_delete on public.feedback
  for delete to authenticated
  using (public.can_manage_student(student_id));
