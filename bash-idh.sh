#
# bash-idh.sh
#
# bash-idh: Bash Interactive Directory History 
#
# See README.md at https://github.com/sarowe/bash-idh 
#

# These variables are used by the "tddh" function to cycle between three
# directory history displays: a few entries (_MODERATE); a lot of entries
# (_MAX); and no entries.  Edit these to suit.
export DISPLAY_DIR_HISTORY_MAX=100
export DISPLAY_DIR_HISTORY_MODERATE=10
export DISPLAY_DIR_HISTORY=$DISPLAY_DIR_HISTORY_MAX

# The ANSI escape sequence to use to colorize the directory history display.
# Comment this out to use the default color.
export IDH_COLOR="\e[0;33m"

# The ANSI escape sequence to use to revert to the default color.
# Comment this out if you have commented out the IDH_COLOR variable, above.
export IDH_COLOR_RESET="\e[0m"



# At each prompt: Write a toggle-able directory history display
if [[ -z "$PROMPT_COMMAND" ]] ; then
    export PROMPT_COMMAND=idhpc
elif [[ $PROMPT_COMMAND != *idhpc* ]] ; then
    # Append "idhpc" to $PROMPT_COMMAND if it's not already included
    export PROMPT_COMMAND="$PROMPT_COMMAND ; idhpc"
fi

function back ()
{
    # Navigate the directory history by giving this command followed by
    # the number corresponding to the directory history entry to which you
    # want to return.
    #
    # For example, "back 3" will change the current directory to the
    # directory listed as #3 in the directory history listing (i.e., the
    # Bash directory stack).
    #
    local dest num_back="$1"
    if [ -z "$num_back" ]; then
        num_back="1"
    fi
    if [ ${#DIRSTACK[@]} -gt $num_back ]; then
        dest="${DIRSTACK[$num_back]}"
        builtin popd -n +$num_back >/dev/null
        builtin pushd "${dest/[~]/$HOME}" >/dev/null
    fi
}

function drop ()
{
    # Use this function to remove individual directory history entries or
    # ranges of them.
    #
    # Usage: drop [n | n-m | -n | n-] (where n,m are directory history entries)
    #
    # This function does a reverse numeric sort on its arguments, so that the
    # eldest members get removed before the youngest, thus avoiding position-
    # altering displacements.
    #
    local help=0
    local gong=";;;" # The value of $gong has to match that in range_expand()
    local use="Usage: drop [ n | n-m | -n | n- | all]+ (n,m: dir. history entries)"
    local a b
    if [ $# -ge 1 ]; then
        if [ "$1" = "all" ]; then
            builtin dirs -c       # Clear all entries in dir history
        else
            for a in $(range_expand $*) ; do
                case $a in
                    [1-9] | [1-9][0-9] ) builtin popd -n +$a >/dev/null;;

                    ${gong}* ) b=${a##$gong}
                        echo "drop: '$b': not in range of directory history."
                        help=1;;

                    * ) echo "drop: '$a': not a directory history entry."
                        help=1;;
                esac
            done
        fi
        if [ $help != 0 ]; then
            echo "$use"
        fi
    else
        echo "$use"
    fi
}

function tddh ()
{
    # Toggle DISPLAY_DIR_HISTORY.  Use this command to toggle whether or not
    # the directory history is printed with every Bash prompt.
    #
    if [ "x$1" != "x" ]; then
	export DISPLAY_DIR_HISTORY=$1
    elif [ $DISPLAY_DIR_HISTORY == 0 ]; then
        export DISPLAY_DIR_HISTORY=$DISPLAY_DIR_HISTORY_MAX
    elif [ $DISPLAY_DIR_HISTORY == $DISPLAY_DIR_HISTORY_MAX ]; then
	export DISPLAY_DIR_HISTORY=$DISPLAY_DIR_HISTORY_MODERATE
   else
        export DISPLAY_DIR_HISTORY=0
    fi
    echo "Directory history display is $DISPLAY_DIR_HISTORY."
}

function cd ()
{
    # This function overrides Bash's builtin cd command, to keep the
    # directory stack from accumulating non-unique entries.
    #
    local dest="$1" orig="$PWD" dsp origdest
    if [ -z "$dest" ]; then
        dest="$HOME"
    fi
    builtin cd "$dest"
    origdest="$PWD"
    dest="${PWD/$HOME/~}"
    builtin cd "$orig"

    for ((dsp = 0 ; dsp < ${#DIRSTACK[@]} ; ++dsp)); do
        if [ "$dest" == "${DIRSTACK[$dsp]}" ]; then
            if [ $dsp -gt 0 ]; then
                # Don't do anything if changing to the current dir.
                builtin popd -n +$dsp >/dev/null
            fi
            break
        elif [ "$origdest" == "${DIRSTACK[$dsp]}" ]; then
            if [ $dsp -gt 0 ]; then
                # Don't do anything if changing to the current dir.
                builtin popd -n +$dsp >/dev/null
            fi
            break
        fi
    done
    if [ $dsp -gt 0 ]; then
        # Don't do anything if changing to the current dir.
        builtin pushd "${dest/[~]/$HOME}" >/dev/null
    fi
}

function rds ()
{
    # print up-to-date Reverse Directory Stack
    #
    local dnum
    local dirstacksize=$(( ${#DIRSTACK[@]} - 1 ))
    local max=$dirstacksize
    if [ $DISPLAY_DIR_HISTORY -ne 0 ]; then
	echo ""
    fi
    if [ $max -gt $DISPLAY_DIR_HISTORY ]; then
	max=$DISPLAY_DIR_HISTORY
    fi
    if [ -n "$IDH_COLOR" ]; then
	printf "$IDH_COLOR"
    fi
    for ((dnum = $max ; dnum > 0 ; --dnum)); do
        echo "<$dnum> ${DIRSTACK[$dnum]/$HOME/~}"
    done
    if [ $dirstacksize -gt $DISPLAY_DIR_HISTORY ]; then
        printf "<^>"
    fi
    if [ -n "$IDH_COLOR_RESET" ]; then
	printf "$IDH_COLOR_RESET"
    fi
}

function range_expand ()
{
    # This function is an internal-use only function; it's intended to be
    # called by shell function drop(), defined below.
    #
    # In descending order, print out the intersection of the sets represented
    # by expanding all arguments, which are assumed to be either numbers or
    # numeric ranges.  Ranges may take the form X-X, -X, or X-, where X is one
    # or more digits.  If a result subset is not in the inclusive range
    # [1,${#DIRSTACK[@]}], where ${#DIRSTACK[@]} is the number of entries in
    # the shell's directory history, then the offending term is not expanded,
    # but rather is prepended with a unique string (the value of the variable
    # named "$gong"); this string triggers an error message to be printed from
    # the calling drop() function.
    #
    local -a expanded
    local a b c d gong=";;;" # The value of $gong has to match that in drop()
    for a in $* ; do
        case $a in
            # A closed range: "n-m"
            [1-9]-[1-9] | [1-9]-[1-9][0-9] | [1-9][0-9]-[1-9][0-9] )
                b=${a%%-*}
                c=${a##*-}
                if [ $b -ge ${#DIRSTACK[@]} -o $c -ge ${#DIRSTACK[@]} ]; then
                    echo "$gong$a"
                else
                    if [ $c -gt $b ]; then
                        for ((d = $c ; d >= $b ; --d)); do
                            expanded[$d]=$d
                        done
                    else
                        for ((d = $b ; d >= $c ; --d)); do
                            expanded[$d]=$d
                        done
                    fi
                fi;;

            # An open range: "n-" [implies: thru last directory history entry]
            [1-9]- | [1-9][0-9]- )
                b=${a%%-}
                if [ $b -ge ${#DIRSTACK[@]} ]; then
                    echo "$gong$a"
                else
                    for (( ; b < ${#DIRSTACK[@]} ; ++b)); do
                        expanded[$b]=$b
                    done
                fi;;

            # An open range: "-n" [implies: from first directory history entry]
            -[1-9] | -[1-9][0-9] )
                b=${a##-}
                if [ $b -ge ${#DIRSTACK[@]} ]; then
                    echo "$gong$a"
                else
                    for ((c = 1 ; c <= $b ; ++c)); do
                        expanded[$c]=$c
                    done
                fi;;

            # An individual number: "n"
            [1-9] | [1-9][0-9] )
                if [ $a -ge ${#DIRSTACK[@]} ]; then
                    echo "$gong$a"
                else
                    expanded[$a]=$a
                fi;;

            # Everything else (malformed)
            * ) echo $a;;
        esac
    done
    for ((a = ${#DIRSTACK[@]} ; a > 0 ; --a)); do
        if [ -n "${expanded[$a]}" ]; then
            echo $a
        fi
    done
}

function idhpc ()
{
    # idhpc: Interactive Directory History Prompt Command
    #
    # This internal-use-only function, which is called by means of the
    # PROMPT_COMMAND environment variable, performs three tasks:
    #
    # 1. If display of the directory history is turned off but the history is
    #    not empty, print a reminder that there are entries which are not being
    #    displayed ("<^>").
    # 2. Remove directory history entries which correspond to directories which
    #    no longer exist.
    # 3. Runs the command to print out the directory history (rds).
    #
    local dnum entry
    for ((dnum = ${#DIRSTACK[@]} - 1 ; dnum > 0 ; --dnum)); do
	entry="${DIRSTACK[$dnum]}"
	if [ ! -d "${entry/[~]/$HOME}" ]; then
	    builtin popd -n +$dnum >/dev/null 2>/dev/null
	fi
    done
    rds
}

export -f back drop tddh cd rds range_expand idhpc
