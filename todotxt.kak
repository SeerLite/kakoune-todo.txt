# Detection
# ‾‾‾‾‾‾‾‾‾

hook global WinSetOption filetype=todotxt %{
    set-option buffer filetype todotxt

    # TODO: Remove -override from all command definitions and make this a module
    define-command -override -docstring 'sort items by priority and state' todotxt-sort %{
        execute-keys -draft '%' | 'sort --stable --key=1,1' <ret>
    }

    declare-option -hidden str todotxt_file_buffer
    declare-option -hidden str-list todotxt_filter_jump_final_selections
    declare-option -hidden str-list todotxt_filter_original_locations

    define-command -override -hidden todotxt-filter-jump %{
        set-option global todotxt_filter_jump_final_selections
        evaluate-commands -draft %{
            execute-keys <a-s>
            evaluate-commands %sh{
                awk 'BEGIN {
                    current_str = "'"$kak_selections_desc"'";
                    orig_str = "'"$kak_opt_todotxt_filter_original_locations"'";
                    split(current_str, current, " ");
                    split(orig_str, orig, " ");

                    printf "set-option global todotxt_filter_jump_final_selections "
                    for (i = 1; i <= length(current); i++) {
                        current_sel = current[i];

                        current_line = current[i];
                        sub(/\..*/, "", current_line);

                        original_line = orig[current_line];
                        sub(/\..*/, "", original_line);

                        new_sel = current_sel;
                        sub(/[0-9]+\./, original_line ".", new_sel);
                        sub(/,[0-9]+\./, "," original_line ".", new_sel);

                        printf " " new_sel;
                    }
                    printf "\n"
                }'
            }
        }
        buffer %opt{todotxt_file_buffer}
        select %opt{todotxt_filter_jump_final_selections}
        set-option global todotxt_filter_jump_final_selections
    }

    define-command -override -docstring 'filter todo entries' todotxt-filter -params 1 %{
        evaluate-commands -save-regs r -draft %{
            # Create the filter buffer if it doesn't exist
            evaluate-commands -draft %{
                edit -scratch *todotxt-filter*
            }
            set-option buffer=*todotxt-filter* todotxt_file_buffer %val{bufname}

            # (
            execute-keys '%' <a-s> <a-K> '^x ' <ret> <a-k> "\Q%arg{1}\E" <ret> ) '"' r y
            set-option buffer=*todotxt-filter* todotxt_filter_original_locations %val{selections_desc}

            buffer *todotxt-filter*
            set-option buffer filetype todotxt
            map buffer normal <ret> ':todotxt-filter-jump<ret>'

            set-option buffer readonly false
            execute-keys '%' d
            execute-keys '"' r <a-P> gj d
            set-option buffer readonly true
        }
        buffer *todotxt-filter*
    }
}

set-face global TodotxtPriorityA red+b
set-face global TodotxtPriorityB yellow+b
set-face global TodotxtPriorityC cyan+b
set-face global TodotxtDate default+b

add-highlighter shared/todotxt group
# Done items
add-highlighter shared/todotxt/comment regex "^x ([^\n]+)" 0:comment
# Priorities
add-highlighter shared/todotxt/priority group
evaluate-commands %sh{
    for letter in A B C D E F G H I J K L M N O P Q R S T U V W X Y Z; do
        printf 'add-highlighter shared/todotxt/priority/ regex "^\\(%s\\)" 0:TodotxtPriority%s\n' $letter $letter
    done
}
# Key/value tags
add-highlighter shared/todotxt/key-value regex "([^:|^ ]+:)([^ |^\n]+)" 0:string 1:variable
# Project (+) and context (@) tags
add-highlighter shared/todotxt/function regex "(\+[^\+|^ |^\n]+)" 0:function
add-highlighter shared/todotxt/meta regex "(@[^\+|^ |^\n]+)" 0:meta
# Dates
add-highlighter shared/todotxt/date regex "(\d{4}-\d{2}-\d{2})" 0:TodotxtDate

hook global WinSetOption filetype=todotxt %{
    set-option buffer comment_line 'x'
}

hook -group todotxt-highlight global WinSetOption filetype=todotxt %{
    add-highlighter window/todotxt ref todotxt
    hook -once -always window WinSetOption filetype=.* %{
        remove-highlighter window/todotxt
    }
}
