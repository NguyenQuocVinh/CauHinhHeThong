# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
	. ~/.bashrc
fi

# User specific environment and startup programs


export PATH
export TZ=Asia/Ho_Chi_Minh
alias rsqlplus="rlwrap sqlplus '/ as sysdba'"
alias rimp="rlwrap imp"
alias rimpdp="rlwrap impdp"
alias rexp="rlwrap exp"
alias rexpdp="rlwrap expdp"
alias rlsnrctl="rlwrap lsnrctl"
alias rrman="rlwrap rman target /"
alias radrci="rlwrap adrci"
