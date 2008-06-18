class md3000 {

    case $operatingsystem {
        centos: {
            $osver     = "el5"
            $kerneldev = "kernel-PAE-devel"
            $provider  = "yum"
            Package { require => [Yumrepo["sans"], Yumrepo["base"]] }
        }
        redhat: {
            $osver     = "el${redhatrelease}"
            $kerneldev = ["kernel-devel", "kernel-smp-devel"]
            $provider  = "up2date"
            Package { 
                require => File["/etc/sysconfig/rhn/up2date"]

                # comment out the above and uncomment the following when the
                # sans-el4 repo is fully functional and ready.
                #require => [
                #    Yumrepo["sans-el4"],
                #    File["/etc/sysconfig/rhn/up2date"] 
                #]
            }
        }
    }

    include md3000::devel
    include md3000::admin

}

class md3000::devel {

    # Get the appropriate dev packages installed.

    package { $kerneldev:
        ensure   => installed,
        provider => $provider
    }

    package { "gcc": ensure => installed, }
    
}

class md3000::admin {

    # Install packages to administer the disk array.

    # minicom to provide access to the RAID controllers via serial password 
    # reset cable.

    package { "minicom": ensure => installed, }

    file { "/etc/minirc.dfl": 
        source  => "puppet:///md3000/minirc.dfl",
        require => Package["minicom"],
    }
    
    # MD Storage Manager.

    package { ["SMagent", "SMruntime", "SMutil", "SMclient"]:
        ensure => installed,
        provider => yum,
        require => Yumrepo["sans"],
    }

}

# Use this class on systems utilizing the device mapper multipath driver for
# multipath support. Do not use on systems utilizing MPP.
class md3000::multipath {
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

# md3000::driver defined type installs the proper HBA and multipath drivers
# for RDAC MPP.
# 
# Variables used:
# $osver: Dell names directories rh#. This may not be needed when the md3000
#   rpms are available through yum.
# $ensure: whether to install the drivers. Default is present.
# $mptlinux: The specific version of the mptlinux package to install.
# $linuxrdac: The specific version of the linuxrdac package to install.
# The mptlinux and linuxrdac packages require specific parameters passed to
# the dkms build and install commands in order to get the modules built for
# the current running kernel. 
#
# Example usage:
# md3000::driver {
#   osver => "rh4",
#   mptlinux => "4.00.07.00-2dkms",
#   linuxrdac => "09.01.C6.06b-1dkms",
# }

#define md3000::driver (
#    $osver = 'rh5', 
#    $ensure = 'present', 
#    $mptlinux, $linuxrdac
#){
#    
#}
# vi:syntax=puppet:filetype=puppet:ts=4:et:
