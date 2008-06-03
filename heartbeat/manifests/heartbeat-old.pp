class heartbeat {
    package { "heartbeat":
        ensure  => present,
        require => Yumrepo["extras"],
        before  => [
            File["/etc/ha.d/ha.cf"], 
            File["/etc/ha.d/haresources"], 
            File["/etc/ha.d/authkeys"], 
            File["/var/lib/heartbeat/crm/cib.xml"]
        ]
    }
    file { "/etc/ha.d/ha.cf":
        mode   => "0644",
        source => "puppet:///heartbeat/ha.d/ha.cf",
    } 
    file { "/etc/ha.d/haresources":
        mode   => "0644",
        source => "puppet:///heartbeat/ha.d/haresources",
    } 
    file { "/etc/ha.d/authkeys":
        mode   => "0600",
        source => "puppet:///heartbeat/ha.d/authkeys",
    } 
    file { "/var/lib/heartbeat/crm/cib.xml":
        owner  => "hacluster",
        group  => "haclient",
        mode   => "0600",
        source => "puppet:///heartbeat/var_lib_heartbeat/crm/cib.xml",
    }
#        file { "/var/lib/heartbeat/crm/cib.xml.sig":
#       owner => "hacluster",
#       group => "haclient",
#               mode => "0600",
#              source => "puppet:///heartbeat/var_lib_heartbeat/crm/cib.xml.sig",
#        }
}
#define heartbeat::haip ( $serveralias, $ip ) {
    
#    }
# vim modeline - have 'set modeline' and 'syntax on' in your ~/.vimrc.
# vi:syntax=puppet:filetype=puppet:ts=4:et:
# EOF
