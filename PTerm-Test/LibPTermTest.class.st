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
LibPTermTest >> testFileActionAddDup [
	|lib pointer st|
	lib := LibPTerm singleton.
	pointer := ExternalAddress allocate: lib class sizeOfFileAction.
	self assert: [ pointer ~= nil ].
	st := lib fileActionInit: pointer.
	self assert: [ st = 0 ].
	st := lib fileActionAddOpen: pointer fd: 1  fileName: '/tmp/test.txt'  flag: lib class O_RDWR   mode: 0644.
	self assert: [ st = 0 ].
	st := lib fileActionAddDup: pointer fd: 1  newFd: 2.
	self assert: [ st = 0 ]. 
	pointer free.
]

{ #category : #tests }
LibPTermTest >> testFileActionAddOpen [
	|lib pointer st|
	lib := LibPTerm singleton.
	pointer := ExternalAddress allocate: lib class sizeOfFileAction.
	self assert: [ pointer ~= nil ].
	st := lib fileActionInit: pointer.
	self assert: [ st = 0 ].
	st := lib fileActionAddOpen: pointer fd: 1  fileName: '/tmp/test.txt'  flag: lib class O_RDWR   mode: 0644.
	self assert: [ st = 0 ].
	pointer free.
]

{ #category : #tests }
LibPTermTest >> testFileActionInit [
	|lib pointer st|
	lib := LibPTerm singleton.
	pointer := ExternalAddress allocate: lib class sizeOfFileAction.
	st := lib fileActionInit: pointer.
	pointer free.
	self assert: [ st = 0 ].
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
