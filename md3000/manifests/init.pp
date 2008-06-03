class md3000 {

    # kernel sources for PAE kernel require for MPT and MPP drivers. 
    # minicom required for serial port access to RAID controllers.
    # lsscsi is a handy tool to have installed on systems with storage arrays.
    # though lsscsi should be added to kickstart for all servers.
    # dkms is available from rpmforge so we don't have to worry about Dell's
    # specific version (its the same as of this writing).

    package { ["kernel-PAE-devel", "minicom", "lsscsi", "dkms"]:
        ensure => installed,
    }

    file { "/etc/minirc.dfl":
        source  => "puppet:///md3000/minirc.dfl",
        require => Package["minicom"],
    }

    # Install the storage manager software on the local system.

    class sm {
        package { ["SMagent", "SMruntime", "SMutil", "SMclient"]: 
            ensure => installed, 
        }

        #service { ["SMagent", "SMmonitor"]:
        #    ensure => running,
        #    enable => true,
        #    require => Package["SMagent", "SMruntime", "SMutil", "SMclient"],
        #}
    }

    # Portability: change the line below to reflect the host adapter.
    # This could become a variable set at the node level.
    class modprobe {
        append_line { "mpt_modprobe":
            file => "/etc/modprobe.conf",
            line => "alias scsi_hostadapter2 mptspi",
        }
    }
    # Use this class on systems utilizing the device mapper multipath driver for
    # multipath support. Do not use on systems utilizing MPP.
    class multipath {
        package { ["device-mapper-multipath", "kpartx"]:
            ensure => installed,
        }
        file { "/etc/multipath.conf":
            source  => "puppet:///md3000/multipath.conf",
            require => Package["device-mapper-multipath"],
        }
        file { "/etc/lvm/lvm.conf":
            source  => "puppet:///md3000/lvm.conf",
            require => Package["device-mapper-multipath"],
        }
        service { "multipathd":
            ensure     => running,
            enable     => true,
            hasrestart => true,
            hasstatus  => true,
            subscribe  => File["/etc/multipath.conf"],
            require    => Package["device-mapper-multipath"],
        }
    }
}

# use this class on systems utilizing MPP RDAC (supported by Dell) for 
# multipath support.
# It will make calls to the md3000::mpp::drver define to install required
# device drivers for the SAS 5/E and MPP RDAC drivers.

# When upgrading mptlinux and linuxrdac package versions to new releases, be
# sure to edit the distro-specific statements below.

class md3000::mpp {
    case $operatingsystem {
        redhat: { $osver = "rh${operatingsystemrelease}" }
        centos: { $osver = "rh5" }
    }

    case $osver {
        rh4: {
            md3000::mpp::driver { [
                "mptlinux-3.02.83.12-7dkms",
                "linuxrdac-09.01.B6.75-1dkms"
            ]: 
                osver => "$osver",
            }
        }
        rh5: {
            md3000::mpp::driver { [
                "mptlinux-4.00.07.00-2dkms",
                "linuxrdac-09.01.C6.06b-1dkms"
            ]: 
                osver => "$osver",
            }
            package { [
                "sg-3.5.34dell-1dkms",
                "libXp-1.0.0-8"
            ]: 
                ensure   => installed, 
            }
        }
    }
} 

# example usage:
# md3000::mpp::driver { "mptlinux-4.00.07.00-2dkms": osver => "rh4", }

define md3000::mpp::driver ($osver = 'rh5', $ensure = 'present') {
    package { "${name}":
        ensure   => "${ensure}",
        provider => rpm,
        require  => Package["dkms"],
        source   => "http://puppet/pub/md3000/${osver}/${name}.noarch.rpm",
    }
}
# vim modeline - have 'set modeline' and 'syntax on' in your ~/.vimrc.
# vi:syntax=puppet:filetype=puppet:ts=4:et:
# EOF
