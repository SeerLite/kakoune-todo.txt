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
}

set-face global TodotxtPriorityA red+b
set-face global TodotxtPriorityB yellow+b
set-face global TodotxtPriorityC cyan+b
set-face global TodotxtDate default+b


add-highlighter shared/todotxt group
add-highlighter shared/todotxt/comment regex "^x ([^\n]+)" 0:comment                        # done items
add-highlighter shared/todotxt/prio-a regex "^\(A\)" 0:TodotxtPriorityA                     # priority (A)
add-highlighter shared/todotxt/prio-b regex "^\(B\)" 0:TodotxtPriorityB                     # priority (B)
add-highlighter shared/todotxt/prio-c regex "^\(C\)" 0:TodotxtPriorityC                     # priority (C)
add-highlighter shared/todotxt/key-value regex "([^:|^ ]+:)([^ |^\n]+)" 0:string 1:variable # key:value
add-highlighter shared/todotxt/function regex "(\+[^\+|^ |^\n]+)" 0:function                # +project
add-highlighter shared/todotxt/meta regex "(@[^\+|^ |^\n]+)" 0:meta                         # @context
add-highlighter shared/todotxt/date regex "(\d{4}-\d{2}-\d{2})" 0:TodotxtDate               # date

hook -group todotxt-highlight global WinSetOption filetype=todotxt %{
	add-highlighter window/todotxt ref todotxt
	hook -once -always window WinSetOption filetype=.* %{
		remove-highlighter window/todotxt
	}
}
