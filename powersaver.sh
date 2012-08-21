#!/bin/bash

# Root user check for install 
USERCHECK=$( whoami  )
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as ROOT"
        echo "You have attempted to run this as $USERCHECK"
                echo "use sudo $0 $1 or change to root."
   exit 1
fi

CPUFREQ=$(which cpufreq-set)
ETHTOOL=$(which ethtool)
WCONFIG=$(which wconfig)

case $1 in

base)
# BASE Configuration
        if [ $CPUFREQ ];then
                # Lower the govoner settings
                        $CPUFREQ -r -g conservative;
        fi
        if [ /sys/class/leds/smc::kbd_backlight/brightness ];then
                # Turn the backlight down
                        echo '100' > /sys/class/leds/smc::kbd_backlight/brightness
        fi
        # To enable USB autosuspend after 2 seconds of inactivity
                for i in `find /sys/bus/usb/devices/*/power/control`; do echo 'auto' > $i; done;
                for i in `find /sys/bus/usb/devices/*/power/autosuspend`; do echo '2' > $i; done;
        # Device Power Management
                echo auto | tee /sys/bus/i2c/devices/*/power/control > /dev/null
                echo auto | tee /sys/bus/pci/devices/*/power/control > /dev/null
        # Runtime Power Management
                for i in `find /sys/devices/*/power/control`; do echo 'auto' > $i; done;
        # To set the VM dirty writeback time to 15 seconds
                echo '1500' > /proc/sys/vm/dirty_writeback_centisecs
        # Laptop Mode
                echo '5' > /proc/sys/vm/laptop_mode
        if [ $ETHTOOL ];then
                # To disable Wake on LAN on eth adapter
                for ETHADP in `ip addr|awk '/eth[0-9]/ {print $2}'|sed 's/://g'`; do ethtool -s ${ETHADP} wol d; done;
        fi
        # SATA Active Link Powermanagement
                for i in `find /sys/class/scsi_host/host*/link_power_management_policy`; do echo 'min_power' > $i; done 
        # NMI Watchdog
                echo '1' > /proc/sys/kernel/nmi_watchdog

;;

critical)
        if [ $CPUFREQ ];then
                # Lower the govoner settings
                $CPUFREQ -r -g powersave;
        fi
        if [ /sys/class/leds/smc::kbd_backlight/brightness ];then
                # Turn the backlight down
                        echo '0' > /sys/class/leds/smc::kbd_backlight/brightness
        fi
        # Intel HDA
                echo '1' > /sys/module/snd_hda_intel/parameters/power_save
        # SATA Active Link Powermanagement
                for i in `find /sys/class/scsi_host/host*/link_power_management_policy`; do echo 'min_power' > $i; done
        # NMI Watchdog
                echo '0' > /proc/sys/kernel/nmi_watchdog
        if [ $WCONFIG ];then
                # Wireless Power timeout        
                wconfig wlan0 power timeout 100ms
        fi
;;

down)
        if [ $CPUFREQ ];then
                # Lower the govoner settings
                $CPUFREQ -r -g powersave; 
        fi
        if [ /sys/class/leds/smc::kbd_backlight/brightness ];then
                # Turn the backlight down
                        echo '20' > /sys/class/leds/smc::kbd_backlight/brightness
        fi
        # Intel HDA
                echo '1' > /sys/module/snd_hda_intel/parameters/power_save
        # SATA Active Link Powermanagement
                for i in `find /sys/class/scsi_host/host*/link_power_management_policy`; do echo 'min_power' > $i; done
        # NMI Watchdog
                echo '0' > /proc/sys/kernel/nmi_watchdog
;;

up)
        if [ $CPUFREQ ];then
                # Increase the Govoner settings 
                        $CPUFREQ -r -g ondemand;
        fi
        if [ /sys/class/leds/smc::kbd_backlight/brightness ];then
                # Turn the backlight up
                        echo '200' > /sys/class/leds/smc::kbd_backlight/brightness
        fi
        # SATA Active Link Powermanagement
                for i in `find /sys/class/scsi_host/host*/link_power_management_policy`; do echo 'max_performance' > $i; done
        # NMI Watchdog
                echo '1' > /proc/sys/kernel/nmi_watchdog
;;

*)
        # Infomation
                echo 'Using Start UP Settings, to toggle Power Settings ( base | down | up | critical )'
;;

esac
