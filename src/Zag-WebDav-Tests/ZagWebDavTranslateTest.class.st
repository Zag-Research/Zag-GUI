"
A ZagWebDavTranslateTest is a test class for testing the behavior of ZagWebDavTranslate
"
Class {
	#name : 'ZagWebDavTranslateTest',
	#superclass : 'TestCase',
	#category : 'Zag-WebDav-Tests-Utility',
	#package : 'Zag-WebDav-Tests',
	#tag : 'Utility'
}

{ #category : 'tests' }
ZagWebDavTranslateTest >> testToFilename [

	self assert: (ZagWebDavTranslate toFilename: #abcd) equals: 'abcd'.
	self assert: (ZagWebDavTranslate toFilename: #abc:d:) equals: 'abc꞉d꞉'.
	self assert: (ZagWebDavTranslate toFilename: #+) equals: '+'.
	self assert: (ZagWebDavTranslate toFilename: #+*) equals: '+∗'
]

{ #category : 'tests' }
ZagWebDavTranslateTest >> testToSelector [

	self assert: (ZagWebDavTranslate toSelector: 'abcd') equals: #abcd.
	self assert: (ZagWebDavTranslate toSelector: 'abc꞉d꞉') equals: #abc:d:.
	self assert: (ZagWebDavTranslate toSelector: '+') equals: #+.
	self assert: (ZagWebDavTranslate toSelector: '+∗') equals: #+*
	
]
