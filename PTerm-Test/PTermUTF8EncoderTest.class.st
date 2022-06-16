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

	"Some of the examples in this test are taken from section ‘3.9 Unicode Encoding Forms’ of ‘The Unicode Standard, Version 14.0 – Core Specification’. As is explained in the subsection ‘Constraints on Conversion Processes’, for one UTF-8 sequence, multiple different U+FFFD substitutions can be possible. For <F0 80 80 41>, <U+FFFD> is not possible, but <U+FFFD, U+0041> and <U+FFFD, U+FFFD, U+FFFD, U+0041> are both possible. The subsection ‘U+FFFD Substitution of Maximal Subparts’ describes the practice specified by a W3C standard, which is however not required by the Unicode Standard. The substitution of #decodeStreamUpToIncomplete: does not follow the W3C standard for tables 3-8 through 3-10, but does follow it for table 3-11."

	| replacement |

	replacement := Character codePoint: 16rFFFD.

	self assertDecodingOf: #[]
		equals: ''
		leavingNumberOfBytes: 0.
	self assertDecodingOf: #[16r41]
		equals: 'A'
		leavingNumberOfBytes: 0.
	self assertDecodingOf: #[16rC2 16rB1]
		equals: '±'
		leavingNumberOfBytes: 0.
	self assertDecodingOf: #[16rC2 16rB1 16rE2 16r81]
		equals: '±'
		leavingNumberOfBytes: 2.
	self assertDecodingOf: #[16rC2 16rB1 16rE2 16r81 16r89 16rF0 16r9F 16r8C]
		equals: '±⁉'
		leavingNumberOfBytes: 3.
	self assertDecodingOf: #[16rC2 16rB1 16rE2 16r81 16r89 16rF0 16r9F 16r8C 16r90]
		equals: '±⁉' , (String with: (Character codePoint: 16r1F310))
		leavingNumberOfBytes: 0.
	self assertDecodingOf: #[16rF4 16r90 16r80 16r80]
		equals: (String with: replacement)
		leavingNumberOfBytes: 0.
	self assertDecodingOf: #[16rC2]
		equals: ''
		leavingNumberOfBytes: 1.
	"Example on p. 125 of the Unicode v14.0 Core Specification:"
	self assertDecodingOf: #[16rC2 16r41 16r42]
		equals: (String with: replacement with: $A with: $B)
		leavingNumberOfBytes: 0.
	self assertDecodingOf: #[16rF0 16r80 16r80]
		equals: ''
		leavingNumberOfBytes: 3.
	"Example on p. 126 of the Unicode v14.0 Core Specification:"
	self assertDecodingOf: #[16rF0 16r80 16r80 16r41]
		equals: (String with: replacement with: $A)
		leavingNumberOfBytes: 0.
	self assertDecodingOf: #[16r61 16rF1 16r80 16r80 16rE1 16r80]
		equals:
			(String with: $a with: replacement)
		leavingNumberOfBytes: 2.
	"Example on p. 129 of the Unicode v10.0 Core Specification (earlier version of the standard; result is the recommended one):"
	self assertDecodingOf: #[16r61 16rF1 16r80 16r80 16rE1 16r80 16rC2 16r62 16r80 16r63 16r80 16rBF 16r64]
		equals:
			(String with: $a with: replacement with: replacement with: replacement) ,
			(String with: $b with: replacement) ,
			(String with: $c with: replacement with: replacement with: $d)
		leavingNumberOfBytes: 0.

	"Example in table 3-8 of the Unicode v14.0 Core Specification (result differs):"
	self assertDecodingOf: #[16rC0 16rAF 16rE0 16r80 16rBF 16rF0 16r81 16r82 16r41]
		equals: (String with: replacement with: replacement with: replacement with: $A)
		leavingNumberOfBytes: 0.
	"Example in table 3-9 of the Unicode v14.0 Core Specification (result differs):"
	self assertDecodingOf: #[16rED 16rA0 16r80 16rED 16rBF 16rBF 16rED 16rAF 16r41]
		equals: (String with: replacement with: replacement with: replacement with: $A)
		leavingNumberOfBytes: 0.
	"Example in table 3-10 of the Unicode v14.0 Core Specification (result differs):"
	self assertDecodingOf: #[16rF4 16r91 16r92 16r93 16rFF 16r41 16r80 16rBF 16r42]
		equals:
			(String with: replacement with: replacement with: $A) ,
			(String with: replacement with: replacement with: $B)
		leavingNumberOfBytes: 0.
	"Example in table 3-11 of the Unicode v14.0 Core Specification (same result):"
	self assertDecodingOf: #[16rE1 16r80 16rE2 16rF0 16r91 16r92 16rF1 16rBF 16r41]
		equals: (String with: replacement with: replacement with: replacement with: replacement with: $A)
		leavingNumberOfBytes: 0.

]
