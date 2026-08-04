"
I am the configurator for Zag-WebDav
"
Class {
	#name : 'BaselineOfZagWebDav',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfZagWebDav-Base',
	#package : 'BaselineOfZagWebDav',
	#tag : 'Base'
}

{ #category : 'baselines' }
BaselineOfZagWebDav >> baseline: spec [

	<baseline>
	spec for: #common do: [
			self defineDependencies: spec.
			self definePackages: spec.
			self defineGroups: spec ]
]

{ #category : 'private - definitions' }
BaselineOfZagWebDav >> defineDependencies: spec [
	"Only declare Zinc as a dependency if it isn't already present in the image"

	(Smalltalk hasClassNamed: #ZnResponse) ifFalse: [
		spec baseline: 'ZincHTTPComponents' with: [ spec repository: 'github://svenvc/zinc/repository' ] ]
]

{ #category : 'private - definitions' }
BaselineOfZagWebDav >> defineGroups: spec [
	"Convenient targets for Metacello loading"

	spec group: 'default' with: #( 'Zag-WebDav' ).
	spec group: 'tests' with: #( 'Zag-WebDav-Tests' )
]

{ #category : 'private - definitions' }
BaselineOfZagWebDav >> definePackages: spec [
	"In Pharo, Zinc is built-in, so Zag-WebDav requires no extra load dependencies"

	(Smalltalk hasClassNamed: #ZnResponse)
		ifTrue: [ spec package: 'Zag-WebDav' ]
		ifFalse: [ spec package: 'Zag-WebDav' with: [ spec requires: #( 'ZincHTTPComponents' ) ] ].
	spec package: 'Zag-WebDav-Tests' with: [ spec requires: #('Zag-WebDav') ].
]
