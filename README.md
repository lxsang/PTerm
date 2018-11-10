# PTerm

Using Unix terminal from Pharo.

Note: this work is based on the work at: [https://github.com/pavel-krivanek/terminal](https://github.com/pavel-krivanek/terminal)

Require libc compliant with the host pharo VM (32 or 64 bits) to be installed.

![PTerm](https://github.com/lxsang/PTerm/raw/master/Pterm.gif)

## Install

Install on pharo 7

```smalltalk
Metacello new
	repository: 'github://lxsang/PTerm';
	baseline:'PTerm';
	load
```

## Usage
```Smalltalk
TerminalEmulator openShell: '/bin/bash'
```

## Fonts and Themes
### Fonts
By default, PTerm automatically downloads and uses 'DejaVu Sans Mono' as the default font, but you can always change the default font by accessing to the terminal window menu as below:

![](https://github.com/lxsang/online_stuffs/raw/master/pterm-menu.png)

Normally, the default font (DejaVu Sans Mono) supports most commonly used Unicode character.
But for those who want heavily Unicode support (Chinese, Thai, Japanese, etc.), PTerm has a second option in the window menu, that allows to automatically download and use Unifont (12 MB) as the default font. This font offers 65536 Unicode codepoints hence supports almost every language, it doesn't look really nice though.

### Themes
The default theme of PTerm can also be changed via the window menu, some available themes:
* Solarized (dark and light)
* Xterm (dark and light)
* Tango (dark and light)
* Linux console (dark and light)
* Atom (dark and light)
* Atom One (dark and light)
* more incomming...
