#!/bin/sh

test_description='verify safe.directory checks while running as root'

. ./test-lib.sh
. "$TEST_DIRECTORY"/lib-sudo.sh

if [ "$IKNOWWHATIAMDOING" != "YES" ]
then
	skip_all="You must set env var IKNOWWHATIAMDOING=YES in order to run this test"
	test_done
fi

if ! test_have_prereq NOT_ROOT
then
	skip_all="No, you don't; these tests can't run as root"
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

# this destroys the test environment used above
test_expect_success SUDO 'cleanup regression' '
	sudo rm -rf root
'

if ! test_have_prereq SUDO
then
	skip_all="You need sudo to root for all remaining tests"
	test_done
fi

test_expect_success SUDO 'setup root owned repository' '
	sudo mkdir -p root/p &&
	sudo git init root/p
'

test_expect_success 'cannot access if owned by root' '
	(
		cd root/p &&
		test_must_fail git status
	)
'

test_expect_success SUDO 'cannot access with sudo' '
	(
		# TODO: test_must_fail needs additional functionality
		# 6a67c759489 blocks its use with sudo
		cd root/p &&
		! sudo git status
	)
'

test_expect_success SUDO 'can access using a workaround' '
	# run sudo twice
	(
		cd root/p &&
		run_with_sudo <<-END
			sudo git status
		END
	) &&
	# provide explicit GIT_DIR
	(
		cd root/p &&
		run_with_sudo <<-END
			GIT_DIR=.git &&
			GIT_WORK_TREE=. &&
			export GIT_DIR GIT_WORK_TREE &&
			git status
		END
	) &&
	# discard SUDO_UID
	(
		cd root/p &&
		run_with_sudo <<-END
			unset SUDO_UID &&
			git status
		END
	)
'

# this MUST be always the last test
test_expect_success SUDO 'cleanup' '
	sudo rm -rf root
'

test_done
