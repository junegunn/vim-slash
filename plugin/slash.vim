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
  return a:seq."\<plug>(slash-prev)"
endfunction

function! s:trailer()
  augroup slash
    autocmd!
    autocmd CursorMoved,CursorMovedI * set nohlsearch | autocmd! slash
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
  return seq . maparg("<plug>(slash-after)", mode())
endfunction

function! SlashEscape(backward)
  return '\V'.substitute(escape(@", '\' . (a:backward ? '?' : '/')), "\n", '\\n', 'g')
endfunction

noremap  <expr> <plug>(slash-trailer) <sid>trailer()
cnoremap        <plug>(slash-cr)      <cr>
noremap         <plug>(slash-prev)    <c-o>

cmap <expr> <cr> <sid>wrap("\<cr>")
map  <expr> n    <sid>wrap('n')
map  <expr> N    <sid>wrap('N')
map  <expr> gd   <sid>wrap('gd')
map  <expr> gD   <sid>wrap('gD')
map  <expr> *    <sid>wrap(<sid>immobile('*'))
map  <expr> #    <sid>wrap(<sid>immobile('#'))
map  <expr> g*   <sid>wrap(<sid>immobile('g*'))
map  <expr> g#   <sid>wrap(<sid>immobile('g#'))
xmap <expr> *    <sid>wrap(<sid>immobile("y/\<c-r>=SlashEscape(0)\<plug>(slash-cr)\<plug>(slash-cr)"))
xmap <expr> #    <sid>wrap(<sid>immobile("y?\<c-r>=SlashEscape(1)\<plug>(slash-cr)\<plug>(slash-cr)"))
