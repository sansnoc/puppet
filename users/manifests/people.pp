# class users::people
# we separate this out because it is long from having all the useraccount define
# calls.
class users::people { # this class virtually calls the user:account define.
    # first set some defaults based on whether this node is openbsd or centos.
    $group  = $operatingsystem ? {
        centos => "root",
        redhat => "root",
        openbsd => "wheel",
        default => "root",
    }   
    # we should get bash installed on openbsd systems elsewhere, but just
    # in case:
    $shell  = $operatingsystem ? {
        centos => "/bin/bash",
        redhat => "/bin/bash",
        openbsd => "/usr/local/bin/bash",
        default => "/bin/bash",
    }
    # We use /home as the default "home" filesystem.
    # TODO: maybe this should be handled through a define, instead.
    # we set the group here based on the default group by platform above.
    $homefs = "/home"
    file { $homefs:
        ensure  => directory,
        owner   => "root",
        group   => $group,
        mode    => 2755
    }
    # These are the NOC users.
    # use uids 500-509 for noc users.
    @useraccount { "someuser":
        ensure   => "present",
        uid      => "500",
        pgroup   => "wheel",
        groups   => ["users"],
        fullname => "Some User",
        homefs   => $homefs,
        shell    => $shell,
    }
    # These are the Web/database users.
    # use uids 510-529 for web users.
    @useraccount { "webguy1":
        ensure   => "present",
        uid      => "510",
        pgroup   => "htdocs",
        groups   => ["wwwcron"],
        fullname => "Web Guy One",
        homefs   => $homefs,
        shell    => "/bin/bash",
    }
}
# class users::database 
# Override the primary group for virtual web users to mysql.
# Make these virtual users real.
class users::database inherits users::people {
    Useraccount["webguy1"] {
        pgroup => "mysql",
        groups => "users",
        require => Group["mysql"],
    }
    Useraccount <| pgroup == mysql |>
}
# vim modeline - have 'set modeline' and 'syntax on' in your ~/.vimrc.
# vi:syntax=puppet:filetype=puppet:ts=4:et:
# EOF
