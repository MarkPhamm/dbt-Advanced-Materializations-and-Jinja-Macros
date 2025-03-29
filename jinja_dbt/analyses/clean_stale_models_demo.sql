-- This analysis demonstrates the clean_stale_models macro
-- It will show what would be dropped (in dry-run mode) for objects older than 7 days

{% do clean_stale_models(days = 7) %}