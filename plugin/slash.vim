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

function! s:set_repeated_move_type(seq)
  " Vmaps work by replacing * and # with yank text then search the underlying
  " word. We have to recognize these modes in order to override * and # keys
  " in normal mode later, remapping then to n or N as desired.

  if mode() == 'v' && a:seq[0:1] ==# 'y/'
    let b:slash_repeated_move = 'visual_forward'
  elseif mode() == 'v' && a:seq[0:1] ==# 'y?'
    let b:slash_repeated_move = 'visual_backward'
  else
    let b:slash_repeated_move = 'normal'
  endif
endfunction

function! s:revert_search_direction(key)
  if a:key ==# 'n'
    return 'N'
  elseif a:key ==# 'N'
    return 'n'
  elseif
    return a:key
  endif
endfunction

function! s:star_to_forward_backward(key)
  if a:key ==# '*'
    return 'n'
  elseif a:key ==# '#'
    return 'N'
  else
    return a:key
  endif
endfunction

function! s:immobile(seq)
  let repeated_move = get(b:, 'slash_repeated_move', '')

  if repeated_move ==# 'normal'
    return a:seq
  elseif repeated_move ==# 'visual_forward'
    return s:star_to_forward_backward(a:seq)
  elseif repeated_move ==# 'visual_backward'
    return s:revert_search_direction(s:star_to_forward_backward(a:seq))
  endif

  let s:winline = winline()
  call s:set_repeated_move_type(a:seq)
  return a:seq."\<plug>(slash-prev)"
endfunction

function! s:trailer()
  augroup slash
    autocmd!
    autocmd CursorMoved,CursorMovedI * set nohlsearch | let b:slash_repeated_move = '' | autocmd! slash
  augroup END

  let seq = foldclosed('.') != -1 ? 'zo' : ''
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
noremap         <plug>(slash-prev)    <c-o>
inoremap        <plug>(slash-prev)    <nop>

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
