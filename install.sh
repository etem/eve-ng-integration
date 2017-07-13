#!/bin/sh
#
# This script is meant for quick & easy install via:
#   'curl -sSL https://raw.githubusercontent.com/SmartFinn/eve-ng-integration/master/install.sh | sh'
# or:
#   'wget -qO- https://raw.githubusercontent.com/SmartFinn/eve-ng-integration/master/install.sh | sh'

set -e

URL="https://github.com/etem/eve-ng-integration/archive/master.tar.gz"

# add sudo if user is not root
[ "$(whoami)" = root ] || SUDO="sudo"

command_exists() { command -v "$@" > /dev/null 2>&1; }
verbose() { echo "=>" "$@"; }
die() { echo "$@" >&2; exit 1; }

is_unsupported() {
	cat <<-'EOF' >&2

	Your Linux distribution is not supported.

	Feel free to ask support for it by opening an issue at:
	  https://github.com/SmartFinn/eve-ng-integration/issues

	EOF
	exit 1
}

do_install() {
	temp_dir=$(mktemp -d)

	verbose "Download and extract into '$temp_dir'..."
	if command_exists wget; then
		wget -qO- "$URL" | tar --strip-components=1 -C "$temp_dir" -xzf -
	else
		curl -sL "$URL" | tar --strip-components=1 -C "$temp_dir" -xzf -
	fi

	verbose "Installing..."
	eval $SUDO install -m 755 -D "$temp_dir"/eve-ng-integration /usr/bin/
	eval $SUDO install -m 644 -D "$temp_dir"/eve-ng-integration.desktop \
		/usr/share/applications/

	eval $SUDO update-desktop-database -q || true

	verbose "Remove '$temp_dir'..."
	if [ -d "$temp_dir" ]; then
		rm -rf "$temp_dir"
	fi

	verbose "Complete!"

	cat <<-'EOF'

	  Do not forget add the user to the wireshark group:

	    # You will need to log out and then log back in
	    # again for this change to take effect.
	    sudo usermod -a -G wireshark $USER

	EOF

	exit 0
}

# Detect Linux distribution
if [ -r /etc/os-release ]; then
	. /etc/os-release
elif command_exists lsb_release; then
	ID=$(lsb_release -si)
	VERSION_ID=$(lsb_release -sr)
else
	is_unsupported
fi

verbose "Detected distribution: $ID $VERSION_ID (${ID_LIKE:-"none"})"

# Check if python is installed
if command_exists python; then
	# create variable
	PYTHON=""
fi

for dist_id in $ID $ID_LIKE; do
	case "$dist_id" in
		debian|ubuntu)
			verbose "Install dependencies..."
			eval $SUDO apt-get install -y ${PYTHON="python"} \
				ssh-askpass telnet vinagre wireshark
			do_install
			;;
		arch|archlinux|manjaro)
			verbose "Install dependencies..."
			eval $SUDO pacman -S ${PYTHON="python"} \
				inetutils vinagre wireshark-qt x11-ssh-askpass
			do_install
			;;
		fedora)
			verbose "Install dependencies..."
			eval $SUDO dnf install -y ${PYTHON="python"} \
				openssh-askpass telnet vinagre wireshark-qt
			do_install
			;;
		opensuse|suse)
			verbose "Install dependencies..."
			eval $SUDO zypper install -y ${PYTHON="python"} \
				openssh-askpass telnet vinagre wireshark-ui-qt
			do_install
			;;
		centos|CentOS|rhel)
			verbose "Install dependencies..."
			eval $SUDO yum install -y ${PYTHON="python"} \
				openssh-askpass telnet vinagre wireshark-gnome
			do_install
			;;
		*)
			continue
			;;
	esac
done

is_unsupported
