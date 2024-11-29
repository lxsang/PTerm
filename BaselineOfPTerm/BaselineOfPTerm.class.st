Class {
	#name : #BaselineOfPTerm,
	#superclass : #BaselineOf,
	#category : #BaselineOfPTerm
}

{ #category : #baselines }
BaselineOfPTerm >> baseline: spec [

	<baseline>
	spec for: #common do: [
		spec postLoadDoIt: #postload.
		spec
			package: 'PTerm-Core'
			with: [ spec requires: #( 'PTerm-Protocol' ) ];
			package: 'PTerm-Test';
			package: 'PTerm-Protocol';
			package: 'PTerm-Fonts';
			package: 'PTerm-UI';
			group: 'default' with: #( 'PTerm-Core' 'PTerm-Test' 'PTerm-Fonts' 'PTerm-UI' ) ].

	spec for: #'pharo13.x' do: [
		spec package: 'PTerm-Pharo13'.
		spec group: 'default' with: #( 'PTerm-Pharo13' ) ]
]

{ #category : #baselines }
BaselineOfPTerm >> postload [

	StTerminalInterface default: PTTerminalInterface new.
]
