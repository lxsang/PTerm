Class {
	#name : #XTermTheme,
	#superclass : #TerminalEmulatorColorPalette,
	#category : #'PTerm-UI'
}

{ #category : #theming }
XTermTheme class >> rgbTriplets [

	^ #(
		"Foreground:"
			#(16r000000 16rCD0000 16r00CD00 16rCDCD00 16r0000EE 16rCD00CD 16r00CDCD 16rE5E5E5)
		"Background:"
			#(16r000000 16rCD0000 16r00CD00 16rCDCD00 16r0000EE 16rCD00CD 16r00CDCD 16rE5E5E5 16rFFFFFF))

]
