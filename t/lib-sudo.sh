# Helpers for running git commands under sudo.

# Runs a scriplet passed through stdin under sudo.
run_with_sudo () {
	local ret
	local SH=${1-"$TEST_SHELL_PATH"}
	local RUN="$HOME/$$.sh"
	write_script "$RUN" "$SH"
	sudo "$SH" -c "\"$RUN\""
	ret=$?
	rm -f "$RUN"
	return $ret
}
