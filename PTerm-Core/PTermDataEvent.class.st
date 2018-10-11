Class {
	#name : #PTermDataEvent,
	#superclass : #Announcement,
	#instVars : [
		'data'
	],
	#category : #'PTerm-Core'
}

{ #category : #accessing }
PTermDataEvent class >> data: d [
	^self new data:d; yourself
]

{ #category : #accessing }
PTermDataEvent >> data [
	^ data
]

{ #category : #accessing }
PTermDataEvent >> data: anObject [
	data := anObject
]
