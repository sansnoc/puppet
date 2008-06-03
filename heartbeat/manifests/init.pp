
class heartbeat {

    package { "heartbeat":
        ensure  => installed,
        require => Yumrepo["extras"],
    }

    service { "heartbeat":
        hasstatus  => true,
        hasrestart => true,
    }

}

# heartbeat::hacf creates a base cluster configuration file with sane
# defaults for our environment.
#
# Variables used:
# Each variable/parameter used corresponds to a value in the heartbeat ha.cf
# file. For definitive documentation on the allowed options and values, see
# the heartbeat documentation. Special notes here.
#
# $hosts: Must be passed as an array for the template to parse properly.
# $ping: Must be passed as an array as well, see sample usage.
#
# Example usage:
# heartbeat::hacf { "security wiki"":
#    hosts => ["web1e", "web1f"],
#    ping => ["10.1.0.1"],
# }

define heartbeat::hacf (
    $logfacility = 'local0',   $bcast         = 'bond0',
    $keepalive   = '1',        $auto_failback = 'on',
    $deadtime    = '10',       $hosts,
    $warntime    = '3',        $ping,
    $initdead    = '30',       $crm           = true   
){
    
    file { "/etc/ha.d/ha.cf":
        mode    => 0644,
        content => template("heartbeat/ha.cf.erb"),
        notify  => Service["heartbeat"],
        require => Package["heartbeat"],
    }

}

# heartbeat::haresources sets up a v1 haresources file as a baseline, then
# runs the conversion script to create a v2 cib.xml file.
# 
# Variables used:
# 
# $primary: The primary system where the service should live.
# $ipaddr: Ip address(es) used, must be passed as an array.
# $service: The service for the resource group. Optional.
#
# Example usage: 
#
# heartbeat::haresources { "security wiki":
#    primary => "web1e.den.giac.net",
#    ipaddr  => ["10.1.0.151"],
#    service => "httpd",
# }

define heartbeat::haresources ( $primary, $ipaddr, $service = '') {
    
    file { "/etc/ha.d/haresources":
        mode    => 0644,
        replace => false,
        content => template("heartbeat/haresources.erb"),
        require => [Package["heartbeat"], File["/etc/ha.d/ha.cf"]],
    }
   
    # Run the conversion file to create cib.xml for heartbeat v2.
    # the haresources2cib.py script checks for cib.xml.
    
    exec { "/usr/lib/heartbeat/haresources2cib.py": 
        creates => "/var/lib/heartbeat/crm/cib.xml",
        require => File["/etc/ha.d/haresources"],
    }

}

# heartbeat::authkeys sets up the authentication keys files.
# The template will perform an MD5 hash on the password.
#
# Variables used:
# 
# $signature: The signature method. Valid values are md5, sha1 and crc.
# $password: The password to create an md5 hash
# 
# Example usage:
#
# heartbeat::authkeys { "security wiki":
#   password => "Security Wiki",
# }
define heartbeat::authkeys ($signature = 'sha1', $password) {

    file { "/etc/ha.d/authkeys":
        mode    => 0600,
        content => template("heartbeat/authkeys.erb"),
        notify  => Service["heartbeat"],
        require => Package["heartbeat"],
    }

}
# vi:syntax=puppet:filetype=puppet:ts=4:et:
