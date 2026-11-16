# The login environment: the variables a terminal starts with, which
# /etc/login-environment.sh builds (modules/features/session.nix).
#
# An agent's harness inherits its environment from the app that started it. An
# app that opens at login starts before those variables are exported, and one
# started before the last switch holds the old ones. So an agent's commands load
# the file themselves, and do not depend on when their app started.

# The POSIX line that loads the login environment. It does nothing on a machine
# without the file.
export def load-line [
	file: path = '/etc/login-environment.sh' # the file that builds the login environment
]: nothing -> string {
	$"[ ! -r '($file)' ] || . '($file)'"
}
