Class {
	#name : #PTerm,
	#superclass : #ProtocolEndpoint,
	#instVars : [
		'master',
		'pid',
		'announcer',
		'sub',
		'active'
	],
	#category : #'PTerm-Core'
}

{ #category : #accessing }
PTerm >> announcer [
	^ announcer
]

{ #category : #protocol }
PTerm >> close [
	self master ifNotNil: [
		self nextPutCr: 'exit'	
	]
]

{ #category : #accessing }
PTerm >> downcall: data [
	^self nextPut: data asCharacter asString
]

{ #category : #protocol }
PTerm >> initialize [ 
	announcer := Announcer new.
	active := false
]

{ #category : #protocol }
PTerm >> isConnected [ 
	^ active
]

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

{ #category : #protocol }
PTerm >> name [ 
	^'PTerm'
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

{ #category : #protocol }
PTerm >> note: name with: val [
	super note: name with: val.
	name = #windowSize ifTrue: [ self setWinsize: val ].
]

{ #category : #accessing }
PTerm >> pid [
	^ pid
]

{ #category : #protocol }
PTerm >> run [
	sub := self announcer when: PTermDataEvent  do: [ :e|up upcallAll: e data].

]

{ #category : #initialization }
PTerm >> setWinsize: point [
	|st|
	Transcript show: 'resize window to ', point asString; cr.
	 st := self lib ttyWinSize: self master rows: point y  cols: point x.
	st = 0 ifFalse: [ ^self error: 'Cannot set tty window size' ]
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
	^self spawn: cmd args: argv  env: nil 
]

{ #category : #'instance creation' }
PTerm >> spawn: cmd args: argv env:envs [
	| status xarray fname fileaction earray|
	"allocate the file action structure (void* for now)"
	status := FFIUInt32  newBuffer.
	xarray := self lib stringArrayOf: argv.
	earray  := self lib stringArrayOf: envs.
	master := self lib master.
	"self lib setNonBlocking: master."
	fname := self lib ptsname: self master.
	fileaction  := self lib fileActionSettingFor:fname.
	[ self waitForOutput  ] forkAt: Processor userSchedulingPriority.
	self lib posixSpawn: status 
			process: cmd
			fileAction: fileaction
			fileAttr: nil
			argv: xarray getHandle
			env: earray getHandle.
	pid := status integerAt: 1 size: 4 signed:true.
	"self lib kill: pid signal: self lib class SIGKILL."
	"self lib waitpit: pid status: status noHang: 0."
	fileaction free.
	active := true.
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
			data :=  String newFrom: (FFIExternalArray fromHandle: buff type: 'char' size: count).
			self announcer announce: (PTermDataEvent data: data asByteArray ).
		].
		self pid ifNotNil: [ 
			ws := self lib waitpid: self pid status: status noHang: 1
		].
	ws = 0
	] whileTrue: [ count > 0 ifFalse:[ 300 milliSeconds wait ]].
	active := false.
	self lib closept: self master.
	self announcer unsubscribe: sub.
	master := nil.
	up note: #endpointClosed with: true.
	Transcript  show: 'Terminal closed'.
]

{ #category : #'instance creation' }
PTerm >> xspawn: argv [
	^ self xspawn: argv env: nil 
]

{ #category : #'instance creation' }
PTerm >> xspawn: argv env:envs [
	| xarray  earray|
	"allocate the file action structure (void* for now)"
	xarray := self lib stringArrayOf: argv.
	earray  := self lib stringArrayOf: envs.
	xarray ifNotNil: [ xarray := xarray getHandle ].
	earray ifNotNil: [ earray := earray getHandle ] ifNil: [Smalltalk os environment environ getHandle].
	master := self lib master.
	[ self waitForOutput  ] forkAt: Processor userSchedulingPriority.
	pid := self lib ttySpawn: master argv: xarray   envs: earray .
	"self lib kill: pid signal: self lib class SIGKILL."
	"self lib waitpit: pid status: status noHang: 0."
	Transcript show: 'Finish: ', pid asString; cr.
]
