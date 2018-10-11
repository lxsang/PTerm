Class {
	#name : #LibPTerm,
	#superclass : #Object,
	#classInstVars : [
		'instance'
	],
	#category : #'PTerm-Core'
}

{ #category : #'as yet unclassified' }
LibPTerm class >> O_RDWR [
	^2
]

{ #category : #'instance creation' }
LibPTerm class >> new [
	self error: 'Please use #singleton'
]

{ #category : #'instance creation' }
LibPTerm class >> singleton [ 
	^ instance ifNil: [ instance := super new ]
]

{ #category : #'as yet unclassified' }
LibPTerm >> closept: fd [
	^ self ffiCall: #(int close(int fd)) module: LibC
]

{ #category : #'as yet unclassified' }
LibPTerm >> grantpt: fd [
	^ self ffiCall: #(int grantpt(int fd)) module: LibC
]

{ #category : #'as yet unclassified' }
LibPTerm >> master [
	|fd st|
	fd := self openpt: self class O_RDWR.
	fd < 0 ifTrue:[^self error:'Error on on posix_openpt()'].
	st := self grantpt: fd.
	st ~= 0 ifTrue: [ self closept: fd. ^ self error: 'Error on grantpt()' ].
	st := self unlockpt: fd.
	st ~= 0 ifTrue: [ self closept: fd. ^ self error: 'Error on unlockpt()' ].
	^fd
	
]

{ #category : #'as yet unclassified' }
LibPTerm >> open: name mode: flag [
	^ self ffiCall: #(int open(char* name, int flag)) module: LibC
]

{ #category : #'as yet unclassified' }
LibPTerm >> openpt: flag [
	^ self ffiCall: #(int posix_openpt(int flag)) module: LibC
]

{ #category : #'as yet unclassified' }
LibPTerm >> print: text [
	^ self ffiCall: #(void printf(char* text)) module: LibC
]

{ #category : #'as yet unclassified' }
LibPTerm >> ptsname: fd [
	^ self ffiCall: #(char* ptsname(int fd)) module: LibC
]

{ #category : #'as yet unclassified' }
LibPTerm >> slave: fd [
	|name|
	name := self ptsname: fd.
	^self open: name mode: self class O_RDWR  
]

{ #category : #'as yet unclassified' }
LibPTerm >> unlockpt: fd [
	^ self ffiCall: #(int unlockpt(int fd)) module: LibC
]
