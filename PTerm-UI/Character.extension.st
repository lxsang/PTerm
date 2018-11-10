Extension { #name : #Character }

{ #category : #'*PTerm-UI' }
Character class >> combiningInterval [
	^#(
	 #( 16r0300 16r036F ) #( 16r0483 16r0486 ) #( 16r0488 16r0489 )
    #( 16r0591 16r05BD ) #( 16r05BF 16r05BF ) #( 16r05C1 16r05C2 )
    #( 16r05C4 16r05C5 ) #( 16r05C7 16r05C7 ) #( 16r0600 16r0603 )
    #( 16r0610 16r0615 ) #( 16r064B 16r065E ) #( 16r0670 16r0670 )
    #( 16r06D6 16r06E4 ) #( 16r06E7 16r06E8 ) #( 16r06EA 16r06ED )
    #( 16r070F 16r070F ) #( 16r0711 16r0711 ) #( 16r0730 16r074A )
    #( 16r07A6 16r07B0 ) #( 16r07EB 16r07F3 ) #( 16r0901 16r0902 )
    #( 16r093C 16r093C ) #( 16r0941 16r0948 ) #( 16r094D 16r094D )
    #( 16r0951 16r0954 ) #( 16r0962 16r0963 ) #( 16r0981 16r0981 )
    #( 16r09BC 16r09BC ) #( 16r09C1 16r09C4 ) #( 16r09CD 16r09CD )
    #( 16r09E2 16r09E3 ) #( 16r0A01 16r0A02 ) #( 16r0A3C 16r0A3C )
    #( 16r0A41 16r0A42 ) #( 16r0A47 16r0A48 ) #( 16r0A4B 16r0A4D )
    #( 16r0A70 16r0A71 ) #( 16r0A81 16r0A82 ) #( 16r0ABC 16r0ABC )
    #( 16r0AC1 16r0AC5 ) #( 16r0AC7 16r0AC8 ) #( 16r0ACD 16r0ACD )
    #( 16r0AE2 16r0AE3 ) #( 16r0B01 16r0B01 ) #( 16r0B3C 16r0B3C )
    #( 16r0B3F 16r0B3F ) #( 16r0B41 16r0B43 ) #( 16r0B4D 16r0B4D )
    #( 16r0B56 16r0B56 ) #( 16r0B82 16r0B82 ) #( 16r0BC0 16r0BC0 )
    #( 16r0BCD 16r0BCD ) #( 16r0C3E 16r0C40 ) #( 16r0C46 16r0C48 )
    #( 16r0C4A 16r0C4D ) #( 16r0C55 16r0C56 ) #( 16r0CBC 16r0CBC )
    #( 16r0CBF 16r0CBF ) #( 16r0CC6 16r0CC6 ) #( 16r0CCC 16r0CCD )
    #( 16r0CE2 16r0CE3 ) #( 16r0D41 16r0D43 ) #( 16r0D4D 16r0D4D )
    #( 16r0DCA 16r0DCA ) #( 16r0DD2 16r0DD4 ) #( 16r0DD6 16r0DD6 )
    #( 16r0E31 16r0E31 ) #( 16r0E34 16r0E3A ) #( 16r0E47 16r0E4E )
    #( 16r0EB1 16r0EB1 ) #( 16r0EB4 16r0EB9 ) #( 16r0EBB 16r0EBC )
    #( 16r0EC8 16r0ECD ) #( 16r0F18 16r0F19 ) #( 16r0F35 16r0F35 )
    #( 16r0F37 16r0F37 ) #( 16r0F39 16r0F39 ) #( 16r0F71 16r0F7E )
    #( 16r0F80 16r0F84 ) #( 16r0F86 16r0F87 ) #( 16r0F90 16r0F97 )
    #( 16r0F99 16r0FBC ) #( 16r0FC6 16r0FC6 ) #( 16r102D 16r1030 )
    #( 16r1032 16r1032 ) #( 16r1036 16r1037 ) #( 16r1039 16r1039 )
    #( 16r1058 16r1059 ) #( 16r1160 16r11FF ) #( 16r135F 16r135F )
    #( 16r1712 16r1714 ) #( 16r1732 16r1734 ) #( 16r1752 16r1753 )
    #( 16r1772 16r1773 ) #( 16r17B4 16r17B5 ) #( 16r17B7 16r17BD )
    #( 16r17C6 16r17C6 ) #( 16r17C9 16r17D3 ) #( 16r17DD 16r17DD )
    #( 16r180B 16r180D ) #( 16r18A9 16r18A9 ) #( 16r1920 16r1922 )
    #( 16r1927 16r1928 ) #( 16r1932 16r1932 ) #( 16r1939 16r193B )
    #( 16r1A17 16r1A18 ) #( 16r1B00 16r1B03 ) #( 16r1B34 16r1B34 )
    #( 16r1B36 16r1B3A ) #( 16r1B3C 16r1B3C ) #( 16r1B42 16r1B42 )
    #( 16r1B6B 16r1B73 ) #( 16r1DC0 16r1DCA ) #( 16r1DFE 16r1DFF )
    #( 16r200B 16r200F ) #( 16r202A 16r202E ) #( 16r2060 16r2063 )
    #( 16r206A 16r206F ) #( 16r20D0 16r20EF ) #( 16r302A 16r302F )
    #( 16r3099 16r309A ) #( 16rA806 16rA806 ) #( 16rA80B 16rA80B )
    #( 16rA825 16rA826 ) #( 16rFB1E 16rFB1E ) #( 16rFE00 16rFE0F )
    #( 16rFE20 16rFE23 ) #( 16rFEFF 16rFEFF ) #( 16rFFF9 16rFFFB )
    #( 16r10A01 16r10A03 ) #( 16r10A05 16r10A06 ) #( 16r10A0C 16r10A0F )
    #( 16r10A38 16r10A3A ) #( 16r10A3F 16r10A3F ) #( 16r1D167 16r1D169 )
    #( 16r1D173 16r1D182 ) #( 16r1D185 16r1D18B ) #( 16r1D1AA 16r1D1AD )
    #( 16r1D242 16r1D244 ) #( 16rE0001 16rE0001 ) #( 16rE0020 16rE007F )
    #( 16rE0100 16rE01EF ))
]

{ #category : #'*PTerm-UI' }
Character >> isCombining [
	|min mid table code max|
	code := self codePoint.
	table := Character combiningInterval.
	max := table size.
	min := 1.
	mid := 1.
	((code < table first first) & (code > table last last)) ifTrue:[^false].
	[ max >= min ] whileTrue: [
		mid := ((min + max) / 2) asInteger.
		code > (table at:mid) last ifTrue:[
			min := mid + 1
		] ifFalse:[
			code < (table at:mid) first ifTrue:[max := mid - 1] ifFalse:[^true]
		]
	].
	^false
]

{ #category : #'*PTerm-UI' }
Character >> isFullWidth [
	"base on this code:
	https://www.cl.cam.ac.uk/~mgk25/ucs/wcwidth.c"
	|code|
	code := self codePoint.
	code < 256 ifTrue:[^false].
	self isCombining ifTrue: [ ^false ].
	^((code >= 16r1100) &
     ((code <= 16r115f) |                  
      (code = 16r2329) | (code = 16r232a) |
      ((code >= 16r2e80 )& (code <= 16ra4cf) &
       (code ~= 16r303f)) |                  
      ((code >= 16rac00) & (code <= 16rd7a3)) | 
      ((code >= 16rf900) & (code <= 16rfaff)) | 
      ((code >= 16rfe10) & (code <= 16rfe19)) | 
      ((code >= 16rfe30) & (code <= 16rfe6f)) | 
      ((code >= 16rff00) & (code <= 16rff60)) |
      ((code >= 16rffe0) & (code <= 16rffe6)) |
      ((code >= 16r20000) & (code <= 16r2fffd)) |
      ((code >= 16r30000) & (code <= 16r3fffd))))
]
