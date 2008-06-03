# class name_of_class { }
# define definition { }
# 
# Classes and Definitions here.

class dirvish { 

    class client {
        # client portion is limited to installing an SSH key on the box
        # for the dirvish server to use to connect to it.
        # Since this is site specific, this is doen via our local module
    }

    class server {

        package { 
            ["perl-Time-modules",
            "perl-Time-Period"]:
            ensure => installed,
            require => Yumrepo["rpmforge"],
        }

        file { "/etc/dirvish":
            ensure => directory,
            owner  => "root",
            group  => "root",
            mode   => "0755",
        }

        file {
            "/usr/sbin/dirvish" :
                owner  => "root", group  => "root", mode   => "0755",
                source => "puppet:///dirvish/bin/dirvish";
            "/usr/sbin/dirvish-expire" :
                owner  => "root", group  => "root", mode   => "0755",
                source => "puppet:///dirvish/bin/dirvish-expire";
            "/usr/sbin/dirvish-locate" :
                owner  => "root", group  => "root", mode   => "0755",
                source => "puppet:///dirvish/bin/dirvish-locate";
            "/usr/sbin/dirvish-runall" :
                owner  => "root", group  => "root", mode   => "0755",
                source => "puppet:///dirvish/bin/dirvish-runall";
        }

        file {
            "/usr/share/man/man5/dirvish.conf.5" :
                owner  => "root", group  => "root", mode   => "0644",
                source => "puppet:///dirvish/man/dirvish.conf.5";
            "/usr/share/man/man8/dirvish.8" :
                owner  => "root", group  => "root", mode   => "0644",
                source => "puppet:///dirvish/man/dirvish.8";
            "/usr/share/man/man8/dirvish-expire.8" :
                owner  => "root", group  => "root", mode   => "0644",
                source => "puppet:///dirvish/man/dirvish-expire.8";
            "/usr/share/man/man8/dirvish-locate.8" :
                owner  => "root", group  => "root", mode   => "0644",
                source => "puppet:///dirvish/man/dirvish-locate.8";
            "/usr/share/man/man8/dirvish-runall.8" :
                owner  => "root", group  => "root", mode   => "0644",
                source => "puppet:///dirvish/man/dirvish-runall.8",
        }
    }
}

define dirvish::config ($banks, $imagedef = "%Y%m%d", $index = "none", $log = "none",
        $excludes = [''], $runall = [''], $time = false, $expiredef = "+2 weeks", $expires = ['']) {

    file { "/etc/dirvish/master.conf":
        owner   => "root",
        group   => "root",
        mode    => "0640",
        content => template("dirvish/master.conf.erb")
    }
}

define dirvish::bank ($bank) {
    file { "$bank":
        ensure => directory,
        owner  => "root",
        group  => "root",
        mode   => "0750",
    }
}

define dirvish::vault ($bank, $vault) {
    file { "$bank/$vault":
        ensure => directory,
        owner  => "root",
        group  => "root",
        mode   => "0750",
    }
    file { "$bank/$vault/dirvish":
        ensure  => directory,
        owner   => "root",
        group   => "root",
        mode    => "0750",
        require => File["$bank/$vault"],
    }
}

define dirvish::branch ($bank, $vault, $host, $fs,
            $xdev = "true", $index = "gzip", $excludes = [''], $parent = false) {

    file { "$bank/$vault/dirvish/$name.conf":
        owner   => "root",
        group   => "root",
        mode    => "0640",
        content => template("dirvish/branch.conf.erb")
    }

    $cmd = $parent ? {
        false   => "dirvish --init --branch $vault:$name",
        default => "dirvish --reference $parent --branch $vault:$name",
    }

    exec { "branch-create-$name":
        command => $cmd,
        creates => "$bank/$vault/dirvish/$name.hist",
        require => [File["/usr/sbin/dirvish"], File["$bank/$vault/dirvish/$name.conf"]]
    }
}

define dirvish::stats ($email, $period = "yesterday") {

    file { "/usr/sbin/$name":
        owner   => "root",
        group   => "root",
        mode    => "0755",
        content => template("dirvish/dirvish-stats.erb")
    }
}

define dirvish::userkey ($user = "root", $group = "root", $key = false, $file = "authorized_keys2") {

    $dir = $user ? {
        "root"   => "/root/.ssh",
        default  => "/home/$user/.ssh",
    }

    exec { "dirvish-create-keydir":
        command => "/bin/mkdir -m 0700 -p $dir",
        creates => "$dir",
    }
    exec { "dirvish-modify-keydir":
        command => "/bin/chown $user:$group $dir",
        unless  => "stat --printf='%U:%G\n' $dir | grep '$user:$group' 1>/dev/null",
        require => Exec["dirvish-create-keydir"]
    }

    line { "dirvish-pub-key":
        ensure  => present,
        file    => "$dir/$file",
        line    => "$key",
        require => Exec["dirvish-modify-keydir"]
    }

}


# vim modeline - have 'set modeline' and 'syntax on' in your ~/.vimrc.
# vi:syntax=puppet:filetype=puppet:ts=4:et:
# EOF
