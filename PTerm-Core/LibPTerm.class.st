Class {
	#name : #LibPTerm,
	#superclass : #FFILibrary,
	#classInstVars : [
		'instance'
	],
	#category : #'PTerm-Core'
}

{ #category : #'C-constants' }
LibPTerm class >> F_GETFL [
	^3
]

{ #category : #'C-constants' }
LibPTerm class >> F_SETFL [
	^4
]

{ #category : #'C-constants' }
LibPTerm class >> O_NONBLOCK [
	Smalltalk os isMacOS ifTrue: [ ^4 ].
	^4000
]

{ #category : #'C-constants' }
LibPTerm class >> O_RDWR [
	^2
]

{ #category : #'C-constants' }
LibPTerm class >> POSIX_SPAWN_SETSID [
	Smalltalk os isLinux ifTrue:[ ^ 16r80 ].
	Smalltalk os isMacOS  ifTrue:[^ 16r400].
	self error: '(Yet) unsupported operating system'.

]

{ #category : #'C-constants' }
LibPTerm class >> SIGHUP [

	^ 1
]

{ #category : #'C-constants' }
LibPTerm class >> SIGKILL [
	^ 9
]

{ #category : #'C-constants' }
LibPTerm class >> ST_WINSIZE [
	^8
]

{ #category : #'C-constants' }
LibPTerm class >> TIOCGWINSZ [
	Smalltalk os isMacOS ifTrue: [ ^1074295912 ].
	Smalltalk os isLinux ifTrue: [ ^ 21523].
	self error: '(Yet) unsupported operating system'.
]

{ #category : #'C-constants' }
LibPTerm class >> TIOCSWINSZ [
	Smalltalk os isMacOS ifTrue: [ ^2148037735 ].
	Smalltalk os isLinux ifTrue: [ ^21524 ].
	self error: '(Yet) unsupported operating system'.
]

{ #category : #'instance creation' }
LibPTerm class >> new [
	self error: 'Please use #singleton'
]

{ #category : #'instance creation' }
LibPTerm class >> singleton [ 
	^ self uniqueInstance 
]

{ #category : #'C-constants' }
LibPTerm class >> sizeOfFileAction [
	"we fix it to 80 for now"
	^80
]

{ #category : #'C-constants' }
LibPTerm class >> sizeOfSpawnAttr [
	(Smalltalk os isLinux or: [Smalltalk os isMacOS])  ifTrue:[
		"FIXME: this number is emprical value I've got on 
		 my amd64 linux system. This demonstrates the fundamental
		problem of nearly all FFI implementations."
		^ 340
	].

	self error: '(Yet) unsupported operating system'



]

{ #category : #lib }
LibPTerm >> closept: fd [
	^ self ffiCall: #(int close(int fd)) module: LibC
]

{ #category : #'instance creation' }
LibPTerm >> exec: command [
	^ LibC uniqueInstance system: command
]

{ #category : #lib }
LibPTerm >> fileActionAddDup: pointer fd: fd newFd: fd2 [ 
	^self ffiCall: #(int posix_spawn_file_actions_adddup2( void* pointer, int fd, int fd2)) module: LibC.
]

{ #category : #lib }
LibPTerm >> fileActionAddOpen: pointer fd: fd fileName: name flag: flag mode: mode [ 
	^self ffiCall: #(int posix_spawn_file_actions_addopen( void* pointer, int fd, char* name, int flag, int mode )) module: LibC.
]

{ #category : #lib }
LibPTerm >> fileActionInit: pointer [
	^self ffiCall: #(int posix_spawn_file_actions_init( void* pointer )) module: LibC.
]

{ #category : #lib }
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

{ #category : #lib }
LibPTerm >> fnctl: fd action: action flag: flag [
 	^ self ffiCall: #(int fcntl(int fd, int action, int flag)) library: LibC fixedArgumentCount: 2
]

{ #category : #writing }
LibPTerm >> getReadWriteBufferOf: size [
	^(FFIExternalArray externalNewType: 'char' size: size) getHandle
]

{ #category : #lib }
LibPTerm >> grantpt: fd [
	^ self ffiCall: #(int grantpt(int fd)) module: LibC
]

{ #category : #lib }
LibPTerm >> ioct: fd cmd: cmd arg: arg [
	^ self ffiCall: #(int ioctl(int fd, ulong cmd, void* arg)) library: LibC fixedArgumentCount: 2
]

{ #category : #accessing }
LibPTerm >> kill: pid signal: sig [
	^ self ffiCall: #(int kill(int pid, int sig)) module: LibC
]

{ #category : #'accessing platform' }
LibPTerm >> macLibraryName [ 
	^ 'libtty.dylib'
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

{ #category : #lib }
LibPTerm >> open: name mode: flag [
	^ self ffiCall: #(int open(char* name, int flag)) library: LibC fixedArgumentCount: 2
]

{ #category : #lib }
LibPTerm >> openpt: flag [
	^ self ffiCall: #(int posix_openpt(int flag)) module: LibC
]

{ #category : #lib }
LibPTerm >> posixSpawn:pid  process: cmd fileAction: ptr fileAttr:fattr argv: args env: envs [
	^ self ffiCall:#( int posix_spawnp(int* pid, char* cmd, void* ptr, void* fattr, void* args, void* envs ))  module: LibC  
]

{ #category : #lib }
LibPTerm >> print: text [
	^ self ffiCall: #(void printf(char* text)) library: LibC fixedArgumentCount: 1
]

{ #category : #lib }
LibPTerm >> ptsname: fd [
	^ self ffiCall: #(char* ptsname(int fd)) module: LibC
]

{ #category : #lib }
LibPTerm >> read: fd buffer: buff size: size [
	^self ffiCall: #(int read(int fd, char* buff, int size)) module: LibC 
]

{ #category : #initialization }
LibPTerm >> setNonBlocking: fd [
	|flag st|
	flag := self fnctl: fd action: self class F_GETFL flag:0.
	flag := flag bitOr: self class O_NONBLOCK.
	st := self fnctl: fd action: self class F_SETFL flag: flag.
	st = 0 ifFalse:[^self error: 'Cannot set nonblocking'].
	^st
]

{ #category : #lib }
LibPTerm >> spawnAttrDestroy: pointer [
	^self ffiCall: #(int posix_spawnattr_destroy( void* pointer )) module: LibC.
]

{ #category : #lib }
LibPTerm >> spawnAttrInit: pointer [
	^self ffiCall: #(int posix_spawnattr_init( void* pointer )) module: LibC.
]

{ #category : #lib }
LibPTerm >> spawnAttrSetFlags: pointer flags: flags [
	^self ffiCall: #(int posix_spawnattr_setflags( void* pointer, uint16 flags )) module: LibC.
]

{ #category : #lib }
LibPTerm >> stringArrayOf: anArray [
	|xarray|
	anArray  ifNil: [ ^nil ].
	xarray := FFIExternalArray externalNewType: 'char*' size: anArray size + 1. 
	anArray withIndexDo: [ :v :i| xarray at:i put: (ExternalAddress fromString: v) ]. 
	xarray at:anArray size + 1 put: (ExternalAddress  fromAddress: 0).
	^ xarray 
]

{ #category : #lib }
LibPTerm >> ttySpawn: fdm path: path argv: argv envs: envp [

	^ self ffiCall: #(int tty_spawn(int fdm, const char* path, void* argv, void* envp))
]

{ #category : #'accessing platform' }
LibPTerm >> unixLibraryName [
	^ 'libtty.so'
]

{ #category : #lib }
LibPTerm >> unlockpt: fd [
	^ self ffiCall: #(int unlockpt(int fd)) module: LibC
]

{ #category : #lib }
LibPTerm >> waitpid: pid status: buf noHang: v [
	^ self ffiCall: #(int waitpid(int pid, int * buf, int v)) module: LibC
]

{ #category : #writing }
LibPTerm >> write: fd buffer: buff size: size [
	^self ffiCall: #(int write(int fd, char* buff, int size)) module: LibC 
]
