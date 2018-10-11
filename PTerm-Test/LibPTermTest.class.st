Class {
	#name : #LibPTermTest,
	#superclass : #ClassTestCase,
	#category : #'PTerm-Test'
}

{ #category : #coverage }
LibPTermTest >> classToBeTested [
	
	^ LibPTerm 
]

{ #category : #tests }
LibPTermTest >> testGrant [
	|lib fd st|
	lib := LibPTerm singleton.
	fd := lib openpt: 2.
	self assert: [ fd >= 0 ].
	st := lib grantpt: fd.
	self assert: [ st = 0 ].
	lib closept: fd
]

{ #category : #tests }
LibPTermTest >> testNew [
	^ true
]

{ #category : #tests }
LibPTermTest >> testOpenpt [
	|fd|
	fd := LibPTerm singleton openpt: 2. 
	self assert: [ fd >= 0 ].
	LibPTerm singleton closept: fd
]

{ #category : #tests }
LibPTermTest >> testSlave [
	|lib fdm fds|
	lib := LibPTerm singleton.
	fdm := lib master.
	fds := lib slave:fdm.
	lib closept:fdm.
	self assert: [ fds >= 0 ].
	lib closept: fds.
]

{ #category : #tests }
LibPTermTest >> testUnlock [
	|lib fd st|
	lib := LibPTerm singleton.
	fd := lib openpt: LibPTerm O_RDWR.
	self assert: [ fd >= 0 ].
	st := lib grantpt: fd.
	self assert: [ st = 0 ].
	st := lib unlockpt: fd.
	lib closept: fd
]
