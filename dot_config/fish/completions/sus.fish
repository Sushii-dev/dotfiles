# Fish completion for `sus` -- driven by `sus --list` (name<TAB>description).
#
# Keeping the source of truth in the dispatcher means new sus-<cmd> helpers
# show up in completion as soon as they're added to the registry, no edits here.

# Only offer subcommands when no subcommand has been given yet.
function __sus_needs_command
    set -l cmd (commandline -opc)
    test (count $cmd) -eq 1
end

complete -c sus -f

# First argument: subcommands from the live registry, with descriptions.
for line in (sus --list 2>/dev/null)
    set -l parts (string split \t -- $line)
    if test (count $parts) -ge 2
        complete -c sus -n __sus_needs_command -a $parts[1] -d $parts[2]
    else if test (count $parts) -ge 1
        complete -c sus -n __sus_needs_command -a $parts[1]
    end
end

# `sus install <category>`: offer the curated category names.
complete -c sus -n '__fish_seen_subcommand_from install' \
    -a 'tui service development editor terminal browser ai gaming' \
    -d 'curated install category'

