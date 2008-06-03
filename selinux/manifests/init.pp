# Create the directory where local policy templates are stored for loading
# with the selinux::module defined type below.

class selinux {
    file { "/etc/selinux/local":
        ensure => directory,
        mode   => 0750,
    }
}

# selinux::module defined type adds a new SELinux template into 
# the running policy. This type does not require any arguments, it only
# uses the name from the caller.
# 
# This define requires creating an SELinux template to load. The best
# method to create the template is to use audit2allow. For example,
#
# sudo audit2allow -m "multipathd" -i /var/log/audit/audit.log > multipathd.te
#
# The above assumes auditing is turned on and logging properly to the above
# log file. See the audit2allow man page for more information.
# 
# Example usage for a node (module from above audit2allow example):
# 
# selinux::module { "multipathd": }

define selinux::module () {
    file { "/etc/selinux/local/${name}.te":
        source => "puppet:///selinux/${name}.te",
    }

    file { "/etc/selinux/local/$name-setup.sh":
        ensure  => present,
        mode    => 0750,
        content => template ("selinux/setup.erb"),
        require => File["/etc/selinux/local"],
    }

	exec { "SELinux-$name-Update":
		command		=> "/etc/selinux/local/$name-setup.sh",
		refreshonly => true,
		require     => File["/etc/selinux/local/$name-setup.sh"],
		subscribe	=> File["/etc/selinux/local/$name.te"],
	}
}

# Need documentation for this type -
# example usage:
# selinux::chcon { "postfix-lostfound":
#       user => "system_u",
#       type => "file_t",
#       file => "/var/spool/postfix/lost+found",
#  }

define selinux::chcon ( $user = false, $role = false, $type = false, $file) {
    case $user {
        false:   {}
        default: {
            exec { "$name-chcon-user":
                command => "/usr/bin/chcon -u $user $file",
                unless => "ls -ldZ $file | grep -q '$user'",
            }
        }
    }

    case $role {
        false:   {}
        default: {
            exec { "$name-chcon-role":
                command => "/usr/bin/chcon -r $role $file",
                unless => "ls -ldZ $file | grep -q '$role'",
            }
        }
    }

    case $type {
        false:   {}
        default: {
            exec { "$name-chcon-type":
                command => "/usr/bin/chcon -t $type $file",
                unless => "ls -ldZ $file | grep -q '$type'",
            }
        }
    }
}

# vim modeline - have 'set modeline' and 'syntax on' in your ~/.vimrc.
# vi:syntax=puppet:filetype=puppet:ts=4:et:
# EOF
