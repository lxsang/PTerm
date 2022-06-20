Class {
	#name : #PTermUTF8Encoder,
	#superclass : #ZnUTF8Encoder,
	#category : #'PTerm-Core'
}

{ #category : #convenience }
PTermUTF8Encoder >> decodeNextFrom: byteStream to: characterStream [
	|decodedChar position|
	byteStream atEnd ifTrue: [ ^false ].
	position := byteStream position.
	decodedChar := [ 
		self nextFromStream: byteStream
	] on: PTInvalidUTF8, PTIncompleteUTF8 do: [ :e|
		e isResumable ifFalse: [
			byteStream position: position.
			^false
		].
		e class = PTInvalidUTF8IllegalContinuationByte ifTrue:[byteStream back].
		Character codePoint: e defaultResumeValue
	].
	characterStream nextPut: decodedChar.
	^true 

]

{ #category : #convenience }
PTermUTF8Encoder >> decodeStreamUpToIncomplete: byteStream [

	^ String streamContents: [ :characterStream |
			[self decodeNextFrom: byteStream to: characterStream] whileTrue
	  ]
]

{ #category : #'error handling' }
PTermUTF8Encoder >> errorIllegalContinuationByte [

	^ PTInvalidUTF8IllegalContinuationByte signal

]

{ #category : #'error handling' }
PTermUTF8Encoder >> errorIllegalLeadingByte [

	^ PTInvalidUTF8IllegalLeadingByte signal

]

{ #category : #'error handling' }
PTermUTF8Encoder >> errorIncomplete [
	^ PTIncompleteUTF8 signal

]

{ #category : #'error handling' }
PTermUTF8Encoder >> errorOutsideRange [

	^ PTInvalidUTF8OutsideRange signal

]

{ #category : #'error handling' }
PTermUTF8Encoder >> errorOverlong [

	^ PTInvalidUTF8Overlong signal

]

{ #category : #converting }
PTermUTF8Encoder >> nextCodePointFromStream: stream [

	| codePoint |

	codePoint := super nextCodePointFromStream: stream.
	codePoint <= self maximumUTFCode ifFalse: [ ^ self errorOutsideRange ].
	^ codePoint

]
