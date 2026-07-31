"
I am the configurator for Zag-WebDav
"
Class {
	#name : 'BaselineOfZag_WebDav',
	#superclass : 'BaselineOf',
	#category : 'BaselineOfZag_WebDav-Base',
	#package : 'BaselineOfZag_WebDav',
	#tag : 'Base'
}

{ #category : 'baselines' }
BaselineOfZag_WebDav >> baseline: spec [

	<baseline>
	spec for: #common do: [
			self defineDependencies: spec.
			self definePackages: spec.
			self defineGroups: spec ]
]

{ #category : 'private - definitions' }
BaselineOfZag_WebDav >> defineDependencies: spec [
	"Only declare Zinc as a dependency if it isn't already present in the image"

	(Smalltalk hasClassNamed: #ZnResponse) ifFalse: [
		spec baseline: 'ZincHTTPComponents' with: [ spec repository: 'github://svenvc/zinc/repository' ] ]
]

{ #category : 'private - definitions' }
BaselineOfZag_WebDav >> defineGroups: spec [
    "Convenient targets for Metacello loading"
    spec
        group: 'Core' with: #('Zag-WebDav');
        group: 'default' with: #('Core')
]

{ #category : 'private - definitions' }
BaselineOfZag_WebDav >> definePackages: spec [
    "Declare your internal packages and their load order"
    spec
        package: 'Zag-WebDav' with: [ spec requires: #('ZincHTTPComponents') ]
]
