# Detection
# ‾‾‾‾‾‾‾‾‾

provide-module todotxt %{
    define-command -docstring 'sort items by priority and state' todotxt-sort %{
        execute-keys -draft '%' | 'sort --stable --key=1,1' <ret>
    }

    declare-option -hidden str todotxt_file_buffer
    declare-option -hidden str-list todotxt_filter_jump_final_selections
    declare-option -hidden int todotxt_itersel_cursor_column
    declare-option -hidden int todotxt_itersel_anchor_column

    define-command -hidden todotxt-filter-jump %{
        set-option global todotxt_filter_jump_final_selections
        evaluate-commands -draft %{
            execute-keys <a-s>
            evaluate-commands -itersel -draft -save-regs l %{
                evaluate-commands -draft %{
                    execute-keys x <a-K> '^$' <ret> '"' l *
                }
                set-option global todotxt_itersel_cursor_column %val{cursor_column}
                execute-keys '<a-;>'
                set-option global todotxt_itersel_anchor_column %val{cursor_column}
                evaluate-commands -buffer %opt{todotxt_file_buffer} %{
                    execute-keys '%' '"' l s <ret>
                    select "%val{cursor_line}.%opt{todotxt_itersel_cursor_column},%val{cursor_line}.%opt{todotxt_itersel_anchor_column}"
                    set-option -add global todotxt_filter_jump_final_selections %val{selection_desc}
                }
                set-option global todotxt_itersel_cursor_column 0
                set-option global todotxt_itersel_anchor_column 0
            }
        }
        buffer %opt{todotxt_file_buffer}
        select %opt{todotxt_filter_jump_final_selections}
        set-option global todotxt_filter_jump_final_selections
        execute-keys ';'
    }

    declare-option -hidden str todotxt_filter_yank_command

    define-command -hidden todotxt-update-filter-buffer -params 1 %{
        evaluate-commands -save-regs rc -draft -buffer %arg{1} %{
            evaluate-commands -buffer %opt{todotxt_file_buffer} %opt{todotxt_filter_yank_command}

            # Merge selections
            evaluate-commands -draft %{
                edit -scratch *todotxt-tmp*
                execute-keys '"' r <a-P> gj d
                execute-keys '%' '"' r y
                delete-buffer *todotxt-tmp*
            }

            set-option buffer readonly false
            execute-keys '%' | %{printf '%s' "$kak_reg_r"} <ret>
            set-option buffer readonly true
        }
    }

    define-command -docstring 'filter todo entries' todotxt-filter -params 1 %{
        evaluate-commands -save-regs rb -draft %{
            set-register b %val{bufname}
            execute-keys '%' <a-s> <a-K> '^x ' <ret> <a-k> "%arg{1}" <ret> '"' r y

            # Merge selections
            evaluate-commands -draft %{
                edit -scratch *todotxt-tmp*
                execute-keys '"' r <a-P> gj d
                execute-keys '%' '"' r y
                delete-buffer *todotxt-tmp*
            }

            try %{
                buffer *todotxt-filter*
                set-option buffer readonly false
            } catch %{
                edit -scratch *todotxt-filter*
                set-option buffer filetype todotxt
                set-option buffer todotxt_file_buffer %reg{b}
                map buffer normal <ret> ':todotxt-filter-jump<ret>'
            }
            remove-hooks "buffer=%opt{todotxt_file_buffer}" todotxt-filter-update
            hook -group todotxt-filter-update "buffer=%opt{todotxt_file_buffer}" NormalIdle .* %{
                todotxt-update-filter-buffer *todotxt-filter*
            }
            set-option buffer todotxt_filter_yank_command %exp{
                execute-keys '%%' <a-s> <a-K> '^x ' <ret> <a-k> %arg{1} <ret>
                execute-keys '"' r y
            }
            execute-keys '%' | %{printf '%s' "$kak_reg_r"} <ret>
            set-option buffer readonly true
        }
        buffer *todotxt-filter*
    }

    define-command -docstring 'filter due todo entries, sorted by due date' todotxt-filter-due %{
        evaluate-commands -save-regs rb -draft %{
            set-register b %val{bufname}
            execute-keys '%' <a-s> <a-K> '^x ' <ret> <a-k> '\bdue:\S+\b' <ret> '"' r y

            # Merge selections
            evaluate-commands -draft %{
                edit -scratch *todotxt-tmp*
                execute-keys '"' r <a-P> gj d
                execute-keys '%' '"' r y
                delete-buffer *todotxt-tmp*
            }

            try %{
                buffer *todotxt-filter-due*
                set-option buffer readonly false
                # execute-keys '%' d
            } catch %{
                edit -scratch *todotxt-filter-due*
                set-option buffer filetype todotxt
                set-option buffer todotxt_file_buffer %reg{b}
                map buffer normal <ret> ':todotxt-filter-jump<ret>'
            }
            remove-hooks "buffer=%opt{todotxt_file_buffer}" todotxt-filter-due-update
            hook -group todotxt-filter-due-update "buffer=%opt{todotxt_file_buffer}" NormalIdle .* %{
                todotxt-update-filter-buffer *todotxt-filter-due*
            }
            execute-keys '%' | %{printf '%s' "$kak_reg_r"} <ret>
            execute-keys '%' 1 s '\bdue:(\S+)\b' <ret> y gh P a ' ' <esc> H s '\D' <ret> d
            execute-keys '%' | "sort -ns" <ret>
            execute-keys '%' s '^\d+ ' <ret> d
            set-option buffer todotxt_filter_yank_command %{
                execute-keys '%%' <a-s> <a-K> '^x ' <ret> <a-k> '\bdue:\S+\b' <ret>
                execute-keys '"' r y
                evaluate-commands -draft %{
                    edit -scratch *todotxt-tmp*
                    execute-keys '"' r <a-P> gj d
                    execute-keys '%' 1 s '\bdue:(\S+)\b' <ret> y gh P a ' ' <esc> H s '\D' <ret> d
                    execute-keys '%' | "sort -ns" <ret>
                    execute-keys '%' s '^\d+ ' <ret> d
                    execute-keys '%' '"' r y
                    delete-buffer *todotxt-tmp*
                }
            }
            set-option buffer readonly true
        }
        buffer *todotxt-filter-due*
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
    # Idk why this was set in the original code, see git log/blame
    set-option buffer filetype todotxt
    require-module todotxt
}

hook global WinSetOption filetype=todotxt %{
    set-option buffer comment_line 'x'
}

hook -group todotxt-highlight global WinSetOption filetype=todotxt %{
    add-highlighter window/todotxt ref todotxt
    hook -once -always window WinSetOption filetype=.* %{
        remove-highlighter window/todotxt
    }
}
