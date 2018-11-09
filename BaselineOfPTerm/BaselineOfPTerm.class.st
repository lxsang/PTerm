Class {
	#name : #BaselineOfPTerm,
	#superclass : #BaselineOf,
	#category : #BaselineOfPTerm
}

{ #category : #baselines }
BaselineOfPTerm >> baseline: spec [
	<baseline>
spec for: #common do: [ 
	"spec preLoadDoIt: #preload."
	spec postLoadDoIt: #checkFonts.
	spec
		package: 'PTerm-Core' with:  [ spec requires: #('PTerm-Protocol') ];
		package: 'PTerm-Test';
		package: 'PTerm-Protocol';
		package: 'PTerm-UI';
		group: 'default' with: #('PTerm-Core' 'PTerm-Test'  'PTerm-UI')
]
]

{ #category : #baselines }
BaselineOfPTerm >> checkFonts [
	TerminalEmulator checkFonts 
]
