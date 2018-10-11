"
I store metadata for this package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : #ManifestPTermCore,
	#superclass : #PackageManifest,
	#category : #'PTerm-Core-Manifest'
}

{ #category : #'code-critics' }
ManifestPTermCore class >> ruleRBLiteralArrayContainsCommaRuleV1FalsePositive [
	^ #(#(#(#RGPackage #(#'PTerm-Core')) #'2018-10-11T14:59:07.02625+02:00') )
]

{ #category : #'code-critics' }
ManifestPTermCore class >> ruleRBUncommonMessageSendRuleV1FalsePositive [
	^ #(#(#(#RGMethodDefinition #(#LibPTerm #master #false)) #'2018-10-11T11:39:34.584794+02:00') )
]
