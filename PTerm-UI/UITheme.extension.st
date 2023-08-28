Extension { #name : #UITheme }

{ #category : #'*PTerm-UI' }
UITheme >> isDark [
	^false
]

{ #category : #'*PTerm-UI' }
UITheme >> isLight [
	^false
]

{ #category : #'*PTerm-UI' }
UITheme >> terminalEmulatorPalette [
	^PTermSolarizedTheme dark
]
