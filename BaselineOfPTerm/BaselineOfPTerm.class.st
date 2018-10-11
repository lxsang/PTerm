Class {
	#name : #BaselineOfPTerm,
	#superclass : #BaselineOf,
	#category : #BaselineOfPTerm
}

{ #category : #baselines }
BaselineOfPTerm >> baseline: spec [
spec for: #common do: [ 
	<baseline>
	"spec preLoadDoIt: #preload."
	spec
		package: 'PTerm-Core';
		package: 'PTerm-Test';
		group: 'default' with: #('PTerm-Core' 'PTerm-Test')
]
]
