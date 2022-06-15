Class {
	#name : #PTermUTF8Encoder,
	#superclass : #ZnUTF8Encoder,
	#category : #'PTerm-Core'
}

{ #category : #convenience }
PTermUTF8Encoder >> decodeStreamUpToIncomplete: byteStream [

	^ self decodeStreamUpToIncomplete: byteStream replacementCharacter: (Character codePoint: 16rFFFD)

]

{ #category : #convenience }
PTermUTF8Encoder >> decodeStreamUpToIncomplete: byteStream replacementCharacter: replacementCharacter [

	^ String streamContents: [ :characterStream |
		| position |
		[
			[ byteStream atEnd ] whileFalse: [
				| character |
				position := byteStream position.
				character := [ [ self nextFromStream: byteStream ]
					on: PTInvalidUTF8IllegalLeadingByte , PTInvalidUTF8Overlong , PTInvalidUTF8OutsideRange do: [
						replacementCharacter ] ]
					on: PTInvalidUTF8IllegalContinuationByte do: [
						byteStream back.
						replacementCharacter ].
				characterStream nextPut: character ]
		] on: ZnIncomplete do: [
			byteStream position: position ] ]

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
PTermUTF8Encoder >> errorOutsideRange [

	^ PTInvalidUTF8OutsideRange signal

]

{ #category : #'error handling' }
PTermUTF8Encoder >> errorOverlong [

	^ PTInvalidUTF8Overlong signal

]
