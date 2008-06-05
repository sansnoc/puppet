#############################################################################
# Options and settings
#############################################################################
shopt -s cdspell
shopt -s checkhash
shopt -s checkwinsize
shopt -s cmdhist
shopt -s dotglob
shopt -s extglob
shopt -s lithist
shopt -s nocaseglob
shopt -s no_empty_cmd_completion
set -o vi
set -o notify
set -o allexport
umask 027

#############################################################################
# Environment variables
#############################################################################
PATH="/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin:/usr/X11R6/bin:$HOME/bin"
MANPATH="/usr/man:/usr/local/man:/usr/share/man:/usr/local/share/man:/usr/X11R6/man"
HISTSIZE="5000"
# Set to avoid spamming up the history file
HISTIGNORE="cd:ls:[bf]g:clear:exit"
# Set to timestamp history entries and preserve across sessions
HISTTIMEFORMAT="%D %R: "
VISUAL="vi"
EDITOR="vi"
# this prompt will show the hostname in green if the last command returned 0,
# otherwise it will be red.
PS1="\[\`if [[ \$? = "0" ]]; then echo '\e[32m\h\e[0m'; else echo '\e[31m\h\e[0m' ; fi\`:\w\n\$ "
PS2=" "
PAGER="/usr/bin/less"
# Adjust ls color output for a white background terminal (removes bold).
LS_COLORS='no=00:fi=00:di=00;34:ln=00;36:pi=40;33:so=00;35:do=00;35:bd=40;33;01:cd=40;33;01:or=40;31;01:su=37;41:sg=30;43:ex=00;32:*.tar=00;31:*.tgz=00;31:*.arj=00;31:*.taz=00;31:*.lzh=00;31:*.zip=00;31:*.z=00;31:*.Z=00;31:*.gz=00;31:*.bz2=00;31:*.deb=00;31:*.rpm=00;31:*.jar=00;31:*.jpg=00;35:*.jpeg=00;35:*.gif=00;35:*.bmp=00;35:*.pbm=00;35:*.pgm=00;35:*.ppm=00;35:*.tga=00;35:*.xbm=00;35:*.xpm=00;35:*.tif=00;35:*.tiff=00;35:*.png=00;35:*.mov=00;35:*.mpg=00;35:*.mpeg=00;35:*.avi=00;35:*.fli=00;35:*.gl=00;35:*.dl=00;35:*.xcf=00;35:*.xwd=00;35:*.flac=00;35:*.mp3=00;35:*.mpc=00;35:*.ogg=00;35:*.wav=00;35:'

# Make the titlebar of the window show where we are at if logged in via ssh
# (putty window or X11 window) or from a local GNOME session (ie gnome-terminal)
if [ ! -z $SSH_TTY ] || [ ! -z $GDMSESSION ]
then
    PROMPT_COMMAND='echo -ne "\033]0;${HOSTNAME}:${PWD}\007"'
    # Run a couple informational commands upon login.
    df -h -l
    uptime
fi

#############################################################################
# Aliases
#############################################################################
# make some common commands more useful.
if [ 'OpenBSD' == `uname` ]
then
    alias ls="ls -F"
else
    alias ls="ls --color=auto -hF --file-type"
fi

alias lz="ls -FalZ --color=auto"
alias du="du -mcx"
alias df="df -Tm"
alias free="free -m"
alias today="date +%F"
# navigation shortcuts
alias ..="cd .."
alias -- -="cd -"
# old habits die hard
alias more="/usr/bin/less"
# Quickly add sshkey.
alias sshkey="ssh-add $HOME/.ssh/id_dsa"
# vim > vi
alias vi=/usr/bin/vim
alias ps="COLUMNS=320 ps"
#############################################################################
# Set up other variables and configuration.
#############################################################################
if [ -f ~/.bashrc.local ]
then
    . ~/.bashrc.local
fi

function lsd {
    if [ -d $1 ]; then
        cd $1
        shift
        ls $@
    else 
        file $1
    fi
}

# Don't export all variables in the actual shell, just for the profile...
set +o allexport

# vim modeline - have 'set modeline' and 'syntax on' in your ~/.vimrc.
# vi:syntax=sh:filetype=sh:ts=4:et:
# EOF
