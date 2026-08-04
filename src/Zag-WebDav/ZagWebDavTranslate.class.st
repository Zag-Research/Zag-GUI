"
I am a utility class to translate method selectors to valid WebDav filenames and back.
"
Class {
	#name : 'ZagWebDavTranslate',
	#superclass : 'Object',
	#classInstVars : [
		'binaryMappings',
		'reverseBinaryMappings',
		'colon'
	],
	#category : 'Zag-WebDav-Utility',
	#package : 'Zag-WebDav',
	#tag : 'Utility'
}

{ #category : 'converting' }
ZagWebDavTranslate class >> binaryMap: aString on: mappings symbolKeys: keysAsSymbols [

	^ mappings
		  at: (keysAsSymbols
				   ifTrue: [ aString asSymbol ]
				   ifFalse: [ aString ])
		  ifAbsentPut: [
				  | string |
				  string := String streamContents: [ :s |
						            aString do: [ :c |
								            s nextPutAll: (mappings
										             at: (keysAsSymbols
												              ifTrue: [ c asString asSymbol ]
												              ifFalse: [ c asString ])
										             ifAbsent: [ c asString ]) ] ].
				  keysAsSymbols
					  ifTrue: [ string ]
					  ifFalse: [ string asSymbol ] ]
]

{ #category : 'class initialization' }
ZagWebDavTranslate class >> initialize [

	<script>
	colon := (Character codePoint: 16rA789) asString.
	binaryMappings := {
		                  (#/ -> '⁄'). "U+2044 Fraction Slash (no gap in dev fonts)"
		                  (#\ -> '⧵'). "U+29F5 Reverse Solidus Operator"
		                  (#* -> '∗'). "U+2217 Asterisk Operator"
		                  (#| -> '∣'). "U+2223 Divides"
		                  (#< -> '˂'). "U+02C2 Modifier Letter Left Arrowhead"
		                  (#> -> '˃'). "U+02C3 Modifier Letter Right Arrowhead"
		                  (#? -> 'ʔ') "U+0294 Latin Letter Glottal Stop" } asDictionary.
	reverseBinaryMappings := {
		                         ('⁄' -> #/).
		                         ('⧵' -> #\).
		                         ('∗' -> #*).
		                         ('∣' -> #|).
		                         ('˂' -> #<).
		                         ('˃' -> #>).
		                         ('ʔ' -> #?) } asDictionary
]

{ #category : 'converting' }
ZagWebDavTranslate class >> toFilename: aSymbol [
	" encode binary operators "

	aSymbol isBinary ifTrue: [ ^ self binaryMap: aSymbol on: binaryMappings symbolKeys: true ].

	"Replaces colons with underscores for file system compatibility"
	^ aSymbol asString copyReplaceAll: ':' with: colon
]

{ #category : 'converting' }
ZagWebDavTranslate class >> toSelector: aFilenameString [
	"Strips the .st extension if any and converts filename-safe characters back to a Smalltalk selector"

	| baseName |
	"Remove possible file extension"
	baseName := aFilenameString withoutSuffix: '.st'.

	((baseName first between: $A and: $Z) or: [ baseName first between: $a and: $z ]) ifFalse: [
		^ self binaryMap: baseName on: reverseBinaryMappings symbolKeys: false ].

	"2. Convert underscores or fake colons back to colons"
	^ ((baseName copyReplaceAll: colon with: ':') copyReplaceAll: '_' with: ':') asSymbol
]
