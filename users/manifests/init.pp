# This module creates users using virtual resources via a called define, 
# useraccount. It also has some special handling of web team users because they
# may be in a different primary group on database servers, for example.
#
# To use this module on a node, include the following, as appropriate.
# include users::people   # on all servers.
# include users::noc      # on all servers.
# include groups::web     # only on web servers.
# include users::web      # only on web servers.
# include users::web::extra # only on web servers.
# include users::database # only on database servers.

# We have some other classes to grab too.
import "people"
import "web"

# define useraccount
# creates a user with their complete home directory, including ssh key(s),
# shell profile(s) and anything else.
# This define should be called to create a virtual resource so it can
# be used to create all users, and then the users required on the particular
# node are specified through the various user classes.
# Example:
# @useraccount { "username":
#   ensure   => "present",
#   uid      => 500,
#   pgroup   => users,
#   groups   => ["staff", "other"],
#   fullname => "New User",
#   homefs   => "$homefs",
#   shell    => "$shell",
# }

define useraccount ( $ensure = present, $uid, $pgroup = users,
                       $groups, $fullname, $homefs, $shell) {
    $username = $name
    # This case statement will allow disabling an account by passing
    # ensure => absent, to set the home directory ownership to root.
    case $ensure {
        present: {
            $home_owner = $username
            $home_group = $pgroup
        }
        default: {
            $home_owner = "root"
            $home_group = "root"
        }
    }
    # Create the user with their groups as specified
    user { $username:
        ensure      => $ensure,
        uid         => $uid,
        gid         => $pgroup,
        groups      => $groups,
        comment     => $fullname,
        home        => "${homefs}/$username",
        shell       => $shell,
        allowdupe   => false,
    }
    file { "${homefs}/${username}":
        ensure  => directory,
        owner   => $home_owner,
        group   => $home_group,
        mode    => 750,
        require => User["${username}"],
    }
    file { "${homefs}/${username}/.ssh":
        ensure  => directory,
        owner   => $home_owner,
        group   => $home_group,
        mode    => 700,
        require => File["${homefs}/${username}"],
    }
    file { "${homefs}/${username}/.ssh/authorized_keys":
        ensure  => present,
        owner   => $home_owner,
        group   => $home_group,
        mode    => 600,
        require => File["${homefs}/${username}/.ssh"],
        source  => "puppet:///users/${username}/.ssh/authorized_keys",
    }
    file { "${homefs}/${username}/.ssh/authorized_keys2":
        ensure  => "${homefs}/${username}/.ssh/authorized_keys",
        require => File["${homefs}/${username}/.ssh/authorized_keys"],
    }
    file { "${homefs}/${username}/.bashrc":
        ensure  => present,
        owner   => $home_owner,
        group   => $home_group,
        mode    => 640,
        require => File["${homefs}/${username}"],
        source  => "puppet:///users/${username}/.bashrc",
    }
    file { "${homefs}/${username}/.bash_profile":
        ensure  => "${homefs}/${username}/.bashrc",
        require => File["${homefs}/${username}/.bashrc"],
    }
}

# class groups::web
# This class virtual creates the required groups for the web team.
class groups::web {
    @group { "htdocs":  ensure => present, gid => "1502", }
    @group { "wwwcron": ensure => present, gid => "1501", }
    @group { "secure":  ensure => present, gid => "2038", }
}
# Create another class to realize other groups.
#class groups::newgrouptype {
#    @group { "newgroup": ensure => present, gid => "530", }
#}
# class users::noc 
# Make the virtual users with wheel as the primary group real.
# This should be the NOC/Sysadmin team.
class users::noc {
    Useraccount <| pgroup == wheel |>
}

# class users::web
# Make the virtual users with htdocs as the primary group real.
# This should be the webmaster team.
class users::web {
    Group <| title == htdocs |>
    Group <| title == wwwcron |>
    Group <| title == secure |>
    Useraccount <| pgroup == htdocs |>
    Useraccount <| title == webalizer |>
    User <| title == cronman |>
    User <| title == secure |>
}
#class users::web::newwebgroup {
#    Group <| title == htdocs |>
#}
# Make the virtual users for the newgroup systems real.
#class users::newgroup {
#    Group <| title == newgroup |>
#    Useraccount <| pgroup == newgroup |>
#}
# vim modeline - have 'set modeline' and 'syntax on' in your ~/.vimrc.
# vi:syntax=puppet:filetype=puppet:ts=4:et:
# EOF
