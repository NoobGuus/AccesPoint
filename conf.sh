ifconfig
echo "Hi, on what interface do you want to run the AP?"
echo "USE WLAN. so for example wlan0 or wlan1"
read WLAN
echo "Name of the SSID!"
read SSID
echo "Password of the AP!"
read PASS


#1. Configure DHCP----------------------------------------------
x=yum.yum
touch $x
sudo rm -rf /etc/default/udhcpd
sudo mkdir /etc/default
sudo touch /etc/default/udhcpd
echo "start 192.168.42.2 " >>   $x
echo "end 192.168.42.20" >> $x
echo "interface $WLAN" >> $x
echo "remaining yes" >> $x
echo "opt dns 8.8.8.8 4.2.2.2" >> $x
echo "opt subnet 255.255.255.0" >> $x
echo "opt router 192.168.42.1" >> $x
echo "opt lease 864000" >> $x
sudo mv  $x /etc/udhcpd.conf
touch $x
echo  "# Comment the following line to enable" >> $x
echo "#DHCPD_ENABLED=\"no\"" >> $x
echo "# Options to pass to busybox' udhcpd." >> $x
echo "# -S    Log to syslog" >> $x
echo "# -f    run in foreground" >> $x
echo "DHCPD_OPTS=\"-S\"" >> $x
sudo mv $x  /etc/default/udhcpd
	#give the Pi a static IP address 
sudo ifconfig $WLAN 192.168.42.1
#------------SETUP Station Interface for Rt5370-------------------------------------
touch $x
sudo cp  /etc/network/interfaces /etc/network/interfaces.bk
echo "source-directory /etc/network/interfaces.d" >> $x
echo "auto lo" >> $x
echo "iface lo inet loopback" >> $x
echo "" >> $x
echo "auto eth0" >> $x
echo "iface eth0 inet dhcp" >> $x
echo "" >> $x
echo "allow-hotplug $WLAN" >> $x
echo "iface $WLAN inet dhcp" >> $x
echo "    wpa-conf /etc/wpa_supplicant/wpa_supplicant.conf" >> $x
echo "    wireless-power off" >> $x
echo "" >> $x
echo "iface default inet dhcp" >> $x
sudo chown --reference=/etc/network/interfaces $x
sudo chmod --reference==/etc/network/interfaces $x
sudo mv $x /etc/network/interfaces
sudo cp /etc/network/interfaces /etc/network/interfaces.sta 
sudo chmod --reference /etc/network/interfaces.bk /etc/network/interfaces.sta
#------------------------------SETUP AP Interface for Rt5370-------------------------------
touch  $x
echo "source-directory /etc/network/interfaces.d" >> $x
echo "auto lo" >> $x
echo "iface lo inet loopback" >> $x
echo "" >> $x
echo "auto eth0" >> $x
echo "iface eth0 inet dhcp" >> $x
echo "" >> $x
echo "iface $WLAN inet static" >> $x
echo "    address 192.168.42.1" >> $x
echo "    netmask 255.255.255.0" >> $x
echo "    wireless-power off" >> $x
echo "" >> $x
echo "iface default inet dhcp" >> $x
echo "up iptables-restore < /etc/iptables.ipv4.nat" >> $x
sudo chmod --reference==/etc/network/interfaces $x
sudo chown --reference=/etc/network/interfaces $x
sudo mv $x  /etc/network/interfaces.ap
sudo chmod --reference /etc/network/interfaces.bk /etc/network/interfaces.ap
#Config /etc/wpa_supplicant/wpa_supplicant.conf
touch $x
sudo rm -rf /etc/wpa_supplicant/wpa_supplicant.conf
sudo mkdir /etc/wpa_supplicant
sudo touch /etc/wpa_supplicant/wpa_supplicant.conf
echo "ctrl_interface=/var/run/wpa_supplicant" >> $x
echo "update_config=1" >> $x
echo "network={" >> $x
echo "        ssid=\"$SSID\"" >> $x
echo "        psk=\"PASS\"" >> $x
echo "}" >> $x
sudo mv $x /etc/wpa_supplicant/wpa_supplicant.conf

#4. Configure HostAPD------------------------------------------------
touch $x
echo "interface=$WLAN" >> $x
echo "driver=nl80211" >> $x
echo "ssid=Broken" >> $x
echo "hw_mode=g" >> $x
echo "channel=6" >> $x
echo "macaddr_acl=0" >> $x
echo "auth_algs=1" >> $x
echo "ignore_broadcast_ssid=0" >> $x
echo "wpa=2" >> $x
echo "wpa_passphrase=BrokenNetwork" >> $x
echo "wpa_key_mgmt=WPA-PSK" >> $x
echo "wpa_pairwise=TKIP" >> $x
echo "rsn_pairwise=CCMP" >> $x
sudo mv  $x  /etc/hostapd/hostapd.conf
#5. Configure NAT--------------------------------------------
touch $x
echo "DAEMON_CONF=\"/etc/hostapd/hostapd.conf\"" >> $x
sudo mv $x /etc/default/hostapd

touch $x
sudo sh -c "echo 1 >> /proc/sys/net/ipv4/ip_forward"
sudo echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i eth0 -o $WLAN -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i $WLAN -o eth0 -j ACCEPT
sudo sh -c "iptables-save >> /etc/iptables.ipv4.nat"

sudo rm yum.yum
#------------------------------6. Fire it up! R----------------------------------------
sudo service hostapd start
sudo service udhcpd start
#--------------------------Make the start and stop files!----------------------
start=ap-start.sh

touch $start

echo "sudo /etc/init.d/hostapd stop" >> $start
echo "sudo /etc/init.d/udhcpd stop" >> $start
echo "sudo ifdown $WLAN" >> $start
echo "sudo ifconfig $WLAN down" >> $start
echo "sudo rm -rf /etc/network/interfaces" >> $start
echo "sudo cp /etc/network/interfaces.ap /etc/network/interfaces" >> $start
echo "sudo ifconfig $WLAN up" >> $start
echo "sudo ifup $WLAN" >> $start
echo "sudo /etc/init.d/hostapd restart" >> $start
echo "sudo /etc/init.d/udhcpd restart" >> $start
echo "sudo service hostapd status" >> $start
echo "echo " >> $start
echo "echo ===============================================" >> $start
echo "echo Started the Acces Point!" >> $start
echo "echo ===============================================" >> $start


stop=ap-stop.sh

touch $stop

echo "sudo /etc/init.d/hostapd stop" >> $stop
echo "sudo /etc/init.d/udhcpd stop" >> $stop
echo "echo " >> $stop
echo "echo ===============================================" >> $stop
echo "echo Stopped the Acces Point!" >> $stop
echo "echo ===============================================" >> $stop

#------------------------Create wifiConnect.py------------------------------------
sudo apt-get install dnsmasq -y
sudo service dnsmasq start
sudo update-rc.d dnsmasq enable
sudo apt-get install udhcpc -y


