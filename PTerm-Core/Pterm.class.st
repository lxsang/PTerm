Class {
	#name : #PTerm,
	#superclass : #Object,
	#instVars : [
		'master',
		'pid'
	],
	#category : #'PTerm-Core'
}

{ #category : #'instance creation' }
PTerm >> lib [ 
	^ LibPTerm singleton 
]

{ #category : #accessing }
PTerm >> master [
	^ master
]

{ #category : #accessing }
PTerm >> master: anObject [
	master := anObject
]

{ #category : #'instance creation' }
PTerm >> nextPut: text [
	|buff|
	self master ifNil:[^self].
	buff := ExternalAddress fromString: text.
	self lib write: self master buffer: buff  size: text size. 
]

{ #category : #'instance creation' }
PTerm >> nextPutCr:text [
	self nextPut: text, Character cr asString
]

{ #category : #accessing }
PTerm >> pid [
	^ pid
]

{ #category : #'instance creation' }
PTerm >> spawn [
	|buff status argv xarray fname fileaction pid count data|
	"allocate the file action structure (void* for now)"
	status := FFIUInt32  newBuffer.
	argv := {'ls'. '-al'}.
	xarray := self lib stringArrayOf: argv.
	master := self lib master.
	fname := self lib ptsname: self master.
	fileaction  := self lib fileActionSettingFor:fname.
	self lib posixSpawn: status process: '/bin/ls' fileAction: fileaction fileAttr: nil  argv: xarray getHandle  env: nil.
	pid := status integerAt: 1 size: 4 signed:true.
	"read the stdout then print"
	buff := self lib getReadWriteBufferOf: 2048.
	count := self lib read: self master buffer: buff  size: 2048.
	Transcript show: 'Read ', count asString, 'bytes'; cr.
	data :=  String
	newFrom: (FFIExternalArray fromHandle: buff type: 'char' size: count).
	Transcript show: data;cr.
	self lib kill: pid signal: self lib class SIGKILL.
	self lib waitpit: pid status: status noHang: 0. 
	fileaction free.
	Transcript show: 'Finish'.
]

{ #category : #'instance creation' }
PTerm >> spawn: cmd args: argv [
	| status xarray fname fileaction |
	"allocate the file action structure (void* for now)"
	status := FFIUInt32  newBuffer.
	xarray := self lib stringArrayOf: argv.
	master := self lib master.
	"self lib setNonBlocking: master."
	fname := self lib ptsname: self master.
	fileaction  := self lib fileActionSettingFor:fname.
	[ self waitForOutput  ] fork.
	self lib posixSpawn: status 
			process: cmd
			fileAction: fileaction
			fileAttr: nil
			argv: xarray getHandle
			env: nil.
	pid := status integerAt: 1 size: 4 signed:true.
	"self lib kill: pid signal: self lib class SIGKILL."
	"self lib waitpit: pid status: status noHang: 0."
	fileaction free.
	Transcript show: 'Finish'.
]

{ #category : #'instance creation' }
PTerm >> waitForOutput [
	|data buff count ws status|
	ws := 0.
	self master ifNil: [ ^self ].
	status := FFIUInt32  newBuffer.
	buff := self lib getReadWriteBufferOf: 2048.
	[ 
		count := self lib read: self master buffer: buff  size: 2048.
		count > 0 ifTrue:[
			data :=  String
			newFrom: (FFIExternalArray fromHandle: buff type: 'char' size: count).
			Transcript show: data;cr.
		].
		self pid ifNotNil: [ 
			ws := self lib waitpid: self pid status: status noHang: 1
		].
	ws = 0
	] whileTrue: [ count > 0 ifFalse:[200 milliSeconds wait ]].
	Transcript  show: 'Finish read'.
]
