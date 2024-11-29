Class {
	#name : #PTTerminalInterface,
	#superclass : #StTerminalInterface,
	#category : #'PTerm-Pharo13-Utilities'
}

{ #category : #accessing }
PTTerminalInterface >> openTerminalOn: aPath [

	TerminalEmulator open: '/bin/bash' arguments: { 
		'-c' .
		('cd ' , aPath fullName , ' && exec bash -i ')
		}
]
