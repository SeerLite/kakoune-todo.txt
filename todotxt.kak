# Detection
# ‾‾‾‾‾‾‾‾‾

hook global BufCreate .*[.]?(todo\.txt) %{
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
}

set-face global TodoPrioA red+b
set-face global TodoPrioB yellow+b
set-face global TodoPrioC cyan+b
set-face global TodoDate default+b


add-highlighter shared/todotxt group
add-highlighter shared/todotxt/comment regex "^x ([^\n]+)" 0:comment                   # done items
add-highlighter shared/todotxt/prio-a regex "^\(A\) ([^\n]+)" 0:TodoPrioA              # priority (A)
add-highlighter shared/todotxt/prio-b regex "^\(B\) ([^\n]+)" 0:TodoPrioB              # priority (B)
add-highlighter shared/todotxt/prio-c regex "^\(C\) ([^\n]+)" 0:TodoPrioC              # priority (C)
add-highlighter shared/todotxt/key-value regex "([^:|^ ]+:)([^ |^\n]+)" 0:value 1:type # key:value
add-highlighter shared/todotxt/keyword regex "(\+[^\+|^ |^\n]+)" 0:keyword             # +project
add-highlighter shared/todotxt/meta regex "(@[^\+|^ |^\n]+)" 0:meta                    # @context
add-highlighter shared/todotxt/date regex "(\d{4}-\d{2}-\d{2})" 0:TodoDate             # date

hook -group todotxt-highlight global WinSetOption filetype=todotxt %{
	add-highlighter window/todotxt ref todotxt
	hook -once -always window WinSetOption filetype=.* %{
		remove-highlighter window/todotxt
	}
}
