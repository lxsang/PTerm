Class {
	#name : #PTerm,
	#superclass : #ProtocolEndpoint,
	#instVars : [
		'master',
		'pid',
		'announcer',
		'sub',
		'active',
		'wbuff'
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
		self nextPutAllCr: 'exit'.
		pid ifNotNil: [ 
			self lib kill: pid signal: self lib class SIGKILL.
		].
	]
]

{ #category : #accessing }
PTerm >> downcall: data [
	data > 255 ifTrue:[
		"may be unicode"
		data asCharacter asString utf8Encoded do:[:b| self nextPut: b].
		^self
	].
	^self nextPut: data
]

{ #category : #protocol }
PTerm >> initialize [ 
	announcer := Announcer new.
	active := false.
	wbuff := ExternalAddress allocate: 8
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
PTerm >> nextPut: anInt [
	self master ifNil:[^self].
	wbuff unsignedByteAt: 1 put: anInt.
	self lib write: self master buffer: wbuff  size: 1. 
]

{ #category : #'instance creation' }
PTerm >> nextPutAll: text [
	text do:[:c|
		self nextPut: c codePoint
	]
]

{ #category : #'instance creation' }
PTerm >> nextPutAllCr:text [
	self nextPutAll: text, Character cr asString
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
	sub := self announcer when: PTermDataEvent  do: [ :e|
		e data do:[:c|
			up upcall: c codePoint ]].

]

{ #category : #initialization }
PTerm >> setWinsize: point [
	|buf arr st|
	[self lib ttyWinSize: self master rows: point y  cols: point x] on: Error do: [
		buf := FFIExternalArray externalNewType: 'uint8' size: self lib class ST_WINSIZE.
		arr := point y asByteArrayOfSize: 2.
		buf at: 1 put: (arr at:2).
		buf at:2 put: (arr at: 1).
		arr := point x asByteArrayOfSize: 2.
		buf at: 3 put: (arr at: 2).
		buf at: 4 put: (arr at:1).
		buf at: 5 put: 0.
		buf at: 6 put: 0.
		buf at: 7 put: 0.
		buf at: 8 put:0.
		st := self lib ioct: self master cmd: self lib class TIOCSWINSZ  arg: buf getHandle.
		st = 0 ifFalse:[^self error: 'Cannot set window size to', point asString ]
	]
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
	| status  fname fileaction |
	"allocate the file action structure (void* for now)"
	status := FFIUInt32  newBuffer.
	master ifNil: [ master := self lib master ].
	"self lib setNonBlocking: master."
	fname := self lib ptsname: self master.
	fileaction  := self lib fileActionSettingFor:fname.
	self lib posixSpawn: status 
			process: cmd
			fileAction: fileaction
			fileAttr: nil
			argv: argv
			env: envs.
	pid := status integerAt: 1 size: 4 signed:true.
	fileaction free.
	Transcript show: 'Created non interractive shell';cr.
]

{ #category : #'instance creation' }
PTerm >> waitForOutput [
	|data buff count ws status stream|
	ws := 0.
	self master ifNil: [ ^self ].
	status := FFIUInt32  newBuffer.
	stream := WriteStream on: ByteArray new.
	buff := self lib getReadWriteBufferOf: 2048.
	[ 
		count := self lib read: self master buffer: buff  size: 2048.
		count > 0 ifTrue:[
			data :=  (FFIExternalArray fromHandle: buff type: 'uint8' size: count) asByteArray.
			stream nextPutAll: data.
			[
				data := stream contents decodeWith: #utf8.
				self announcer announce: (PTermDataEvent data: data ).
				stream reset.
			] on:Error do:[].
		].
		self pid ifNotNil: [ 
			ws := self lib waitpid: self pid status: status noHang: 1
		].
	ws = 0
	] whileTrue: [ count > 0 ifFalse:[ 100 milliSeconds wait ]].
	active := false.
	self lib closept: self master.
	self announcer unsubscribe: sub.
	master := nil.
	up note: #endpointClosed with: true.
	wbuff free.
	Transcript  show: 'Terminal closed'; cr.
]

{ #category : #'instance creation' }
PTerm >> xspawn: argv [
	^ self xspawn: argv env: nil 
]

{ #category : #'instance creation' }
PTerm >> xspawn: argv env:envs [
	| xarray  earray|
	xarray := self lib stringArrayOf: argv.
	earray  := self lib stringArrayOf: envs.
	xarray ifNotNil: [ xarray := xarray getHandle ].
	earray ifNotNil: [ earray := earray getHandle ] ifNil: [Smalltalk os environment environ getHandle].
	master := self lib master.
	[ self waitForOutput  ] forkAt: Processor userSchedulingPriority.
	"try to use the external lib if not sucess, fallback to the posix_spawn"
	[pid := self lib ttySpawn: master argv: xarray   envs: earray ] on: Error do:[
		self spawn: (argv first) args: xarray   env: earray 
	].
	active:= true.
	Transcript show: 'Command run on process: ', pid asString; cr.
]
