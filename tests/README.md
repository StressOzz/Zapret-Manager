# Forkozz regression check

Run `node tests/legacy-bypass.cjs` (Node.js built-ins only).

The check extracts the actual `legacy_bypass_info` helper from the installer,
runs its JavaScript-compatible subset with a mocked UCI cursor, and parses the
generated Forkozz LuCI page. It covers legacy exclusions, disabled exclusions,
the managed `zm_bypass` section, unrelated section types, list deduplication,
empty configuration, and read-only access.

This is not a native ucode or browser integration test. On a test router, add an
enabled and a disabled `connection_type=exclusion` section with synthetic domains,
subnets and list references. Open Forkozz → Исключения and verify both appear with
their status and read-only fields. Compare `uci export netshift` before and after
opening the page and saving the existing Forkozz exclusion fields: the legacy
sections must remain unchanged. No automatic migration or routing change is intended.
