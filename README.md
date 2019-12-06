## Install

This creates a git repo in your home directory, but the gitignore file ignores
all files by default, so you just force add your dotfiles, and you can treat
them as part of a normal git repo, i.e. no symlinks or install scripts.

```
cd ~
git clone --bare https://github.com/lollipopman/dotfiles.git .git
git config --local --bool core.bare false
git reset --hard @
```

## Usage

```
git add -f .tmux.conf
git commit -m 'tmux rocks!'
git push
```
