#
# ~/.bash_profile
#

# Source .bashrc if it exists
[[ -f ~/.bashrc ]] && . ~/.bashrc

# Start Hyprland with dbus-run-session only on TTY1
if [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]]; then
    exec dbus-run-session Hyprland
fi

