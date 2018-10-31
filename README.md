# PTerm

Using Unix terminal from Pharo.

Note: this work is based on the work at: [https://github.com/pavel-krivanek/terminal](https://github.com/pavel-krivanek/terminal)

Require libc compliant with the host pharo VM (32 or 64 bits) to be installed.

![PTerm](https://github.com/lxsang/PTerm/raw/master/Pterm.gif)


## Update:
* Add unicode support
* PTerm now uses dark mode

![](https://github.com/lxsang/online_stuffs/raw/master/pterm-dark.png)

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
