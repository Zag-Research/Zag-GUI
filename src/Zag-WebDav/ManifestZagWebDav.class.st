"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : 'ManifestZagWebDav',
	#superclass : 'PackageManifest',
	#category : 'Zag-WebDav-Manifest',
	#package : 'Zag-WebDav',
	#tag : 'Manifest'
}

{ #category : 'code-critics' }
ManifestZagWebDav class >> ruleClassNotReferencedRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGClassDefinition #(#ZagWebDav)) #'2026-07-30T20:28:09.737135-04:00') )
]

{ #category : 'code-critics' }
ManifestZagWebDav class >> ruleLongMethodsRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#ZagWebDav #makeXmlNodeFor:method: #false)) #'2026-07-30T14:27:33.334978-04:00') #(#(#RGMethodDefinition #(#ZagWebDav #resourceExists: #false)) #'2026-07-30T14:49:00.17812-04:00') #(#(#RGMethodDefinition #(#ZagWebDav #handlePropfind: #false)) #'2026-07-30T14:49:38.321138-04:00') #(#(#RGMethodDefinition #(#ZagWebDav #propfindPackageTree:depth: #false)) #'2026-07-30T20:27:21.256591-04:00') )
]

{ #category : 'code-critics' }
ManifestZagWebDav class >> ruleReCyclomaticComplexityRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#ZagWebDav #makeXmlNodeFor:method: #false)) #'2026-07-30T13:37:03.566438-04:00') )
]

{ #category : 'code-critics' }
ManifestZagWebDav class >> ruleStringConcatenationRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#ZagWebDav #handlePropfind: #false)) #'2026-07-30T13:06:26.996959-04:00') #(#(#RGMethodDefinition #(#ZagWebDav #propfindClassTree:depth: #false)) #'2026-07-30T13:48:35.094816-04:00') #(#(#RGMethodDefinition #(#ZagWebDav #propfindPackageTree:depth: #false)) #'2026-07-30T13:51:38.557496-04:00') )
]

{ #category : 'code-critics' }
ManifestZagWebDav class >> ruleTempsReadBeforeWrittenRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#'ZagWebDav class' #start #true)) #'2026-07-30T10:06:49.60351-04:00') )
]

{ #category : 'code-critics' }
ManifestZagWebDav class >> ruleUnaryAccessingMethodWithoutReturnRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGMethodDefinition #(#'ZagWebDav class' #start #true)) #'2026-07-30T10:06:43.39586-04:00') #(#(#RGMethodDefinition #(#'ZagWebDav class' #stop #true)) #'2026-07-30T20:25:52.099036-04:00') )
]
