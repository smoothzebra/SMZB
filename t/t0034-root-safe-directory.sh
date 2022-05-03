#!/bin/sh

test_description='verify safe.directory checks while running as root'

. ./test-lib.sh

if [ "$IKNOWWHATIAMDOING" != "YES" ]
then
	skip_all="You must set env var IKNOWWHATIAMDOING=YES in order to run this test"
	test_done
fi

# this prerequisite should be added to all the tests, it not only prevents
# the test from failing but also warms up any authentication cache sudo
# might need to avoid asking for a password
test_lazy_prereq SUDO '
	sudo -n id -u >u &&
	id -u root >r &&
	test_cmp u r &&
	command -v git >u &&
	sudo command -v git >r &&
	test_cmp u r
'

test_expect_success SUDO 'setup' '
	sudo rm -rf root &&
	mkdir -p root/r &&
	sudo chown root root &&
	(
		cd root/r &&
		git init
	)
'

test_expect_success SUDO 'sudo git status as original owner' '
	(
		cd root/r &&
		git status &&
		sudo git status
	)
'

# this MUST be always the last test, if used more than once, the next
# test should do a full setup again.
test_expect_success SUDO 'cleanup' '
	sudo rm -rf root
'

test_done
