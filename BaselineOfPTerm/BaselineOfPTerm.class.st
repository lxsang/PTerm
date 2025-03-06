Class {
	#name : #BaselineOfPTerm,
	#superclass : #BaselineOf,
	#category : #BaselineOfPTerm
}

{ #category : #baselines }
BaselineOfPTerm >> baseline: spec [

	<baseline>
	spec for: #common do: [
		spec
			package: 'PTerm-Core'
			with: [ spec requires: #( 'PTerm-Protocol' ) ];
			package: 'PTerm-Test';
			package: 'PTerm-Protocol';
			package: 'PTerm-Fonts';
			package: 'PTerm-UI';
			group: 'default' with: #( 'PTerm-Core' 'PTerm-Test' 'PTerm-Fonts' 'PTerm-UI' ).
			SystemVersion current major  >= 13 ifTrue: [
				spec postLoadDoIt: #postload.
				spec package: 'PTerm-SystemInterface'.
				spec group: 'default' with: #( 'PTerm-SystemInterface' )
			]
	 ].
]

{ #category : #baselines }
BaselineOfPTerm >> postload [

	StTerminalInterface default: PTTerminalInterface new.
]
