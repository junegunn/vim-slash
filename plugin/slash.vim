" The MIT License (MIT)
"
" Copyright (c) 2016 Junegunn Choi
"
" Permission is hereby granted, free of charge, to any person obtaining a copy
" of this software and associated documentation files (the "Software"), to deal
" in the Software without restriction, including without limitation the rights
" to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
" copies of the Software, and to permit persons to whom the Software is
" furnished to do so, subject to the following conditions:
"
" The above copyright notice and this permission notice shall be included in
" all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
" IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
" FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
" AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
" LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
" OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
" THE SOFTWARE.

function! s:wrap(seq)
  if mode() == 'c' && stridx('/?', getcmdtype()) < 0
    return a:seq
  endif
  silent! autocmd! slash
  set hlsearch
  return a:seq."\<plug>(slash-trailer)"
endfunction

function! s:immobile(seq)
  let s:winline = winline()
  let s:pos = getpos('.')
  return a:seq."\<plug>(slash-prev)"
endfunction

function! s:trailer()
  augroup slash
    autocmd!
    autocmd CursorMoved,CursorMovedI * set nohlsearch | autocmd! slash
  augroup END

  let seq = foldclosed('.') != -1 ? 'zv' : ''
  if exists('s:winline')
    let sdiff = winline() - s:winline
    unlet s:winline
    if sdiff > 0
      let seq .= sdiff."\<c-e>"
    elseif sdiff < 0
      let seq .= -sdiff."\<c-y>"
    endif
  endif
  let after = len(maparg("<plug>(slash-after)", mode())) ? "\<plug>(slash-after)" : ''
  return seq . after
endfunction

function! s:trailer_on_leave()
  augroup slash
    autocmd!
    autocmd InsertLeave * call <sid>trailer()
  augroup END
  return ''
endfunction

function! s:prev()
  return getpos('.') == s:pos ? '' : '``'
endfunction

function! s:escape(backward)
  return '\V'.substitute(escape(@", '\' . (a:backward ? '?' : '/')), "\n", '\\n', 'g')
endfunction

function! slash#blink(times, delay)
  let s:blink = { 'ticks': 2 * a:times, 'delay': a:delay }

  function! s:blink.tick(_)
    let self.ticks -= 1
    let active = self == s:blink && self.ticks > 0

    if !self.clear() && active && &hlsearch
      let [line, col] = [line('.'), col('.')]
      let w:blink_id = matchadd('IncSearch',
            \ printf('\%%%dl\%%>%dc\%%<%dc', line, max([0, col-2]), col+2))
    endif
    if active
      call timer_start(self.delay, self.tick)
      if has('nvim')
        call feedkeys("\<plug>(slash-nop)")
      endif
    endif
  endfunction

  function! s:blink.clear()
    if exists('w:blink_id')
      call matchdelete(w:blink_id)
      unlet w:blink_id
      return 1
    endif
  endfunction

  call s:blink.clear()
  call s:blink.tick(0)
  return ''
endfunction

map      <expr> <plug>(slash-trailer) <sid>trailer()
imap     <expr> <plug>(slash-trailer) <sid>trailer_on_leave()
cnoremap        <plug>(slash-cr)      <cr>
noremap  <expr> <plug>(slash-prev)    <sid>prev()
inoremap        <plug>(slash-prev)    <nop>
noremap!        <plug>(slash-nop)     <nop>

cmap <expr> <cr> <sid>wrap("\<cr>")
map  <expr> n    <sid>wrap('n')
map  <expr> N    <sid>wrap('N')
map  <expr> gd   <sid>wrap('gd')
map  <expr> gD   <sid>wrap('gD')
map  <expr> *    <sid>wrap(<sid>immobile('*'))
map  <expr> #    <sid>wrap(<sid>immobile('#'))
map  <expr> g*   <sid>wrap(<sid>immobile('g*'))
map  <expr> g#   <sid>wrap(<sid>immobile('g#'))
xmap <expr> *    <sid>wrap(<sid>immobile("y/\<c-r>=<sid>escape(0)\<plug>(slash-cr)\<plug>(slash-cr)"))
xmap <expr> #    <sid>wrap(<sid>immobile("y?\<c-r>=<sid>escape(1)\<plug>(slash-cr)\<plug>(slash-cr)"))
