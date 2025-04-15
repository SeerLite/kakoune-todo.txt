# Detection
# ‾‾‾‾‾‾‾‾‾

hook global WinSetOption filetype=todotxt %{
    set-option buffer filetype todotxt

    define-command -hidden todotxt-done2bottom %{
        try %{
            execute-keys '%<a-s><a-k>^x <ret>dge<a-p>:echo %reg{#} items moved<ret>'
        }
    }
    define-command -hidden todotxt-a2top %{
        try %{
            execute-keys '%<a-s><a-k>^\(A\) <ret>dgg<a-P>:echo %reg{#} items moved<ret>'
        }
    }
    define-command -hidden todotxt-b2top %{
        try %{
            execute-keys '%<a-s><a-k>^\(B\) <ret>dgg<a-P>:echo %reg{#} items moved<ret>'
        }
    }
    define-command -hidden todotxt-c2top %{
        try %{
            execute-keys '%<a-s><a-k>^\(C\) <ret>dgg<a-P>:echo %reg{#} items moved<ret>'
        }
    }
    define-command -docstring 'sort items by priority and state' todotxt-sort %{
      execute-keys '%:todotxt-c2top<ret>:todotxt-b2top<ret>:todotxt-a2top<ret>:todotxt-done2bottom<ret>'
    }
    define-command -docstring 'mark item under cursor as done' todotxt-mark-done %{
        try %{
            execute-keys 'xs\([ABC]\) <ret>cx <esc>'
        } catch %{
            execute-keys 'ghix <esc>'
        }
    }
    define-command -docstring 'mark item under cursor as high priority' -params 1 todotxt-mark-prio %{
        try %{
            execute-keys "xs^(\([ABC]\)|x) <ret>c(%arg{1}) <esc>"
        } catch %{
            execute-keys "ghi(%arg{1}) <esc>"
        }
    }

    declare-option -hidden str todotxt_file_buffer
    declare-option -hidden str-list todotxt_filter_jump_final_selections

    define-command -hidden todotxt-filter-jump %{
        set-option global todotxt_filter_jump_final_selections
        evaluate-commands -draft %{
            execute-keys <a-s>
            evaluate-commands -itersel -draft -save-regs l %{
                evaluate-commands -draft %{
                    execute-keys x <a-K> '^$' <ret> '"' l *
                }
                evaluate-commands -buffer %opt{todotxt_file_buffer} %{
                    execute-keys '%' '"' l s <ret>
                    set-option -add global todotxt_filter_jump_final_selections %val{selection_desc}
                }
            }
        }
        buffer %opt{todotxt_file_buffer}
        select %opt{todotxt_filter_jump_final_selections}
        set-option global todotxt_filter_jump_final_selections
    }
    define-command -docstring 'filter todo entries' todotxt-filter -params 1 %{
        evaluate-commands -save-regs rb -draft %{
            set-register b %val{bufname}
            execute-keys '%' <a-s> "<a-k>\Q%arg{1}\E<ret>" '"' r y
            edit -scratch *todotxt-filter*
            set-option buffer filetype todotxt
            set-option buffer todotxt_file_buffer %reg{b}
            map buffer normal <ret> ': todotxt-filter-jump<ret>'
            execute-keys '%' d '"' r <a-P>
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

hook -group todotxt-highlight global WinSetOption filetype=todotxt %{
    add-highlighter window/todotxt ref todotxt
    hook -once -always window WinSetOption filetype=.* %{
        remove-highlighter window/todotxt
    }
}
