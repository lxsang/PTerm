Class {
	#name : #XTermTheme,
	#superclass : #TerminalEmulatorColorPalette,
	#category : #'PTerm-UI'
}

{ #category : #theming }
XTermTheme class >> rgbTriplets [
	^ {
		"foreground"
		#( 16r000000  16rCC0000 16r00CD00 16rCDCD00 16r1E90FF 16rCD00CD 16r00CDCD 16rE5E5E5).
		"background"
		#( 16r4C4C4C  16rFF0000 16r00FF00 16rFFFF00 16r4682B4 16rFF00FF 16r00FFFF 16rFFFFFF).
		
	}
]
