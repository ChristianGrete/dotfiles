#
# The ~/.profile dotfile:
# A POSIX compliant profile for login shells.
#

#
# Defining the ENV file
#

# Set the ~/.rc dotfile to be the ENV file and name it in SHINIT as well (for portability)
export ENV="$HOME/.rc"
export SHINIT="$ENV"

# Note: These lines should be left on the very end of this file to make clear that the ~/.rc file is parsed afterwards
