To set up:

```
git clone https://github.com/emmanueltouzery/nvim_config ${XDG_CONFIG_HOME:-$HOME/.config}/nvim
```

Things to install:

```
npm i -g vscode-langservers-extracted
npm i -g prettier
```

<https://github.com/takaaki-kasai/git-foresta> -- used in the telescope branches preview
`delta`, for the side-by-side preview of the <https://github.com/debugloop/telescope-undo.nvim> undo history.

<https://github.com/josephburnett/jd> -- for json diff integration

Set up https://github.com/mhinz/neovim-remote so that you have `nvr` in your path and executable to get nicer $EDITOR from within the neovim terminal. This also enables a shortcut for git interactive rebase from within neovim-remote
(I used the 'from zip' https://github.com/mhinz/neovim-remote/blob/master/INSTALLATION.md#from-zip approach to avoid using `pip`)
