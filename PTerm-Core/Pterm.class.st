Class {
	#name : #Pterm,
	#superclass : #Object,
	#instVars : [
		'master',
		'slave'
	],
	#category : #'PTerm-Core'
}

{ #category : #'instance creation' }
Pterm >> spawn [
	|buff argv xarray fd fname fileaction pid|
	"allocate the file action structure (void* for now)"
	buff := FFIUInt32  newBuffer.
	argv := {'ls'. '-al'}.
	xarray := self stringArrayOf: argv.
	"fd := self master.
	fname := self ptsname: fd."
	fname := '/home/mrsang/log.txt'.
	fileaction  := self fileActionSettingFor:fname.
	self posixSpawn: buff process: '/bin/ls' fileAction: fileaction fileAttr: nil  argv: xarray getHandle  env: nil.
	pid := buff integerAt: 1 size: 4 signed:true.
	self waitpit: pid status: buff noHang: 0. 
	fileaction free.
	Transcript show: 'Finish'.
]
