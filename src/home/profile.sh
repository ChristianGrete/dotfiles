#
# The ~/.profile dotfile:
# A POSIX compliant profile for login shells.
#

#
# Define the `$ENV` file
#

# Set the "~/.rc" dotfile to be the `$ENV` file and reference it in `$SHINIT` as
# well (for portability reasons)
export ENV="$HOME/.rc"
export SHINIT="$ENV"

#
# NOTE:
#   The two lines above should be left on the very end of this file to make
#   clear that the "~/.rc" file is parsed afterwards.
#
