# Shared boolean interpretation for OTBR env flags.
# Sourced by service run scripts; not meant to be executed directly.
#
# Falsy (case-insensitive): 0, empty, false, no, off.
# Everything else is truthy. This gives RCP_USE_TCP and friends ONE consistent
# meaning across every script, instead of the previous mix of `-gt`, `-eq` and
# `==` that disagreed on values like "false", "00" or "2" and could even abort
# a script under `set -e` with "integer expression expected".
otbr_is_true() {
	local v="${1:-}"
	case "${v,,}" in
		0|''|false|no|off) return 1 ;;
		*) return 0 ;;
	esac
}
