# class name_of_class { }
# define definition { }
# 
# Classes and Definitions here.

class dell {

    class srvadmin {

        class base {
            package { ["instsvc-drivers", "srvadmin-omhip", "srvadmin-old", "srvadmin-cm"]: 
                ensure => installed,
                require => Yumrepo["sans"],
            }

            #service { "dsm_om_shrsvc":
            #    ensure => running,
            #    enable => true,
            #    hasrestart => true,
            #    require => [Package["instsvc-drivers"], Package["srvadmin-omhip"], Package["srvadmin-old"], Package["srvadmin-cm"]],
            #}

            exec { "srvadmin-base-start":
                command => "/usr/bin/srvadmin-services.sh start",
                creates => "/var/run/dsm_sa_datamgr32d.pid",
                require => Package[srvadmin-omhip],
            }
        }

        class rac {
            package { ["srvadmin-racadm5", "srvadmin-racdrsc5"]: 
                ensure => installed,
                require => Yumrepo["sans"],
            }

        }

        class storage {
            package { "srvadmin-storage": 
                ensure => installed,
                require => Yumrepo["sans"],
            }

        }

        class webserver {
            package { "srvadmin-iws": 
                ensure => installed,
                require => Yumrepo["sans"],
            }

            service { "dsm_om_connsvc":
                ensure => running,
                enable => true,
                hasrestart => true,
                require => Package["srvadmin-iws"],
            }
        }

    }
}

# vim modeline - have 'set modeline' and 'syntax on' in your ~/.vimrc.
# vi:syntax=puppet:filetype=puppet:ts=4:et:
# EOF
