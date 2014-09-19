bash-idh: Bash Interactive Directory History
============================================

bash-idh enables Bash shell users to transparently view and interact with
Bash's built-in directory stack.  The interface is much cleaner and much
less cryptic than the built-in "dirs", "pushd" and "popd" commands.

For example, if in a Bash session you've visited /tmp, /usr/local/src/,
/etc/init.d/, and /home/user/ (where your account name is "user"), the
built-in Bash command "dirs" will show ("~" indicates your home dir):

    /tmp /usr/local/src /etc/init.d ~

If you have enabled bash-idh, your prompt will instead look like: 

    <3> /tmp
    <2> /usr/local/src/
    <1> /etc/init.d
    [~ user@machine]$ 

and you can issue the command "back 3" to change the current directory
to the 3rd most recent directory you've visited (/tmp).

bash-idh was inspired in part by similar ideas from JP Software's 4DOS

To use bash-idh, source bash-idh.sh from your .bashrc file.  For example:

    source /path/to/bash-idh.sh

bash-idh.sh works in part by modifying the value of the $PROMPT_COMMAND
environment variable to prune stale directories from the Bash directory
stack and then print out the most recently visited directories, one per
line, above the Bash command prompt.  

The commands below are intended to be issued from an interactive shell.
See the top of bash-idh.sh for more customization possibilities.

Bash-IDH commands
-----------------

back  Navigate the directory history by giving this command followed by
      the number corresponding to a directory history entry to which
      you want to return.

      Usage: "back n"   (where n is a directory history entry number)

      For example, "back 3" will change the current directory to the
      directory listed as #3 in the directory history listing (i.e.,
      the Bash directory stack).

cd    This function overrides Bash's builtin cd command, to keep the
      directory stack from accumulating non-unique entries.  In every
      other respect, it works the same way as Bash's builtin cd.

drop  Use this function to remove individual directory history entries or
      ranges of them.

      Usage: "drop [n | n-m | -n | n- | all]"
             (where n,m are directory history entries)

      For example, "drop 15- 6 -2 8-12" will remove the following entries
      from the Bash directory stack (given that they exist):

         "15-": 15 (and all entries with numbers greater than 15)
           "6": 6
          "-2": 1 and 2
        "8-12": 8, 9, 10, 11 and 12

      "drop all" removes all directory stack entries.

tddh  "Toggle display directory history".  Use this command to toggle
      between three directory history lengths: max (default: 100
      entries); moderate (default: 10 entries); and none.  This allows
      you to trade off screen real estate for immediate info about the
      Bash directory stack.

      The author uses the readline configuration file, .inputrc, to map
      the [F9] key to run this command (i.e. "\e[20~":"tddh\n", under
      vt100 emulation).
