Class {
	#name : #Pterm,
	#superclass : #Object,
	#instVars : [
		'master',
		'pid'
	],
	#category : #'PTerm-Core'
}

{ #category : #'instance creation' }
Pterm >> lib [ 
	^ LibPTerm singleton 
]

{ #category : #accessing }
Pterm >> master [
	^ master
]

{ #category : #accessing }
Pterm >> master: anObject [
	master := anObject
]

{ #category : #'instance creation' }
Pterm >> nextPut: text [
	|buff|
	self master ifNil:[^self].
	buff := ExternalAddress fromString: text.
	self lib write: self master buffer: buff  size: text size. 
]

{ #category : #'instance creation' }
Pterm >> nextPutCr:text [
	self nextPut: text, Character cr asString
]

{ #category : #accessing }
Pterm >> pid [
	^ pid
]

{ #category : #'instance creation' }
Pterm >> spawn [
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
Pterm >> spawn: cmd args: argv [
	| status xarray fname fileaction ret|
	"allocate the file action structure (void* for now)"
	status := FFIUInt32  newBuffer.
	xarray := self lib stringArrayOf: argv.
	master := self lib master.
	ret := self lib setNonBlocking: master.
	ret ~= 0 ifTrue:[^self error: 'cannot set nonblocking'].
	fname := self lib ptsname: self master.
	fileaction  := self lib fileActionSettingFor:fname.
	[ self waitForOutput  ] fork.
	self lib posixSpawn: status process: cmd fileAction: fileaction fileAttr: nil  argv: xarray getHandle  env: nil.
	pid := status integerAt: 1 size: 4 signed:true.
	"self lib kill: pid signal: self lib class SIGKILL."
	"self lib waitpit: pid status: status noHang: 0."
	fileaction free.
	Transcript show: 'Finish'.
]

{ #category : #'instance creation' }
Pterm >> waitForOutput [
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
