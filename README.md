# Installing arch linux doc

This document explains how I installed arch linux the first time

## General steps I did

First, I arch iso image

Use rufus to flash it to a usb

Boot target machine from usb, this is live env

Arch gives live env so I can
- Partition
- Mount them
- Install base sys with pacstrap

## Installing iso

Get the torrent file from official site

I install qbittorrent for torrent client

I use client with torrent file to download iso

I verify integrity with the hash in official site

I use windows the verify, windows have built in to get file hash

Difference is not case sensitive btw so "a" and "A" are the same

## Make bootable usb

Use iso and usb to make bootable usb

I use rufus, this is how you make bootable
- I use UEFI, so partition is GPT
- File sys is FAT32
- Write in ISO Image mode

I take it out once its done

## Boot into live env

Plug usb to target machine

Enter BIOS/UEFI settings, I mashed F12
Set boot order to boot from USB first
Save and exit

Pick Arch Linux Install Medium UEFI x86_64

Set font bigger if you want

```bash
setfont ter-132b
```

Check if this machine is really UEFI mode

```bash
ls /sys/firmware/efi
```

Or

```bash
cat sys/firmware/efi/fw-platform_size
```

Output 64? Good! It is UEFI mode

## Connect to wifi

Try to get packets, should fail

```bash
ping google.com
```

I am using wifi so have to rfkill to check if wifi is blocked

Check if wifi interface is down

```bash
ip link
```

If it is check rfkill to see if some are blocked

```bash
rfkill
```

Unblock it

```bash
rfkill unblock wifi
```

Use iwctl to scan router, enter its prompt

```bash
iwctl
```

Then

```bash
device list
# This is your interface, find the one for wifi, should be wlan0
station <device> scan
station <device> get-networks
station <device> connect <SSID>
```

## Set timezone

```bash
timedatectl set-timezone Asia/Jakarta
```

Check if its correct with

```bash
timedatectl
```

## Partition

My target machine was partitioned with Ubuntu installer

So I just have to reformat it to wipe it here
- root
- EFI

```bash
sudo mkfs.ext4 /dev/nvme0n1p2
sudo mkfs.fat -F32 /dev/nvme0n1p1
```

## Mount

Attach partition to a dir

Mount root
```bash
mount /dev/nvme0n1p2 /mnt
```

Mount EFI
```bash
mkdir -p /mnt/boot/efi
mount /dev/nvme0n1p1 /mnt/boot/efi
```

Use lsblk to check partition and mount
```bash
lsblk
p1 -> EFI
p2 -> root
```

## Pick mirrors for download

IMPORTANT

Install reflector
```bash
pacman -Sy reflector
reflector --country "Indonesia" --latest 20 --sort rate --save / etc/pacman.d./mirrorlist
```

## Install base system arch

IMPORTANT

```bash
pacstram /mnt base linux linux-firmware
```

## Install additional packages

IMPORTANT

- CPU microcode for Intel
- Network managers
- nano text editor

```bash
pacstrap -K /mnt base linux linux-firmware intel-ucode networkmanager nano
```

## Make fstab

This is config linux file, for partitions and mounts

```bash
genfstab -U /mnt >> /mnt/etc/fstab
```

## Enter root

Use chroot to change root

```bash
arch-chroot /mnt
```

## Set timezone

Set timezone
```bash
ln -sf /usr/share/zoneinfo/Asia/Jakarta /etc/localtime
```

Generate /etc/adjtime
```bash
hwclock --systohc
```

Set sync
```bash
systemctl enable systemd-timesyncd
```

## Set localization like lang US

Find local I want
```bash
nano /etc/locale.gen
# uncomment this in there en_US.UTF-8 UTF-8
```

Generate locale
```bash
locale-gen
```

Set sys lang
```bash
nano /etc/locale.conf
# Add this
# LANG=en_US.UTF-8
```

Set console keyboard layout
```bash
nano /etc/vconsole.conf
# add this line
# KEYMAP=us
```

## Set hostname

```bash
echo thisisyourhostname > /etc/hostname
```

## Enable network manager

```bash
systemctl enable NetworkManager
```

## Set password

```bash
passwd
```

## Get bootloader

IMPORTANT

I am using single disk, UEFI, so GRUB
```bash
pacman -S grub efibootmgr
```

Install GRUB
```bash
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB
```

Generate its config
```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

## Reboot

Exit change root with "exit" command

Umount everything
```bash
umount -R /mnt
```

```bash
reboot
# plug out the usb before it tries to boot again
```

## Login into arch as root

Use the password you set just now

This is the end of the installation

## Post installation

From here onwards are stuff we put on arch to make it work for me

Put whatever you need after this

## Set editor to nano

```bash
export EDITOR=nano
```

## Allow other user to use sudo

```bash
# open visudo with nano
visudo

# ctrl + w, type and hit enter in nano to search
# uncomment this
# %wheel ALL=(ALL) ALL
# save and exit
```

## Connect to internet

Start and enable network manager
```bash
systemctl enable --now NetworkManager
```

List networks
```bash
nmcli dev wifi
```

Connect to one of em
```bash
nmcli dev wifi connect
"your_wifi_name" password
"your_wifi_password"
```

Check connection
```bash
nmcli connection show
```

## Get sudo

```bash
pacman -S sudo
```

## Add another user other than root

```bash
sudo useradd -m -G wheel -s /bin/bash cliff
sudo passwd cliff
sudo usermod -aG wheel cliff  # to let cliff use sudo
```

## Switch to non root user

```bash
su - cliff
sudo whoami
```

## Get firewall

IMPORTANT
Install ufw
```bash
sudo pacman -S ufw
```

enable it
```bash
sudo systemctl enable ufw
sudo systemctl start ufw
sudo ufw status
# You should see Status: inactive
# This is ok, this just means that the rules are not applied yet
```

Set policies
```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
```

Allow services
```bash
sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 8080
```

Enable firewall
```bash
sudo ufw enable
sudo ufw status
```

## List of services that I use

- network manager
- systemd-timesyncd
- sudo

## I have journal

journalctl is a logging thing that works in background
It has cap max size, if its too big it wraps and overwrites

People tend not to rollback, just read log and try to fix
So make sure to always backup to cloud

## I mainly use pacman

Unless I need something else so I need other package managers

## Get microcode

Install it
```bash
sudo pacman -S intel-ucode
```

Load it at boot
```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

## I retain boot messages, why not right good to see it something f up

Edit systemd config
```bash
sudo nano /etc/systemd/journald.conf
```

Update this to persistent
```conf
[Journal]
Storage=persistent
```

Restart systemd and journald services
```bash
sudo systemctl restart
systemd-journald
```

Read the logs here
```bash
journalctl -b
```

At certain cap max size it wraps and overwrites

## Get GUI

I use hyprland

I do not start these auto, these are manual

I also do not use sessions

I just use window managers

```bash
sudo pacman -S wayland xorg-xwayland hyprland waybar xdg-desktop-portal-hyprland kitty
```

## Check graphic card

```bash
lspci | grep -i vga
```

My machine is using intel graphic, so I did not install any drivers

## XDG_RUNTIME_DIR

I think this is bad consult chatgpt again on this

These are for temp files dir

Manually set env var
```bash
mkdir -p $HOME/.local/state
```

Use nano to update this "~/.bashrc"
```bash
export XDG_RUNTIME_DIR=$HOME/local/state
```

Then apply changes
```bash
source ~/.bashrc
```

## Add user to video group

So that they can run GUI

```bash
sudo usermod -aG video $USER
```

Check permission
```bash
ls -l /dev/dri
```

Reboot
```bash
reboot
```

Then try starting the GUI
```bash
Hyprland
```

Edit the config file, I have commit my edits to remote repo

I did not add wallpaper btw I like the default

## Add waybar, to see battery usage, clock and other meta

Start this auto, write it in hypr/hyprland.conf
- ~/.config/hypr/hyprland.conf

Add this to start once on hyprland start

```bash
exec-once = waybar
```

The edits on waybar are also commited to remote repo

Waybar uses 2 files, one to determine what to render and the other is css
- ~/.config/waybar/config
- /etc/xdg/waybar/style.css

Shortcut to restart waybar
```bash
killall waybar
waybar
```

## Install terminal emulator

I picked kitty

The customization for it is commited to remote repo as well

```bash
~/.config/kitty/kitty.conf
```

## Install firefox

```bash
sudo pacman -S firefox
```

Better to setup audio first before installing browser, check with chatgpt on this

I picked jack2, default

When you enter google serach results, it may be in Indo
```
It is ok since it adjust based on loc
There should be a popup to let you choose if you want to stay in english

## Unmute audio channels

```bash
amixer sset Master unmute
amixer sset Master 50%

## Remove manual XDG_RUNTIME_DIR setup

edit ~/.bashrc and remove
# export XDG_RUNTIME_DIR=$HOME/.local/state

remove the dir too
rm -r ~/.local/state

update ~/.bashrc
```bashrc
# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# Aliases
alias ls='ls --color=auto'
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias grep='grep --color=auto'

# Prompt
PS1='[\u@\h \W]\$ '

# Default editor
export EDITOR=nano

# Add local bin to PATH if exists
if [[ -d "$HOME/.local/bin" ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
```

edit ~/.bash_profile to start hyprland properly on tty login
```bash_profile
#
# ~/.bash_profile
#

# Source .bashrc if it exists
[[ -f ~/.bashrc ]] && . ~/.bashrc

# Start Hyprland with dbus-run-session only on TTY1
if [[ -z $DISPLAY && $XDG_VTNR -eq 1 ]]; then
    exec dbus-run-session Hyprland
fi
```
This starts hyprland only on first login

## Replace jack2 with pipewire

```bash
sudo pacman -S pipewire wireplumber pipewire-audio pipewire-pulse
```

run as user not sudo
```bash
systemctl --user enable --now pipewire pipewire-pulse
```

verify it is running
```bash
systemctl --user status pipewire pipewire-pulse
```

reboot
```bash
reboot
```

check audio output
```bash
pactl info | grep "Server Name"
```

you should see
Server Name: PulseAudio (on Pipewire)

---

## The following is how to maintain this

A **concise, repeatable checklist**. Here's a **step-by-step routine** for weekly or biweekly upkeep. If you just follow these steps regularly, you’ll maintain a **secure and stable system** without overcomplicating things.

---

## 🔁 Arch Maintenance Routine (Repeat Weekly or Biweekly)

### ✅ 1. **Update System Packages**

```bash
sudo pacman -Syu
```

* Reboot if kernel or systemd was updated.
* Don’t skip updates for weeks — it gets risky.

---

### ✅ 2. **Review Security Issues**

```bash
sudo pacman -Q | arch-audit
```

> *(Install with `sudo pacman -S arch-audit` if you haven’t)*

* Check for known vulnerable packages.
* If any are listed, update or research fixes.

---

### ✅ 3. **Check & Clean Package System**

```bash
sudo pacman -Qdtq | sudo pacman -Rns -  # Remove orphans
sudo paccache -r                       # Clean old package cache
```

---

### ✅ 4. **Inspect Firewall Status**

```bash
sudo ufw status verbose
```

* Ensure it’s **enabled** and rules are correct.
* Look for odd open ports or unexpected services.

---

### ✅ 5. **Scan Logs for Errors**

```bash
journalctl -p 3 -xb
```

* Shows current boot errors only.
* Fix any serious system issues if listed.

---

### ✅ 6. **Check System Health**

```bash
systemctl --failed
```

* Ensures no services are failing silently (e.g., audio, network, etc).

---

### ✅ 7. **Backup Configs (Optional but Recommended)**

```bash
cd ~/.config
git add .
git commit -m "Weekly config backup"
git push
```

> Assumes you have a remote repo set up. If not, consider using one.

---

### ✅ 8. **Verify Audio + Network**

Make sure PipeWire and NetworkManager are healthy:

```bash
systemctl --user status pipewire pipewire-pulse
sudo systemctl status NetworkManager
```

---

### ✅ Optional (Monthly)

* `pactl info | grep ServerName` – Ensure PipeWire is still default
* `nmcli` – Check if saved Wi-Fi networks are correct
* Inspect disk space: `df -h` and `du -sh ~/.cache`
* Rotate logs if necessary: `journalctl --vacuum-size=100M`

---

### 🧠 Summary

If you follow the 8-step checklist:

* Your system stays updated & clean
* You catch vulnerabilities early
* Your logs don’t silently fill with issues
* You back up critical configs

---

## Reinstall all pacman packages from here

Better follow the steps here and just use them as reference in case something does not work

dump
```bash
pacman -Qqe > pkglist.txt
```

install
```bash
sudo pacman -S --needed - < pkglist.txt
```
