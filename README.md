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

```vim
" zz after search
map <plug>(slash-after) zz
```
