"
A ZagWebDavTest is a test class for testing the behavior of ZagWebDav
"
Class {
	#name : 'ZagWebDavTest',
	#superclass : 'TestCase',
	#instVars : [
		'webDav'
	],
	#category : 'Zag-WebDav-Tests-Core',
	#package : 'Zag-WebDav-Tests',
	#tag : 'Core'
}

{ #category : 'running' }
ZagWebDavTest >> setUp [
	super setUp.

	webDav := ZagWebDav new
]

{ #category : 'tests' }
ZagWebDavTest >> testExtractClassAndSelectorFrom [

	self assert: (webDav extractClassAndSelectorFrom: #( class ZagWebDav )) equals: nil.
	self assert: (webDav extractClassAndSelectorFrom: #( class ZagWebDav foo )) equals: nil.
	self assert: (webDav extractClassAndSelectorFrom: #( class ZagWebDav foo bar )) equals: nil.
	self assert: (webDav extractClassAndSelectorFrom: #( class ZagWebDav class_methods )) equals: nil.
	self assert: (webDav extractClassAndSelectorFrom: #( class ZagWebDav class_methods foo bar )) equals: nil.
	self assert: (webDav extractClassAndSelectorFrom: #( class ZagWebDav 'Comment.md' )) equals: {
			ZagWebDav.
			1 }.
	self assert: (webDav extractClassAndSelectorFrom: #( class ZagWebDav class_methods foobar )) equals: {
			ZagWebDav class.
			#foobar }.
	self assert: (webDav extractClassAndSelectorFrom: #( class ZagWebDav instance_methods foobar )) equals: {
			ZagWebDav.
			#foobar }
]

{ #category : 'tests' }
ZagWebDavTest >> testResourceExists [

	self deny: (webDav resourceExists: #( class ZagWebDav systemPackages )).
	self assert: (webDav resourceExists: #( class ZagWebDav 'Comment.md' )).
	self deny: (webDav resourceExists: #( class ManifestZagWebDav 'Comment.md' )).
	self deny: (webDav resourceExists: #( class ZagWebDav class_methods foobar )).
	self assert: (webDav resourceExists: #( class ZagWebDav class_methods start )).
	self deny: (webDav resourceExists: #( class ZagWebDav instance_methods foobar )).
	self assert: (webDav resourceExists: #( class ZagWebDav instance_methods systemPackages ))
]
