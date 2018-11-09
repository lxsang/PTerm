Class {
	#name : #PTermLinuxConsoleTheme,
	#superclass : #TerminalEmulatorColorPalette,
	#category : #'PTerm-UI'
}

{ #category : #theming }
PTermLinuxConsoleTheme class >> rgbTriplets [
	^ {
		"foreground"
		"background"
		#( 16r000000  16rAA0000 16r00AA00 16rAA5500 16r0000AA 16rAA00AA 16r00AAAA 16rAAAAAA).
		#( 16r555555  16rFF5555 16r55FF55 16rFFFF55 16r85555FF 16rFF55FF 16r55FFFF 16rFFFFFF ).
	}
]
