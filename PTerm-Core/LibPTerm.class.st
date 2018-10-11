Class {
	#name : #LibPTerm,
	#superclass : #Object,
	#classInstVars : [
		'instance'
	],
	#category : #'PTerm-Core'
}

{ #category : #'as yet unclassified' }
LibPTerm class >> F_GETFL [
	^3
]

{ #category : #'as yet unclassified' }
LibPTerm class >> F_SETFL [
	^4
]

{ #category : #'as yet unclassified' }
LibPTerm class >> O_NONBLOCK [
	Smalltalk os isMacOS ifTrue: [ ^4 ].
	^4000
]

{ #category : #'as yet unclassified' }
LibPTerm class >> O_RDWR [
	^2
]

{ #category : #'as yet unclassified' }
LibPTerm class >> SIGKILL [
	^ 9
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
LibPTerm class >> sizeOfFileAction [
	"we fix it to 80 for now"
	^80
]

{ #category : #'as yet unclassified' }
LibPTerm >> closept: fd [
	^ self ffiCall: #(int close(int fd)) module: LibC
]

{ #category : #'instance creation' }
LibPTerm >> exec: command [
	^ LibC uniqueInstance system: command
]

{ #category : #'as yet unclassified' }
LibPTerm >> fileActionAddDup: pointer fd: fd newFd: fd2 [ 
	^self ffiCall: #(int posix_spawn_file_actions_adddup2( void* pointer, int fd, int fd2)) module: LibC.
]

{ #category : #'as yet unclassified' }
LibPTerm >> fileActionAddOpen: pointer fd: fd fileName: name flag: flag mode: mode [ 
	^self ffiCall: #(int posix_spawn_file_actions_addopen( void* pointer, int fd, char* name, int flag, int mode )) module: LibC.
]

{ #category : #'as yet unclassified' }
LibPTerm >> fileActionInit: pointer [
	^self ffiCall: #(int posix_spawn_file_actions_init( void* pointer )) module: LibC.
]

{ #category : #'as yet unclassified' }
LibPTerm >> fileActionSettingFor:name [
	|st ptr|
	ptr := ExternalAddress allocate: self class sizeOfFileAction.
	st := self fileActionInit: ptr.
	st = 0 ifFalse:[^ self error:'Error posix_spawn_file_actions_init'].
	st := self fileActionAddOpen: ptr fd: 0  fileName: name  flag: self class O_RDWR  mode: 0644. 
	st = 0 ifFalse: [ ^ self error:'Error posix_spawn_file_actions_open' ].
	"st := self fileActionAddDup: ptr fd: 0  newFd: 0.
	st = 0 ifFalse: [ ^self error: 'Error posix_spawn_file_action_dup2' ]."
	st := self fileActionAddDup: ptr fd: 0  newFd: 1.
	st = 0 ifFalse: [ ^self error: 'Error posix_spawn_file_action_dup2' ].
	st := self fileActionAddDup: ptr fd: 0  newFd: 2.
	st = 0 ifFalse: [ ^self error: 'Error posix_spawn_file_action_dup2' ].
	^ ptr
]

{ #category : #'as yet unclassified' }
LibPTerm >> fnctl: fd action: action flag: flag [
 	^ self ffiCall: #(int fcntl(int fd, int action, int flag)) module: LibC 
]

{ #category : #writing }
LibPTerm >> getReadWriteBufferOf: size [
	^(FFIExternalArray externalNewType: 'char' size: size) getHandle
]

{ #category : #'as yet unclassified' }
LibPTerm >> grantpt: fd [
	^ self ffiCall: #(int grantpt(int fd)) module: LibC
]

{ #category : #accessing }
LibPTerm >> kill: pid signal: sig [
	^ self ffiCall: #(int kill(int pid, int sig)) module: LibC
]

{ #category : #accessing }
LibPTerm >> master [
	|fd st|
	fd := self openpt: (self class O_RDWR bitOr: self class O_NONBLOCK).
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
LibPTerm >> posixSpawn:pid  process: cmd fileAction: ptr fileAttr:fattr argv: args env: envs [
	^ self ffiCall:#( int posix_spawnp(int* pid, char* cmd, void* ptr, void* fattr, void* args, void* envs ))  module: LibC 
]

{ #category : #printing }
LibPTerm >> print: text [
	^ self ffiCall: #(void printf(char* text)) module: LibC
]

{ #category : #'as yet unclassified' }
LibPTerm >> ptsname: fd [
	^ self ffiCall: #(char* ptsname(int fd)) module: LibC
]

{ #category : #'as yet unclassified' }
LibPTerm >> read: fd buffer: buff size: size [
	^self ffiCall: #(int read(int fd, char* buff, int size)) module: LibC 
]

{ #category : #'as yet unclassified' }
LibPTerm >> setNonBlocking: fd [
	|flag st|
	flag := self fnctl: fd action: self class F_GETFL flag:0.
	flag := flag bitOr: self class O_NONBLOCK.
	st := self fnctl: fd action: self class F_SETFL flag: flag.
	st = 0 ifFalse:[^self error: 'Cannot set nonblocking'].
	^st
]

{ #category : #'as yet unclassified' }
LibPTerm >> stringArrayOf: anArray [
	|xarray|
	anArray  ifNil: [ ^nil ].
	xarray := FFIExternalArray externalNewType: 'char*' size: anArray size + 1. 
	anArray withIndexDo: [ :v :i| xarray at:i put: (ExternalAddress fromString: v) ]. 
	xarray at:anArray size + 1 put: (ExternalAddress  fromAddress: 0).
	^ xarray 
]

{ #category : #'as yet unclassified' }
LibPTerm >> unlockpt: fd [
	^ self ffiCall: #(int unlockpt(int fd)) module: LibC
]

{ #category : #'as yet unclassified' }
LibPTerm >> waitpid: pid status: buf noHang: v [
	^ self ffiCall: #(int waitpid(int pid, int * buf, int v)) module: LibC
]

{ #category : #writing }
LibPTerm >> write: fd buffer: buff size: size [
	^self ffiCall: #(int write(int fd, char* buff, int size)) module: LibC 
]
