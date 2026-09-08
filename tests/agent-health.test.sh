#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

SCRIPT="$ROOT/scripts/agent-health"
LINK_SCRIPT="$ROOT/scripts/link-agent-health"
TMP=$(dotfiles_test_tmproot agent-health)
STATE="$TMP/state"

file_mode() {
	case $(uname -s) in
	Darwin) stat -f '%Lp' "$1" ;;
	*) stat -c '%a' "$1" ;;
	esac
}

test -x "$SCRIPT" || fail 'agent-health is not executable'
test -x "$LINK_SCRIPT" || fail 'link-agent-health is not executable'

link="$TMP/bin/agent-health"
AGENT_HEALTH_LINK="$link" "$LINK_SCRIPT" >"$TMP/link.out"
[ -L "$link" ] || fail 'link-agent-health did not create a symlink'
[ "$(readlink "$link")" = "$SCRIPT" ] ||
	fail 'link-agent-health did not keep the repository script authoritative'
"$link" --help >/dev/null ||
	fail 'the linked agent-health command is not executable'

regular="$TMP/regular-agent-health"
printf 'owned elsewhere\n' >"$regular"
if AGENT_HEALTH_LINK="$regular" "$LINK_SCRIPT" >"$TMP/conflict.out" 2>&1; then
	fail 'link-agent-health replaced an unowned regular file'
fi
[ "$(cat "$regular")" = 'owned elsewhere' ] ||
	fail 'link-agent-health changed an unowned regular file'
rg -q 'refusing to replace non-symlink' "$TMP/conflict.out" ||
	fail 'link-agent-health did not explain the conflict'

# Sampling reads /proc, so only a Linux host can prove the metrics. Everywhere
# else, prove the refusal instead: a silent skip would hide a sample path that
# started writing garbage rather than exiting.
if [ "$(uname -s)" = Linux ] && [ -r /proc/stat ]; then
	sampling='records private bounded samples'

	AGENT_HEALTH_STATE_DIR="$STATE" \
		AGENT_HEALTH_SAMPLE_SECONDS=0.05 \
		"$SCRIPT" sample

	sample_file=$(find "$STATE" -maxdepth 1 -name 'samples-*.jsonl' -type f -print -quit)
	[ -n "$sample_file" ] || fail 'agent-health did not write a daily sample file'
	[ "$(file_mode "$STATE")" = 700 ] ||
		fail 'agent-health state directory is not private'
	[ "$(file_mode "$sample_file")" = 600 ] ||
		fail 'agent-health sample file is not private'

	jq -e '
		.schema == 2
		and (.timestamp | type == "string")
		and (.sample_seconds > 0)
		and (.cpu_busy_pct >= 0 and .cpu_busy_pct <= 100)
		and (.memory_available_pct >= 0 and .memory_available_pct <= 100)
		and (.io_pressure_some_pct >= 0)
		and (.disk_used_pct >= 0 and .disk_used_pct <= 100)
		and (.agent_instances >= 0)
	' "$sample_file" >/dev/null ||
		fail 'agent-health sample does not contain the expected bounded metrics'

	AGENT_HEALTH_STATE_DIR="$STATE" \
		AGENT_HEALTH_SAMPLE_SECONDS=0.05 \
		"$SCRIPT" sample

	AGENT_HEALTH_STATE_DIR="$STATE" "$SCRIPT" report --hours 24 >"$TMP/report.txt"
	rg -q '^Host verdict: ' "$TMP/report.txt" ||
		fail 'agent-health text report lacks a verdict'
	rg -q '^CPU: ' "$TMP/report.txt" ||
		fail 'agent-health text report lacks CPU evidence'
	rg -q '^I/O: ' "$TMP/report.txt" ||
		fail 'agent-health text report lacks I/O evidence'
	rg -q 'agent instances p95 ' "$TMP/report.txt" ||
		fail 'agent-health text report lacks agent-concurrency evidence'

	AGENT_HEALTH_STATE_DIR="$STATE" "$SCRIPT" report --hours 24 --json >"$TMP/report.json"
	jq -e '
		.samples == 2
		and (.verdict.code | type == "string")
		and (.cpu_busy_pct_p95 >= 0)
		and (.memory_available_pct_min >= 0)
		and (.io_pressure_full_pct_p95 >= 0)
		and (.agent_instances_p95 >= 0)
	' "$TMP/report.json" >/dev/null ||
		fail 'agent-health JSON report is incomplete'
else
	sampling='refuses to sample without /proc'

	if AGENT_HEALTH_STATE_DIR="$STATE" AGENT_HEALTH_SAMPLE_SECONDS=0.05 \
		"$SCRIPT" sample >"$TMP/sample.out" 2>&1; then
		fail 'agent-health sampled on a host with no /proc'
	fi
	rg -q 'requires Linux with /proc' "$TMP/sample.out" ||
		fail 'agent-health did not explain that sampling needs /proc'
	[ ! -d "$STATE" ] || fail 'a refused sample still created the state directory'
fi

classify_state="$TMP/classify-state"
mkdir -m 700 "$classify_state"
timestamp=$(date -u '+%Y-%m-%dT%H:%M:%S+00:00')
cat >"$classify_state/samples-$(date -u '+%Y-%m-%d').jsonl" <<EOF
{"schema":2,"timestamp":"$timestamp","sample_seconds":1,"cpu_busy_pct":40,"load_per_cpu":0.5,"cpu_pressure_pct":0,"memory_available_pct":40,"memory_pressure_pct":5,"io_pressure_some_pct":30,"io_pressure_full_pct":20,"disk_used_pct":50,"agent_instances":10,"top_io_command":"cp","top_io_mib_s":100}
EOF
chmod 600 "$classify_state"/samples-*.jsonl
AGENT_HEALTH_STATE_DIR="$classify_state" \
	"$SCRIPT" report --hours 24 --json >"$TMP/classify-report.json"
jq -e '.verdict.code == "io_contention"' "$TMP/classify-report.json" >/dev/null ||
	fail 'agent-health blamed memory with ample memory available instead of I/O contention'

pass "agent-health links safely, $sampling, and explains host bottlenecks"
