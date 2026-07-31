Extension { #name : 'OrderedCollection' }

{ #category : '*Zag-WebDav' }
OrderedCollection >> stripTrailingSlash [

	self last = $/ ifTrue: [ self removeLast ].
	^ self
]
