## Using i3 as window manager for KDE Plasma > 5.25
# Note that for this method, you do not need to be the root user. However, that means the changes will not effect the other users.
#
# Create a new service file called plasma-i3.service in $HOME/.config/systemd/user.
#
# Write the following into $HOME/.config/systemd/user/plasma-i3.service:

# [Unit]
# Description=Launch Plasma with i3
# Before=plasma-workspace.target
#
# [Service]
# ExecStart=/usr/bin/i3
# Restart=on-failure

# [Install]
# WantedBy=plasma-workspace.target
#



# Mask plasma-kwin_x11.service by running systemctl mask plasma-kwin_x11.service --user
systemctl mask plasma-kwin_x11.service --user
# Enable the plasma-i3 service by running systemctl enable plasma-i3 --user
systemctl enable plasma-i3 --user

# To go back to KWin, just unmask the plasma-kwin_x11.service and disable your plasma-i3 service in the same way.
