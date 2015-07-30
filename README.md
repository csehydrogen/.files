# .files

## Install

```
cd ~
git clone --depth=1 https://github.com/csehydrogen/.files.git
source .files/install.sh
```

This will overwrite local files, so be careful!

## Settings

### OS X

* System Preferences
    * Screen Saver, Energy Saver: Never
    * Dock: Left, Smallest
    * Keyboard: fast repeat, short delay, fn, caps lock > Ctrl
    * Trackpad: All
    * iCloud > iCloud Drive: uncheck
    * Sharing: Computer Name
    * Users & Groups: Guest Off
    * Long keypress off: defaults write -g ApplePressAndHoldEnabled -bool false
    * Finder start folder to ~
    * battery %, detailed time
* Applications
    * Chrome, Google Drive, xCode, KakaoTalk, XQuartz
    * iTerm2
        * [solarized palette](https://github.com/altercation/solarized)
        * [powerline patched Inconsolata-dz font](https://github.com/powerline/fonts/tree/master/InconsolataDz)
    * ShiftIt
        * fn + ←: Left
        * fn + →: Right
        * fn + ↑: Maximize
        * fn + ↓: Toggle Full Screen
    * Karabiner
        * Command_R : 한/영
* homebrew
    * vim, tmux
* cask

### Windows

* System Preferences
    * lower UAC
* Applications
    * Chrome, Google Drive, KakaoTalk, Office
