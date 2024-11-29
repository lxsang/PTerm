Class {
	#name : #PTTerminalInterface,
	#superclass : #StTerminalInterface,
	#category : #'PTerm-Pharo13-Utilities'
}

{ #category : #accessing }
PTTerminalInterface >> openTerminalOn: aPath [

	TerminalEmulator open: '/bin/sh' arguments: { 
		'-c' .
		('cd ' , aPath fullName , ' && exec "${SHELL-/bin/sh}" -i ')
		}
]
