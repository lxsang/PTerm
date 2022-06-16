Class {
	#name : #PTermUTF8EncoderTest,
	#superclass : #TestCase,
	#category : #'PTerm-Test'
}

{ #category : #asserting }
PTermUTF8EncoderTest >> assertDecodingOf: byteArray equals: expectedString leavingNumberOfBytes: expectedBytesLeft [

	| stream actualString actualBytesLeft |
	
	stream := byteArray readStream.
	actualString := PTermUTF8Encoder new decodeStreamUpToIncomplete: stream.
	actualBytesLeft := byteArray size - stream position.
	self assert: actualString equals: expectedString.
	self assert: actualBytesLeft equals: expectedBytesLeft.

]

{ #category : #tests }
PTermUTF8EncoderTest >> testDecodeStreamUpToIncomplete [

	| replacement |

	replacement := Character codePoint: 16rFFFD.

	self assertDecodingOf: #[]
		equals: ''
		leavingNumberOfBytes: 0.
	self assertDecodingOf: #[16r41]
		equals: 'A'
		leavingNumberOfBytes: 0.
	self assertDecodingOf: #[16rC2]
		equals: ''
		leavingNumberOfBytes: 1.
	self assertDecodingOf: #[16rF4 16r90 16r80 16r80]
		equals: (String with: replacement)
		leavingNumberOfBytes: 0.
	self assertDecodingOf: #[16rC2 16r41 16r42]
		equals: (String with: replacement with: $A with: $B)
		leavingNumberOfBytes: 0.
	self assertDecodingOf: #[16rF0 16r80 16r80]
		equals: ''
		leavingNumberOfBytes: 3.
	self assertDecodingOf: #[16rF0 16r80 16r80 16r41]
		equals: (String with: replacement with: $A)
		leavingNumberOfBytes: 0.
	self assertDecodingOf: #[16r61 16rF1 16r80 16r80 16rE1 16r80]
		equals:
			(String with: $a with: replacement)
		leavingNumberOfBytes: 2.
	self assertDecodingOf: #[16r61 16rF1 16r80 16r80 16rE1 16r80 16rC2 16r62 16r80 16r63 16r80 16rBF 16r64]
		equals:
			(String with: $a with: replacement with: replacement with: replacement) ,
			(String with: $b with: replacement) ,
			(String with: $c with: replacement with: replacement with: $d)
		leavingNumberOfBytes: 0.

]
