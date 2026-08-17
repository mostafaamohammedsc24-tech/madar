-- EXAMPLE ONLY — do not commit real secrets.
-- After applying migration 010_system_admin_bootstrap.sql, open Supabase SQL Editor and run:
--
--   SELECT system_admin_complete_bootstrap('<secret>');
--
-- Expected result: success=true, employee_code=SYS-001
-- Then log in via the Employee app with Employee ID SYS-001 or phone 07740080310.
-- Rotate the secret after first login.

SELECT system_admin_complete_bootstrap('<REPLACE_WITH_SECRET>');
