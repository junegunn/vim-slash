vim-slash
=========

vim-slash provides a set of mappings for enhancing in-buffer search experience
in Vim.

- Automatically clears search highlight when cursor is moved
- Improved star-search (visual-mode, highlighting without moving)

Installation
------------

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'junegunn/vim-slash'
```

Comparison with vim-oblique
---------------------------

vim-slash is a smaller alternative to [vim-oblique][ob]. vim-oblique depends
on [a reimplementation of Vim command-line interface][pcl] which is incomplete
and has a number of issues that cannot be easily fixed. vim-oblique is also
much slower than the native /-search when working with large files.

Many features of vim-oblique are missing in vim-slash, but [frankly, my dear,
I don't give a damn][damn].

[ob]:   https://github.com/junegunn/vim-oblique
[pcl]:  https://github.com/junegunn/vim-pseudocl
[damn]: https://en.wikipedia.org/wiki/Frankly,_my_dear,_I_don%27t_give_a_damn

Customization
-------------

#### `zz` after search

Places the current match at the center of the window.

```vim
noremap <plug>(slash-after) zz
```

#### Blinking line after search

```vim
function! s:flash()
  set cursorline!
  redraw
  sleep 20m
  set cursorline!
  return ''
endfunction

noremap <expr> <plug>(slash-after) <sid>flash()
```

#### Non-blocking blinking using Vim 8 timers

```vim
function! s:blink(ticks, delay)
  let s:blink = { 'ticks': a:ticks, 'delay': a:delay }
  function! s:blink.tick(_)
    let self.ticks -= 1
    let active = self == s:blink && self.ticks > 0
    if has_key(self, 'id')
      call matchdelete(remove(self, 'id'))
    elseif active && &hlsearch
      let [line, col] = [line('.'), col('.')]
      let self.id = matchadd('IncSearch',
            \ printf('\%%%dl\%%>%dc\%%<%dc', line, max([0, col-2]), col+2))
    endif
    if active
      call timer_start(self.delay, self.tick)
    endif
  endfunction
  call s:blink.tick(0)
  return ''
endfunction

noremap <expr> <plug>(slash-after) <sid>blink(4, 50)
```
