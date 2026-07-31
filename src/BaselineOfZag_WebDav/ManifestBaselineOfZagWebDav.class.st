"
Please describe the package using the class comment of the included manifest class. The manifest class also includes other additional metadata for the package. These meta data are used by other tools such as the SmalllintManifestChecker and the critics Browser
"
Class {
	#name : 'ManifestBaselineOfZagWebDav',
	#superclass : 'PackageManifest',
	#category : 'BaselineOfZag_WebDav-Manifest',
	#package : 'BaselineOfZag_WebDav',
	#tag : 'Manifest'
}

{ #category : 'code-critics' }
ManifestBaselineOfZagWebDav class >> ruleClassNotReferencedRuleV1FalsePositive [

	<ignoreForCoverage>
	^ #(#(#(#RGClassDefinition #(#BaselineOfZag_WebDav)) #'2026-07-31T09:43:56.151322-04:00') )
]
