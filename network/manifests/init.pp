# networking defined type controls the /etc/sysconfig/network file.
# Most of the work is handled with ruby logic in the template. If the 
# gwdev variable is set, the gateway variable needs to be set as well. 
# This will set the default gateway device for all interfaces.
# $name is not used, it merely identifies the resource uniquely.
#
# Update: Added support for openbsd's /etc/mygate which has the contents
# of the default gateway IP.
#
# Variables used:
# $gw: default gateway IP for all interfaces. Specify a valid IP address.
#   This is optional.
# $gwdev: default gateway device to use. Specify the device name to use,
#   eg, 'eth0' or 'bond0'. This is optional.
# $ensure: whether networking is set up on this system. Valid values are
#   'present' or 'absent'. This setting defaults to 'present'.
# 
# Example:
# networking { "network-${hostname}": 
#     ensure => present, 
#     gwdev  => "eth0",
#     gw     => "10.1.0.1",
# }

define networking ($gw = '', $gwdev = '', $ensure = 'present') {
    case $operatingsystem {
        centos,redhat: { 
            $netstate = $ensure
            file { "/etc/sysconfig/network":
                content => template("network/network.erb"),
            }
        }
        openbsd: {
            file { "/etc/mygate":
                content => "${gw}\n",
            }
        }
    }
}

# netiface defined type controls the networking interface files in 
# /etc/sysconfig/network-scripts/ifcfg-*. It can handle normal, bonded,
# alias, slaves or 'up' interfaces for use on SPAN ports.
#
# Variables used:
# $ensure: Whether this interface is configured at boot or not. For aliases,
#   whether the alias is brought up with the parent interface or not. Valid
#   values are 'present' or 'absent'. Default is present.
# $ifnum: Used for aliases to set the 'number' of the alias. For example,
#   if interface is eth0, set ifnum to 0 for eth0:0.
# $bondopts: Set options for the bonding module. For more information, see
#   Red Hat 5.1 Deployment Guide, 41.5.2.1. bonding Module Directives.
# $interface: The actual interface device. For example, eth0, eth1, bond0.
#   Do not use "eth0:0" for aliases. Instead specify the interface device 
#   here and use $ifnum for the number of the alias.
# $interface_type: Interface 'type'. Valid values are bond, alias, slave
#   and tap. Anything else is considered a 'normal' interface, which is the
#   default.
# $netmask: Specify the interface netmask. This doesn't do error detection
#   so make sure your mask is correct for the network!
# $master: For slave interface types, specify the interface of the master.
#   the master interface doesn't have to be created first. 
# $name: By default, the $name will be the IP address to use for the interface.
#   tap and slave devices do not have an IP address assigned, so use something
#   to uniquely identify those interfaces.
#
# Example normal:
# $interface_type is not set, so assume 'normal'.
# netiface { "10.1.0.170":
#    interface      => "eth0",
#    netmask        => "255.255.255.0",
# }
# 
# Example bonded:
# Sets up a bonded interface. Don't forget to create the slave resources.
# netiface { "10.1.0.170":
#     bondopts       => "mode=balance-rr miimon=100",
#     interface      => "bond0",
#     interface_type => "bond",
#     netmask        => "255.255.255.0",
# }
#
# Example alias:
# The device created here will be bond0:0 ($interface:$ifnum). 
# netiface { "10.1.0.171":
#     interface      => "bond0",
#     interface_type => "alias",
#     ifnum          => "0",
#     netmask        => "255.255.255.0",
# }
#
# Example slave:
# This is used for interfaces that are slaved to a bonded interface.
# netiface { "eth0":
#     interface      => "eth0",
#     interface_type => "slave",
#     master         => "bond0",
# }
#
# Example "up" or "tap":
# This is used for interfaces that are listening on "SPAN" ports, ie, IDS.
# netiface { "${hostname}-eth5-up":
#     interface      => "eth5",
#     interface_type => "tap",
# }
define netiface (
    $ensure = 'present', $ifnum = '', $bondopts = '', $interface,
    $interface_type = 'normal', $netmask = '255.255.255.0', $master = ''
) {
    $ifstate = $ensure
    case $interface_type {
        "alias": {
            file { "/etc/sysconfig/network-scripts/ifcfg-${interface}:${ifnum}":
                content => template("network/ifcfg.erb")
            }
        }
        "bond": {
            file { "/etc/sysconfig/network-scripts/ifcfg-${interface}":
                content => template("network/ifcfg.erb")
            }
            line { "modprobe-${hostname}-${interface}":
                file => "/etc/modprobe.conf",
                line => "alias ${interface} bonding # ${hostname}-${interface}",
            }
        }
        default: { 
            file { "/etc/sysconfig/network-scripts/ifcfg-${interface}":
                content => template("network/ifcfg.erb")
            }
            if $bondopts {
                line { "modprobe-${hostname}-${interface}":
                    file => "/etc/modprobe.conf",
                    line => "alias ${interface} bonding # ${hostname}-${interface}",
                }
            }
        }
    }
}

# similar to the netiface above but specifically for trunk ports on OpenBSD.
# Variables:
# $interface: Specify the trunk# interface to use.
# $trunkports: "Slave" trunkport interfaces used by the trunk. Specify as an
#   array. This will call the netiface::trunk::ports defined type to set up
#   the hostname.$trunkport interface files.
# $trunkproto: Specify the trunk protocol used. Valid values are failover,
#   roundrobin, loadbalance, none per trunk man page. Default is failover.
# $ip: Specify the IP address for the interface.
# $netmask: Specify the netmask for the interface. Default is 255.255.255.0.
# $bcast: Specify the broadcast if required, otherwise use NONE to have
#   BSD automatically detect the required broadcast. Default is NONE.
# $routes: See below for detail.
# 
# To add static routes for the interface, specify the routes as destination
# and gateway pairs, as an array. The template will handle the rest.
#
# $routes = ["10.1.32.0/24 10.1.16.254", "10.1.48.0/24 10.1.16.254"]
# $routes = $perimeter ? { # set $perimeter in the node context.
#   'ext' => ["10.1.32.0/24 10.1.16.254", "10.1.48.0/24 10.1.16.254"],
#   'int' => '' # or something else entirely as needed.
# }
#
# Example usage:
# netiface::trunk { "${hostname}-trunk0":
#    interface => "trunk0",
#    trunkports => ["em0", "em4"],
#    ip         => "10.0.0.1",
# }

define netiface::trunk ($interface, $trunkports, $trunkproto = 'failover',
    $ip, $netmask = '255.255.255.0', $bcast = 'NONE', $routes = false) {
    file { "/etc/hostname.${interface}":
        content => template("network/hostname.trunk.erb"),
    }
    netiface::trunk::ports { $trunkports: }
}
# "slave" interfaces - trunkports for the trunk interface above.
# See comments for netiface::trunk regarding trunk::ports.
define netiface::trunk::ports () {
    file { "/etc/hostname.${name}":
        content => "up\n",
    }
}

# set up carp interfaces on bsd.
# See man page for carp for more details on settings.
# Variables:
# $interface: Specify the carp# interface to use.
# $aliases: Array of aliases bound to the carp interface shared by the 
#   master and slave systems.
# $ip: Specify the IP address for the interface. This is the same for all
#   hosts using this carp interface.
# $netmask: Netmask required. Default is 255.255.255.0.
# $bcast: Specify the broadcast if required, otherwise use NONE to have
#   BSD automatically detect the required broadcast. Default is NONE.
# $vhid: Virtual host identifier, must be unique for each carp interface.
# $pass: Passphrase required to connect to other carp hosts.
# $advskew: Offset used for the carp timeout. Should be different for each
#   system that uses this carp interface. See man page.
# 
# Example usage:
# netiface::carp { "${hostname}-carp0":
#    interface => "carp0",
#    ip        => "10.0.0.1",
#    aliases   => ["10.0.0.100", "10.0.0.200"],
#    vhid      => "1",
#    pass      =>  'P@ssPhra53!',
#    advskew   => "1",
# }

define netiface::carp ($interface, $aliases = '', $ip, 
    $netmask = '255.255.255.0', $bcast = 'NONE', $vhid, $pass, $advskew, $ifgroup = 'internalfw') {
    file { "/etc/hostname.${interface}":
        content => template("network/hostname.carp.erb"),
    }
}

# route defined type adds a static route to the static routes file, 
# /etc/sysconfig/network-scripts/route-$interface. This uses the append_line
# defined type.
#
# Variables used:
# $device: The interface this route is used on. Required.
# $destination: The destination host or network, specify "default" for the 
#   default route. Required.
# $gateway: The gateway to the destination. Required.
#
# Example:
#
# route { "${hostname}-bond0-0":
#    device      => "bond0",
#    destination => "default",
#    gateway     => "10.1.0.254",
# }
# route { "${hostname}-bond0-1":
#    device      => "bond0",
#    destination => "10.1.0.0/24",
#    gateway     => "10.1.0.254",
# }
 
define route ($device, $destination, $gateway) {
    line { "route-${name}":
        file => "/etc/sysconfig/network-scripts/route-${device}",
        line => "${destination} via ${gateway} dev ${device}",
    }
}
# As above, but for trunk interfaces on OpenBSD.
# This define appends the line to the trunk device file.
define route::trunk ($device, $destination, $gateway) {
    line { "route-${name}":
        file => "/etc/hostname.${device}",
        line => "! route -qn add -net $destination $gateway",
        require => File["/etc/hostname.${device}"],
    }
}

# vim modeline - have 'set modeline' and 'syntax on' in your ~/.vimrc.
# vi:syntax=puppet:filetype=puppet:ts=4:et:
# EOF
