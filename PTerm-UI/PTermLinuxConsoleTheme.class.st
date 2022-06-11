Class {
	#name : #PTermLinuxConsoleTheme,
	#superclass : #TerminalEmulatorColorPalette,
	#category : #'PTerm-UI'
}

{ #category : #theming }
PTermLinuxConsoleTheme class >> rgbTriplets [
	^ {
		"foreground"
		#( 16r000000  16rAA0000 16r00AA00 16rAA5500 16r5555FF 16rAA00AA 16r00AAAA 16rFFFFFF).
		"background"
		#( 16r000000  16rAA0000 16r00AA00 16rAA5500 16r5555FF 16rAA00AA 16r00AAAA 16rFFFFFF 16rFFFFFF).
		"#( 16r000000  16rFF5555 16r00AA00 16rFFFF55 16r5555FF 16rFF55FF 16r00AAAA 16rFFFFFF )."
	}
]
