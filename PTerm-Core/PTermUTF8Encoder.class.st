Class {
	#name : #PTermUTF8Encoder,
	#superclass : #ZnUTF8Encoder,
	#category : #'PTerm-Core'
}

{ #category : #converting }
PTermUTF8Encoder >> nextCodePointFromStream: stream [
	[ 
		^super nextCodePointFromStream: stream 
	] on: Error do:[^65533]
]
