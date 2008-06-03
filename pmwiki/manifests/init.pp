# define pmwiki sets up a pmwiki instance in the specified directory.
# This resource assumes Apache and Httpd configuration as well.
#
# Variables used:
# 
# $docroot: The DocumentRoot from the VirtualHost.
# $group:   Group owner of the directories and files.
# $path:    Path on the download server where we get pmwiki tarball from.
# $server:  Web/FTP server where the pmwiki tarball is located.
# $version: Version of PmWiki to install.   
#
# Example usage:
# pmwiki { "${hostname}-pmwiki":
#   docroot => "/srv/www/pmwiki",
#   group   => "htdocs",
#   path    => "pub/pmwiki",
#   server  => "www.pmwiki.org",
#   version => "2.2.0-beta65",
# }

define pmwiki (
    $docroot = '/srv/www/pmwiki',
    $group   = 'htdocs',
    $path    = 'pub/pmwiki', 
    $server  = 'puppet', 
    $version = '' 
) {
    
    Exec { 
        path    => "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
        cwd     => "/srv/www", 
        require => File["/srv/www"],
    }
    
    File { 
        owner => "root",
        group => "${group}",
    }
    
    exec { 
        "wget-pmwiki":
            command => "wget http://${server}/${path}/pmwiki-${version}.tgz",
            creates => "${docroot}-${version}.tgz";

        "untar-pmwiki":
            command => "tar --group ${group} -zxf ${docroot}-${version}.tgz",
            unless  => "test -d ${docroot}-${version}",
            require => Exec["wget-pmwiki"];
    }

    file { 
        "${docroot}-${version}":
            recurse => true,
            require => Exec["untar-pmwiki"];
        
        "${docroot}":
            ensure  => "${docroot}-${version}",
            require => File["${docroot}-${version}"];
        
        ["${docroot}/wiki.d", "${docroot}/uploads"]:
            ensure  => directory,
            mode    => "2775",
            require => File["${docroot}"];
        
        "${docroot}/index.php": 
            content => "<?php include('pmwiki.php');", 
            require => File["${docroot}"];
        
        "${docroot}/.htaccess": 
            mode    => "644",
            source  => "puppet:///pmwiki/htaccess",
            require => File["${docroot}"];
    }
}

# define pmwiki::sync sets up the script and cron entry to copy the
# pmwiki directory tree via rsync from one node to the other.
#
# Variables used:
# $dest: Destination node, passed to the rsync script in cron entry.
# $dir: Directory to copy, passed to the rsync script in cron entry.
#
# Example usage:
# pmwiki::sync { "${hostname}":
#   dest => "web1f",
#   dir  => "/srv/www/pmwiki",
# }
define pmwiki::sync ($dest = '', $dir = '') {
    file { "/usr/local/bin/rsync-pmwiki":
        ensure => present,
        mode   => 0755,
        source => "puppet:///pmwiki/rsync-pmwiki",
    }
    cron { "rsync-pmwiki":
        command => "/usr/local/bin/rsync-pmwiki ${dest} ${dir}",
        minute  => "*/15",
    }
}
# vi:syntax=puppet:filetype=puppet:ts=4:et:
# EOF
