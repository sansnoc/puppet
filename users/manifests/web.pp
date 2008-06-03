# class users::web::extra
# This class creates the cronman and secure users required for the 
# web team to support various aspects of the web systems.
# Only include this class on web systems.
class users::web::extra {
    # cronman is a special user for the web team to manage crontabs centrally
    @user { "cronman": 
        ensure  => "present",
        uid     => "2029",
        gid     => "wwwcron",
        groups  => ["htdocs"],
        comment => "WWW Cron Manager",
        home    => "/home/cronman",
        shell   => "/bin/bash",
        require => Group["wwwcron"],
    }
    # secure is a special user for the web team.
    @user { "secure": 
        ensure  => "present",
        uid     => "2037",
        gid     => "2038",
        groups  => ["htdocs", "wwwcron"],
        comment => "Secure Web User",
        home    => "/home/secure",
        shell   => "/bin/bash",
        require => Group["secure"],
    }
    # webalizer needs to be created for automated ssh access from chipper1.
    # this is only on the web servers, and isn't a person, so it won't be in
    # the 'people' class, even though it uses the useraccount define.
    @useraccount { "webalizer":
        ensure   => "present",
        uid      => "2030",
        pgroup   => "users",
        groups   => ["apache", "htdocs"],
        fullname => "Web stats analyzer",
        homefs   => "/home",
        shell    => "/bin/bash",
    }
}

# vim modeline - have 'set modeline' and 'syntax on' in your ~/.vimrc.
# vi:syntax=puppet:filetype=puppet:ts=4:et:
# EOF
