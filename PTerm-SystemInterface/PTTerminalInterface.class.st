Class {
	#name : #PTTerminalInterface,
	#superclass : #StTerminalInterface,
	#category : #'PTerm-SystemInterface-Utilities'
}

{ #category : #accessing }
PTTerminalInterface >> openTerminalOn: aPath [

	TerminalEmulator open: '/bin/sh' arguments: { 
		'-c' .
		('cd ''' , (aPath fullName copyReplaceAll: '''' with: '''\''''') , ''' && exec "${SHELL-/bin/sh}" -i ')
		}
]
