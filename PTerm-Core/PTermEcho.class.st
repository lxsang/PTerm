Class {
	#name : #PTermEcho,
	#superclass : #ProtocolEndpoint,
	#instVars : [
		'sub',
		'announcer'
	],
	#category : #'PTerm-Core'
}

{ #category : #accessing }
PTermEcho >> announcer [
	^ announcer
]

{ #category : #protocol }
PTermEcho >> close [
	"Terminate the connection to the remote entity."

	^self
]

{ #category : #protocol }
PTermEcho >> downcall: anObject [
	self announcer announce: (PTermDataEvent data: anObject asCharacter asString asByteArray  )
]

{ #category : #'server loop' }
PTermEcho >> getData [
	^ 0
]

{ #category : #initialization }
PTermEcho >> initialize [
	announcer := Announcer new.
]

{ #category : #'server loop' }
PTermEcho >> run [
	sub := self announcer when: PTermDataEvent  do: [ :e|up upcallAll: e data].

]

{ #category : #accessing }
PTermEcho >> sub [
	^ sub
]
