"
I am a single layer in a LayeredProtocol stack.  I pass information up and down the stack, possibly transforming it in the process.

Structure:
	down		(ProtocolLayer) My low protocol, 
			     one element closer to the ""remote connection"" end of the stack.
	up			(ProtocolLayer) My high protocol, 
				  one element closer to the user interface or other ""local client"".
	session	(LayeredProtocol) The entire collection of ProtocolLayers of which I am one.

"
Class {
	#name : #ProtocolLayer,
	#superclass : #Object,
	#instVars : [
		'session',
		'up',
		'down'
	],
	#category : #'PTerm-Protocol'
}

{ #category : #stack }
ProtocolLayer >> asProtocolStack [
	"Answer a new LayeredProtocol in which I am the lowest element."

	^LayeredProtocol on: self
]

{ #category : #accessing }
ProtocolLayer >> down: protoLo [

	down := protoLo
]

{ #category : #stack }
ProtocolLayer >> downcall: anObject [
	"Receive anObject from my high protocol. The default behaviour is to pass it down unmodified to my low protocol (i.e., I am transparent)."

	down ifNotNil: [ :aProtocolLayer | 
		aProtocolLayer downcall: anObject ]
]

{ #category : #stack }
ProtocolLayer >> downcallAll: aCollection [
	"Receive aCollection of data from my high protocol. The default behaviour is to act as if each datum was received individually."

	aCollection do: [:each | self downcall: each]
]

{ #category : #stack }
ProtocolLayer >> flush [
	"Inform my high protocol that we might be about to pause for a while."

	up flush
]

{ #category : #stack }
ProtocolLayer >> install [
	"Perform any additional actions when creating the initial up/down connections between elements in the ProtocolStack."
]

{ #category : #testing }
ProtocolLayer >> isConnected [

	^false
]

{ #category : #session }
ProtocolLayer >> note: aSymbol with: anArgument [
	"My session is informing me that something has happened.  By default I don't care about it."
]

{ #category : #stack }
ProtocolLayer >> passUp: anObject [
	"Pass anObject up to my high protocol."

	up upcall: anObject
]

{ #category : #stack }
ProtocolLayer >> push: aProtocol [
	"Push aProtocol on top of the receiver."

	^(LayeredProtocol on: self) push: aProtocol
]

{ #category : #stack }
ProtocolLayer >> run [
	"Perform any additional actions when starting the protocol running (i.e., just before data transfer begins)."
]

{ #category : #accessing }
ProtocolLayer >> session [

	^session
]

{ #category : #accessing }
ProtocolLayer >> session: aSession [

	session := aSession
]

{ #category : #session }
ProtocolLayer >> sessionNote: aSymbol [
	"Tell my session that something has happened.  If I have no session then do nothing."

	session isNil ifFalse: [session note: aSymbol with: nil]
]

{ #category : #session }
ProtocolLayer >> sessionNote: aSymbol with: anArgument [
	"Tell my session that something has happened.  If I have no session then do nothing."

	session isNil ifFalse: [session note: aSymbol with: anArgument]
]

{ #category : #diagnostics }
ProtocolLayer >> ttyCR [

	self ttyMsg: String cr
]

{ #category : #diagnostics }
ProtocolLayer >> ttyMsg: aString [

	aString withInternetLineEndings asByteArray do: [:b | up upcall: b].
	up flush
]

{ #category : #diagnostics }
ProtocolLayer >> ttyMsgCR: aString [

	self ttyMsg: aString, String cr
]

{ #category : #accessing }
ProtocolLayer >> up: protoHi [

	up := protoHi
]

{ #category : #stack }
ProtocolLayer >> upcall: anObject [
	"Receive anObject from my low protocol.  Default is to pass it on to my high protocol unmodified (in other words, I am transparent)."

	up ifNotNil: [ :aProtocolLayer | 
		aProtocolLayer upcall: anObject ]
]

{ #category : #stack }
ProtocolLayer >> upcallAll: aCollection [
	"Receive aCollection of data from my low protocol.  By default I act as if each datum had been received individually."

	aCollection do: [:b | self upcall: b]
]
