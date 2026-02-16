#!/bin/bash

gsettings set org.gnome.desktop.peripherals.mouse accel-profile 'flat'
gsettings set org.gnome.desktop.interface document-font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface font-antialiasing 'rgba'
gsettings set org.gnome.desktop.interface font-hinting 'full'
gsettings set org.gnome.desktop.interface font-name 'Ubuntu 11'
gsettings set org.gnome.desktop.interface monospace-font-name 'JetBrains Mono 11'
gsettings set org.gnome.desktop.interface toolkit-accessibility false
gsettings set org.gnome.desktop.peripherals.keyboard numlock-state true
gsettings set org.gnome.desktop.peripherals.keyboard remember-numlock-state true
gsettings set org.gnome.desktop.screensaver lock-enabled false
gsettings set org.gnome.settings-daemon.plugins.housekeeping donation-reminder-enabled false
gsettings set org.gnome.desktop.wm.preferences button-layout 'appmenu:minimize,maximize,close'
gsettings set org.gnome.shell enabled-extensions "['background-logo@fedorahosted.org', 'dash-to-dock@micxgx.gmail.com', 'clipboard-indicator@tudmotu.com', 'ding@rastersoft.com']"
gsettings set org.gnome.desktop.input-sources mru-sources "[('xkb', 'ru'), ('xkb', 'us')]"
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'ru'), ('xkb', 'us')]"
gsettings set org.gnome.desktop.input-sources xkb-options "['kpdl:dotoss']"
gsettings set org.gnome.shell favorite-apps "['brave-browser.desktop', 'obsidian.desktop', 'md.obsidian.Obsidian.desktop', 'spotify-launcher.desktop', 'com.spotify.Client.desktop', 'steam.desktop', 'code.desktop', 'com.obsproject.Studio.desktop', 'org.gnome.Nautilus.desktop', 'org.gnome.Software.desktop', 'org.gnome.TextEditor.desktop', 'org.gnome.Calculator.desktop']"