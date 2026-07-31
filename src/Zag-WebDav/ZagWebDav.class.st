"
I am a WebDav client.

My primary motivation is to serve Packages, Classes, and Methds to an editor such as Zed.
"
Class {
	#name : 'ZagWebDav',
	#superclass : 'Object',
	#classInstVars : [
		'server'
	],
	#category : 'Zag-WebDav-Core',
	#package : 'Zag-WebDav',
	#tag : 'Core'
}

{ #category : 'accessing' }
ZagWebDav class >> start [
	"Start a basic HTTP server on port 8383"

	<script>
	server := ZnServer startOn: 8383.

	"Set up a delegate to intercept requests"
	server delegate: self new
]

{ #category : 'accessing' }
ZagWebDav class >> stop [
	" stop HTTP server "

	<script>
	server stop.
	server := nil
]

{ #category : 'private' }
ZagWebDav >> decodeSelector: aFilenameString [
    "Strips the .st extension and converts filename-safe characters back to a Smalltalk selector"
    | baseName decodedString |
    
    "1. Remove the file extension"
    baseName := aFilenameString withoutSuffix: '.st'.
    
    "2. Convert underscores back to colons"
    decodedString := baseName copyReplaceAll: '_' with: ':'.
    
    "3. Return as a Symbol so it can be used to look up the method"
    ^ decodedString asSymbol.
]

{ #category : 'private' }
ZagWebDav >> encodeSelector: aSymbol [
    "Replaces colons with underscores for file system compatibility"
    ^ aSymbol asString copyReplaceAll: ':' with: '_'
]

{ #category : 'private' }
ZagWebDav >> escapeXml: aString [
    ^ ((aString copyReplaceAll: '&' with: '&amp;')
        copyReplaceAll: '<' with: '&lt;')
        copyReplaceAll: '>' with: '&gt;'
]

{ #category : 'private' }
ZagWebDav >> extractClassAndSelectorFrom: segments [
	"Returns an array { class. selector } or nil if invalid"

	| className fileName sel class |
	"Both /class/<ClassName>/<Method>.st and /<PackageName>/<ClassName>/<Method>.st are 3 segments"
	segments size = 3 ifFalse: [ ^ nil ].

	className := segments second.
	fileName := segments third.

	(fileName endsWith: '.st') ifFalse: [ ^ nil ].
	class := Smalltalk globals at: className asSymbol ifAbsent: [ ^ nil ].
	sel := self decodeSelector: fileName.

	^ {
		  class.
		  sel }
]

{ #category : 'request handling' }
ZagWebDav >> handleCatchAll: request [
    "Fakes a successful response for WebDAV locking and metadata requests"
    ^ ZnResponse ok: (ZnEntity text: '')
]

{ #category : 'request handling' }
ZagWebDav >> handleGet: request [
    | target class sel source segments |
    segments := request uri segments stripTrailingSlash.
    
    (self resourceExists: segments) ifFalse: [ 
        ^ ZnResponse notFound: request uri 
    ].
    
    target := self extractClassAndSelectorFrom: segments.
    target ifNil: [ 
        ^ ZnResponse ok: (ZnEntity text: 'Pharo WebDAV Collection')
    ].
    
    class := target first.
    sel := target second.
    
    (class includesSelector: sel) ifFalse: [ ^ ZnResponse notFound: request uri ].
    
    source := (class >> sel) sourceCode.
    ^ ZnResponse ok: (ZnEntity text: source)
]

{ #category : 'request handling' }
ZagWebDav >> handleLock: request [
    | token xml entity response |
    
    "1. Generate a unique lock token (macOS expects it to start with opaquelocktoken:)"
    token := 'opaquelocktoken:', UUID new asString.

    "2. Build the required WebDAV lock discovery XML"
    xml := '<?xml version="1.0" encoding="utf-8" ?>
<D:prop xmlns:D="DAV:">
  <D:lockdiscovery>
    <D:activelock>
      <D:locktype><D:write/></D:locktype>
      <D:lockscope><D:exclusive/></D:lockscope>
      <D:depth>infinity</D:depth>
      <D:timeout>Second-3600</D:timeout>
      <D:locktoken><D:href>', token, '</D:href></D:locktoken>
    </D:activelock>
  </D:lockdiscovery>
</D:prop>'.

    "3. Create the XML entity"
    entity := ZnEntity with: xml type: ZnMimeType applicationXml.
    
    "4. Return the 200 OK response with the all-important Lock-Token header"
    response := ZnResponse ok: entity.
    response headers at: 'Lock-Token' put: ('<', token, '>').
    
    ^ response
]

{ #category : 'request handling' }
ZagWebDav >> handleOptions: request [
    | response |
    response := ZnResponse new 
        statusLine: ZnStatusLine ok;
        entity: (ZnEntity text: ''); "Forces Content-Length: 0"
        yourself.
    response headers 
        at: 'Allow' put: 'OPTIONS, GET, HEAD, PUT, PROPFIND';
        at: 'DAV' put: '1, 2'.
    ^ response
]

{ #category : 'request handling' }
ZagWebDav >> handlePropfind: request [
    | segments depth xmlBody response |
    segments := request uri segments stripTrailingSlash.
    
    "If macOS asks for .DS_Store or a non-existent class, return 404!"
    (self resourceExists: segments) ifFalse: [ 
        ^ ZnResponse notFound: request uri 
    ].
    
    depth := request headers at: 'Depth' ifAbsent: [ '1' ].
    
    xmlBody := String streamContents: [ :stream |
        stream nextPutAll: '<?xml version="1.0" encoding="utf-8" ?><D:multistatus xmlns:D="DAV:">'.
        
        segments isEmptyOrNil ifTrue: [
            stream nextPutAll: (self makeXmlNodeFor: '/' isDir: true).
            depth = '1' ifTrue: [
                stream nextPutAll: (self makeXmlNodeFor: '/class' isDir: true).
                self systemPackages do: [ :pkg |
                    stream nextPutAll: (self makeXmlNodeFor: '/', pkg name asString isDir: true).
                ].
            ].
        ] ifFalse: [
            segments first = 'class' 
                ifTrue: [ stream nextPutAll: (self propfindClassTree: segments depth: depth) ]
                ifFalse: [ stream nextPutAll: (self propfindPackageTree: segments depth: depth) ].
        ].
        
        stream nextPutAll: '</D:multistatus>'.
    ].
    
    response := ZnResponse new 
        statusLine: (ZnStatusLine code: 207); 
        entity: (ZnStringEntity xml: xmlBody); 
        yourself.
        
    "Safe MIME type without triggering the CharacterSet exception"
    response entity contentType: (ZnMimeType main: 'text' sub: 'xml').
    response headers at: 'DAV' put: '1, 2'.
    
    ^ response
]

{ #category : 'request handling' }
ZagWebDav >> handlePut: request [

	| segments class sourceCode target |
	segments := request uri segments stripTrailingSlash.

	"Ignore hidden OS files like .DS_Store during PUT"
	(segments last asString beginsWith: '.') ifTrue: [ ^ ZnResponse ok: (ZnEntity text: '') ].

	"For URL: /Zag-WebDav/ZagWebDav/packageNamed_.st"
	"segments => #('Zag-WebDav' 'ZagWebDav' 'packageNamed_.st')"
	target := self extractClassAndSelectorFrom: segments.
	target ifNil: [ ^ ZnResponse ok: (ZnEntity text: 'Pharo WebDAV Collection') ].

	class := target first.

	sourceCode := request entity contents utf8Decoded withInternalLineEndings.
	class compile: sourceCode withInternalLineEndings.

	" Return 204 No Content so remote knows the save succeeded without needing a response body"
	^ ZnResponse noContent
]

{ #category : 'public' }
ZagWebDav >> handleRequest: request [

	| method |
	method := request method.

	method = #PROPFIND ifTrue: [ ^ self handlePropfind: request ].
	method = #GET ifTrue: [ ^ self handleGet: request ].
	method = #PUT ifTrue: [ ^ self handlePut: request ].
	method = #LOCK ifTrue: [ ^ self handleLock: request ].
	method = #OPTIONS ifTrue: [ ^ self handleOptions: request ].

	"Catch-all for LOCK, UNLOCK, PROPPATCH to keep the OS client happy"
	^ self handleCatchAll: request
]

{ #category : 'private' }
ZagWebDav >> makeXmlNodeFor: hrefPath isDir: isDir [

	| formattedHref cleanPath displayName urlEncodedHref escapedName |
	formattedHref := isDir
		                 ifTrue: [
				                 (hrefPath endsWith: '/')
					                 ifTrue: [ hrefPath ]
					                 ifFalse: [ hrefPath , '/' ] ]
		                 ifFalse: [ hrefPath ].

	cleanPath := (hrefPath endsWith: '/')
		             ifTrue: [ hrefPath copyFrom: 1 to: (hrefPath size - 1 max: 1) ]
		             ifFalse: [ hrefPath ].

	displayName := (cleanPath isEmptyOrNil or: [ cleanPath = '/' ])
		               ifTrue: [ 'Pharo' ]
		               ifFalse: [ cleanPath copyAfterLast: $/ ].

	urlEncodedHref := formattedHref copyReplaceAll: ' ' with: '%20'.
	escapedName := self escapeXml: displayName asString.

	^ String streamContents: [ :s |
			  s
				  nextPutAll: '<D:response><D:href>';
				  nextPutAll: urlEncodedHref;
				  nextPutAll: '</D:href><D:propstat><D:prop><D:displayname>';
				  nextPutAll: escapedName;
				  nextPutAll: '</D:displayname><D:resourcetype>'.

			  isDir ifTrue: [ s nextPutAll: '<D:collection/>' ].

			  s nextPutAll: '</D:resourcetype>'.

			  isDir
				  ifTrue: [ s nextPutAll: '<D:getcontenttype>httpd/unix-directory</D:getcontenttype><D:getetag>"dir-1"</D:getetag>' ]
				  ifFalse: [
						  s nextPutAll:
							  '<D:getcontentlength>100</D:getcontentlength><D:getcontenttype>text/plain</D:getcontenttype><D:getetag>"file-1"</D:getetag>' ].

			  s nextPutAll:
				  '<D:getlastmodified>Thu, 30 Jul 2026 12:00:00 GMT</D:getlastmodified></D:prop><D:status>HTTP/1.1 200 OK</D:status></D:propstat></D:response>' ]
]

{ #category : 'private' }
ZagWebDav >> packageNamed: aString [
    " find a package by name, using the correct package organizer class "

    | organizerClass |
    organizerClass := Smalltalk globals
        at: #PackageOrganizer
        ifAbsent: [ Smalltalk globals at: #RPackageOrganizer ].
    ^ organizerClass default packageNamed: aString ifAbsent: [ nil ]

]

{ #category : 'request handling' }
ZagWebDav >> propfindClassTree: segments depth: depth [
    ^ String streamContents: [ :stream |
        segments size = 1 ifTrue: [
            stream nextPutAll: (self makeXmlNodeFor: '/class' isDir: true).
        ].
        
        segments size = 2 ifTrue: [
            | className class |
            className := segments second.
            stream nextPutAll: (self makeXmlNodeFor: ('/class/', className) isDir: true).
            
            (depth = '1') ifTrue: [
                class := Smalltalk globals at: className asSymbol ifAbsent: [ nil ].
                class ifNotNil: [
                    class selectors do: [ :sel |
                        | fileName |
                        fileName := '/class/', className, '/', (self encodeSelector: sel), '.st'.
                        stream nextPutAll: (self makeXmlNodeFor: fileName isDir: false).
                    ].
                ].
            ].
        ].
    ]
]

{ #category : 'request handling' }
ZagWebDav >> propfindPackageTree: segments depth: depth [
    ^ String streamContents: [ :stream |
        | pkgName |
        pkgName := segments first asString.
        
        segments size = 1 ifTrue: [
            stream nextPutAll: (self makeXmlNodeFor: ('/', pkgName) isDir: true).
            (depth = '1') ifTrue: [
                | pkg |
                pkg := self packageNamed: pkgName.
                pkg ifNotNil: [
                    pkg definedClasses do: [ :cls |
                        | path |
                        path := '/', pkgName, '/', cls name asString.
                        stream nextPutAll: (self makeXmlNodeFor: path isDir: true).
                    ].
                ].
            ].
        ].
        
        segments size = 2 ifTrue: [
            | className class |
            className := segments second asString.
            stream nextPutAll: (self makeXmlNodeFor: ('/', pkgName, '/', className) isDir: true).
            (depth = '1') ifTrue: [
                class := Smalltalk globals at: className asSymbol ifAbsent: [ nil ].
                class ifNotNil: [
                    class selectors do: [ :sel |
                        | fileName |
                        fileName := '/', pkgName, '/', className, '/', (self encodeSelector: sel), '.st'.
                        stream nextPutAll: (self makeXmlNodeFor: fileName isDir: false).
                    ].
                ].
            ].
        ].
    ]
]

{ #category : 'private' }
ZagWebDav >> resourceExists: segments [

	| className class |
	(segments isNil or: [ segments isEmptyOrNil ]) ifTrue: [ ^ true ].

	"Instantly reject macOS hidden files like .DS_Store"
	(segments last beginsWith: '.') ifTrue: [ ^ false ].

	"Level 1: Packages"
	segments size = 1 ifTrue: [
			segments first = 'class' ifTrue: [ ^ true ].
			^ (self packageNamed: segments first) notNil ].

	"Level 2: Classes"
	segments size = 2 ifTrue: [
			className := segments second.
			class := Smalltalk globals at: className asSymbol ifAbsent: [ nil ].
			^ class notNil ].

	"Level 3: Methods"
	segments size = 3 ifTrue: [
			className := segments second.
			class := Smalltalk globals at: className asSymbol ifAbsent: [ nil ].
			^ class notNil and: [ segments third endsWith: '.st' ] ].

	^ false
]

{ #category : 'private' }
ZagWebDav >> systemPackages [
    | organizerClass |
    organizerClass := Smalltalk globals 
        at: #PackageOrganizer 
        ifAbsent: [ Smalltalk globals at: #RPackageOrganizer ].
    ^ organizerClass default packages
]
