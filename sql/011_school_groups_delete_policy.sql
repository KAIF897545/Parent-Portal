-- Parent Portal — allow admin to delete class groups
--
-- Insert/update policies for school_groups already existed; delete was
-- missing, so admin.js's "remove group" button had nothing to work with
-- (a delete with no matching RLS policy just silently affects 0 rows).
-- group_id has no ON DELETE cascade from students, so removing a group
-- that still has students in it fails with a foreign key violation —
-- the client maps that to a friendly message rather than letting it
-- through as a silent no-op.

create policy school_groups_delete_admin on public.school_groups
  for delete to authenticated using (public.is_admin());
