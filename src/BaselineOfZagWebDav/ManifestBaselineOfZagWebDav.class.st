"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : 'ManifestBaselineOfZagWebDav',
	#superclass : 'PackageManifest',
	#category : 'BaselineOfZagWebDav-Manifest',
	#package : 'BaselineOfZagWebDav',
	#tag : 'Manifest'
}

{ #category : 'code-critics' }
ManifestBaselineOfZagWebDav class >> ruleClassNotReferencedRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGClassDefinition #(#BaselineOfZagWebDav)) #'2026-07-31T10:58:21.577531-04:00') )
]
