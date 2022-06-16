Class {
	#name : #PTInvalidUTF8,
	#superclass : #ZnInvalidUTF8,
	#category : #'PTerm-Core'
}

{ #category : #testing }
PTInvalidUTF8 >> defaultResumeValue [
	^ 16rFFFD
]

{ #category : #testing }
PTInvalidUTF8 >> isResumable [
	^true
]
