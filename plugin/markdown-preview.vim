" ========== Simple Markdown Preview Plugin ==========
" Preview the current Markdown buffer with glow, in a vertical split.
" Opened/toggled with <Leader>mp (or :MarkdownPreviewToggle); press q in the
" preview to close it, then toggle again to refresh the render.

function! ToggleMarkdownPreview()
  " Close any existing preview window and return to the source window
  for l:winnr in range(1, winnr('$'))
    if getwinvar(l:winnr, 'is_markdown_preview', 0)
      let l:source_winnr = getwinvar(l:winnr, 'source_winnr', 0)
      execute l:winnr . 'wincmd w'

      quit!

      if l:source_winnr > 0 && l:source_winnr <= winnr('$')
        execute l:source_winnr . 'wincmd w'
      endif
      return
    endif
  endfor

  " No preview yet: capture source window and its text before splitting
  let l:source_winnr = winnr()
  let l:content = getline(1, '$')
  let l:width = max([4, float2nr(&columns * 0.5)])

  if executable('glow') && has('terminal')
    " Render in a terminal window fed by glow
    let l:temp_file = tempname() . '.md'
    call writefile(l:content, l:temp_file)

    execute 'rightbelow vertical terminal glow -s dark -w ' . (l:width - 4) . ' ' . l:temp_file
    execute 'vertical resize ' . l:width

    " Scroll to the top after glow has rendered
    call timer_start(500, {-> feedkeys("\<C-\>\<C-n>gg")})

    " Remove the render input after glow has had time to read it
    " (a lambda must reference the var without the l: prefix)
    call timer_start(2000, {-> delete(temp_file)})
  else
    " Fallback: show the raw text in a scratch buffer
    execute 'rightbelow vnew'
    execute 'vertical resize ' . l:width

    setlocal buftype=nofile noswapfile nobuflisted
    call setline(1, l:content)
    setlocal ft=markdown readonly nomodifiable
  endif

  " Remember this window so toggling can find it again
  let w:is_markdown_preview = 1
  let w:source_winnr = l:source_winnr

  " Close mapping inside the preview window
  nnoremap <buffer> q :call ToggleMarkdownPreview()<CR>
  if has('terminal') && &buftype == 'terminal'
    tnoremap <buffer> q <C-\><C-n>:call ToggleMarkdownPreview()<CR>
  endif
endfunction

" Keep the preview half-width when the whole window is resized
function! ResizeMarkdownPreview()
  for l:winnr in range(1, winnr('$'))
    if getwinvar(l:winnr, 'is_markdown_preview', 0)
      let l:width = max([4, float2nr(&columns * 0.5)])
      execute l:winnr . 'wincmd w'
      execute 'vertical resize ' . l:width
      wincmd p
      return
    endif
  endfor
endfunction

augroup MarkdownPreview
  autocmd!
  autocmd VimResized * call ResizeMarkdownPreview()
augroup END

command! MarkdownPreviewToggle call ToggleMarkdownPreview()
nnoremap <Leader>mp :MarkdownPreviewToggle<CR>
