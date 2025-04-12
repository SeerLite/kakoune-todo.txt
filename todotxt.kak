# Detection
# ‾‾‾‾‾‾‾‾‾

hook global WinSetOption filetype=todotxt %{
    set-option buffer filetype todotxt

    define-command -hidden todo-done2bottom %{
        try %{
            execute-keys '%<a-s><a-k>^x <ret>dge<a-p>:echo %reg{#} items moved<ret>'
        }
    }
    define-command -hidden todo-a2top %{
        try %{
            execute-keys '%<a-s><a-k>^\(A\) <ret>dgg<a-P>:echo %reg{#} items moved<ret>'
        }
    }
    define-command -hidden todo-b2top %{
        try %{
            execute-keys '%<a-s><a-k>^\(B\) <ret>dgg<a-P>:echo %reg{#} items moved<ret>'
        }
    }
    define-command -hidden todo-c2top %{
        try %{
            execute-keys '%<a-s><a-k>^\(C\) <ret>dgg<a-P>:echo %reg{#} items moved<ret>'
        }
    }
    define-command -docstring 'sort items by priority and state' todo-sort %{
      execute-keys '%:todo-c2top<ret>:todo-b2top<ret>:todo-a2top<ret>:todo-done2bottom<ret>'
    }
    define-command -docstring 'mark item under cursor as done' todo-mark-done %{
        try %{
            execute-keys 'xs\([ABC]\) <ret>cx <esc>'
        } catch %{
            execute-keys 'ghix <esc>'
        }
    }
    define-command -docstring 'mark item under cursor as high priority' -params 1 todo-mark-prio %{
        try %{
            execute-keys "xs^(\([ABC]\)|x) <ret>c(%arg{1}) <esc>"
        } catch %{
            execute-keys "ghi(%arg{1}) <esc>"
        }
    }

    # Only set in buffer scope in *todotxt-filter* buffer
    declare-option -hidden str todotxt_file_buffer

    define-command -hidden todo-filter-jump %{
        evaluate-commands -save-regs l %{
            evaluate-commands -draft %{
                execute-keys x '"' l *
            }
            buffer %opt{todotxt_file_buffer}
            execute-keys g e '"' l n
        }
    }
    define-command -docstring 'filter todo entries' todo-filter -params 1 %{
        evaluate-commands -save-regs rb -draft %{
            set-register b %val{bufname}
            execute-keys '%' <a-s> "<a-k>\Q%arg{1}\E<ret>" '"' r y
            edit -scratch *todotxt-filter*
            set-option buffer filetype todotxt
            set-option buffer todotxt_file_buffer %reg{b}
            map buffer normal <ret> ': todo-filter-jump<ret>'
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
