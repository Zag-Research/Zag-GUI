"
I am a WebDav client.

My primary motivation is to serve Packages, Classes, and Methods to an editor such as Zed.

### API:
- `ZagWebDav start` - start a server on default port
- `ZagWebDav stop` - stop the server

However it would be nice to have a full-functioning WebDav server.

### What is Missing for a Full WebDAV Server?
Right now, we have built a minimal read/write WebDAV adapter. It implements just enough of RFC 4918 for an OS file system or editor to read virtual files and write back modifications. To become a fully compliant WebDAV server, here is what is missing:

#### Real Lock Semantics (RFC 4918 Section 6 & 7)
Currently, our server ""fakes"" locking by generating a UUID lock token on LOCK and accepting every write. In a fully compliant server, lock semantics require:
1. **Lock Registry:** A central manager mapping Lock Tokens to URIs, client identity, lock type (Exclusive vs. Shared), and expiry timestamps (Timeout: Second-3600).
2. **The If: Header Enforcement:** When a file is locked, clients send subsequent PUT, DELETE, or PROPPATCH requests with an If: header containing the token (e.g., If: (<opaquelocktoken:1234...>)). If the header is missing or the token doesn't match, the server must reject the operation with 423 Locked.
3. **Lock Refreshing:** Clients send LOCK requests without a body on an already-locked resource to reset the timeout timer.
4. **Depth-Based Locks:** Locking a directory (Depth: infinity) must recursively lock every child method and file inside that folder.
#### Other Protocol Features Missing
1. **PROPPATCH:** Allows clients to set custom key-value metadata on files (like macOS tags or color labels).
2. **MKCOL:** Standard command for creating new directories (creating a new Smalltalk Package or Class).
3. **COPY / MOVE:** Handles file renaming and moving (which in your domain would translate to renameClass:, compile:inCategory:, or refactoring selectors).
4. **DELETE:** Handles deleting files/folders (removing methods or unhousing classes).
5. **ETags & Conditional Requests:** If-Match and If-None-Match headers using entity tags to prevent two clients from overwriting each other's changes if locking isn't used. An etag is a version number of a file, used for caching and preventing overwrite if a file has changed since read.
"
Class {
	#name : 'ZagWebDav',
	#superclass : 'Object',
	#classVars : [
		'BinaryMappings',
		'Colon',
		'ReverseBinaryMappings'
	],
	#classInstVars : [
		'server'
	],
	#category : 'Zag-WebDav-Core',
	#package : 'Zag-WebDav',
	#tag : 'Core'
}

{ #category : 'class initialization' }
ZagWebDav class >> initialize [

	<script>
	Colon := (Character codePoint: 16rA789) asString.
	BinaryMappings := {
		                  (#+ -> '+').
		                  (#- -> '-').
		                  (#* -> '×').
		                  (#/ -> '÷').
		                  (#'\\' -> '⧵⧵').
		                  (#= -> '=').
		                  (#'==' -> '==').
		                  (#'~=' -> '~=').
		                  (#< -> '‹').
		                  (#'<=' -> '≤').
		                  (#> -> '›').
		                  (#'>=' -> '≥').
		                  (#@ -> '@').
		                  (#, -> ',').
		                  (#~ -> '~').
		                  (#| -> '|').
		                  (#& -> '&').
		                  (#'=~' -> '=~').
		                  (#'@@' -> '@@').
		                  (#'\\=' -> '⧵⧵=').
		                  (#'**' -> '××').
		                  (#'*=' -> '×=').
		                  (#'//' -> '÷÷').
		                  (#'-=' -> '-=').
		                  (#'==>' -> '==›').
		                  (#'->' -> '-›').
		                  (#'>>' -> '››').
		                  (#'--' -> '--').
		                  (#'~~>' -> '~~›').
		                  (#\ -> '⧵').
		                  (#'\\\' -> '⧵⧵⧵').
		                  (#% -> '%').
		                  (#'~~' -> '~~').
		                  (#'=>' -> '=›').
		                  (#'+=' -> '+=').
		                  (#'<<' -> '_').
		                  (#'+*' -> '+×').
		                  (#'/=' -> '÷=').
		                  (#'@=' -> '@=').
		                  (#'>>>' -> '›››').
		                  (#'<-' -> '‹-').
		                  (#? -> '﹖') } asDictionary.
	ReverseBinaryMappings := Dictionary new.
	BinaryMappings keysAndValuesDo: [ :key :value | "	
Selector,Unicode Character,Code Point,Resulting Filename,OS Compatibility
>=,≥ (Greater than or equal),U+2265,≥.st,✅ All OSs
<=,≤ (Less than or equal),U+2264,≤.st,✅ All OSs
~=,≠ (Not equal),U+2260,≠.st,✅ All OSs
==,≡ (Identical / Equivalent),U+2261,≡.st,✅ All OSs
*,× (Multiplication sign),U+00D7,×.st,✅ All OSs (Replaces forbidden ASCII *)
/,÷ (Division sign),U+00F7,÷.st,✅ All OSs (Replaces forbidden ASCII /)
\,⧵ (Reverse solidus op),U+29F5,⧵.st,✅ All OSs (Replaces forbidden ASCII \)
|,∣ (Divides / Vertical bar),U+2223,∣.st,✅ All OSs (Replaces forbidden ASCII |)
<,‹ or ＜ (Single Guillemet / Fullwidth),U+2039 / U+FF1C,‹.st,✅ All OSs (Replaces forbidden ASCII <)
>,› or ＞ (Single Guillemet / Fullwidth),U+203B / U+FF1E,›.st,✅ All OSs (Replaces forbidden ASCII >)
+,+ (ASCII Plus),U+002B,+.st,✅ All OSs
-,- (ASCII Minus),U+002D,-.st,✅ All OSs
@,@ (ASCII At),U+0040,@.st,✅ All OSs
"","","", (ASCII Comma)"",U+002C,"","",✅ All OSs"
		ReverseBinaryMappings at: value put: key ]
]

{ #category : 'accessing' }
ZagWebDav class >> start [
	"Start a basic HTTP server on port 8383"

	<script>
	^ self startOn: 8383
]

{ #category : 'accessing' }
ZagWebDav class >> startOn: port [
	"Start a basic HTTP server on port"

	<script>
	self stop.
	server := ZnServer startOn: port.

	"Set up a delegate to intercept requests"
	server delegate: self new.
	^ server
]

{ #category : 'accessing' }
ZagWebDav class >> stop [
	" stop HTTP server "

	<script>
	server ifNotNil: [ server stop].
	server := nil
]

{ #category : 'private' }
ZagWebDav >> decodeSelector: aFilenameString [
	"Strips the .st extension and converts filename-safe characters back to a Smalltalk selector"

	| baseName |
	"Remove the file extension"
	baseName := aFilenameString withoutSuffix: '.st'.

	ReverseBinaryMappings at: baseName ifPresent: [ :s | ^ s ].

	"2. Convert underscores back to colons"
	^ ((baseName copyReplaceAll: Colon with: ':') copyReplaceAll: '_' with: ':') asSymbol
]

{ #category : 'private' }
ZagWebDav >> encodeSelector: aSymbol [
	" encode binary operators "

	aSymbol isBinary ifTrue: [
		^ BinaryMappings at: aSymbol asSymbol ifAbsentPut: [ String streamContents: [ :s | s << 'op_' << aSymbol ] ] ].

	"Replaces colons with underscores for file system compatibility"
	^ aSymbol asString copyReplaceAll: ':' with: Colon
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
            stream nextPutAll: (self makeXmlNodeFor: '/' method: nil).
            depth = '1' ifTrue: [
                stream nextPutAll: (self makeXmlNodeFor: '/class' method: nil).
                self systemPackages do: [ :pkg |
                    stream nextPutAll: (self makeXmlNodeFor: '/', pkg name asString method: nil).
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
ZagWebDav >> makeXmlNodeFor: hrefPath method: compiledMethod [

	| isDir formattedHref cleanPath displayName urlEncodedHref escapedName |
	isDir := compiledMethod isNil.
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
		               ifTrue: [ Smalltalk image shortImageName withoutSuffix: '.image' ]
		               ifFalse: [ cleanPath copyAfterLast: $/ ].
	urlEncodedHref := formattedHref urlEncoded copyReplaceAll: '%2F' with: '/'.
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
				  ifTrue: [
						  s << '<D:getcontenttype>httpd/unix-directory</D:getcontenttype><D:getetag>"dir-1"</D:getetag>'
						  << '<D:getlastmodified>Thu, 30 Jul 2026 12:00:00 GMT</D:getlastmodified>' ]
				  ifFalse: [
						  s << '<D:getcontentlength>' << compiledMethod sourceCode size asString << '</D:getcontentlength>'.
						  s << '<D:getcontenttype>text/plain</D:getcontenttype>' << '<D:getetag>"file-1"</D:getetag>'.
						  s << '<D:getlastmodified>' << (ZnUtils httpDate: (DateAndTime fromMethodTimestamp: compiledMethod timeStamp))
						  << '</D:getlastmodified>' ].


			  s nextPutAll: '</D:prop><D:status>HTTP/1.1 200 OK</D:status></D:propstat></D:response>'.
			  s nextPut: Character lf ]
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
			  segments size = 1 ifTrue: [ stream nextPutAll: (self makeXmlNodeFor: '/class' method: nil) ].

			  segments size = 2 ifTrue: [
					  | className class |
					  className := segments second.
					  stream nextPutAll: (self makeXmlNodeFor: '/class/' , className method: nil).

					  depth = '1' ifTrue: [
							  class := Smalltalk globals at: className asSymbol ifAbsent: [ nil ].
							  class ifNotNil: [
									  class selectors do: [ :sel |
											  | fileName |
											  fileName := '/class/' , className , '/' , (self encodeSelector: sel).
											self crTrace: fileName.
											  stream nextPutAll: (self makeXmlNodeFor: fileName method: class >> sel) ] ] ] ] ]
]

{ #category : 'request handling' }
ZagWebDav >> propfindPackageTree: segments depth: depth [
    ^ String streamContents: [ :stream |
        | pkgName |
        pkgName := segments first asString.
        
        segments size = 1 ifTrue: [
            stream nextPutAll: (self makeXmlNodeFor: ('/', pkgName) method: nil).
            (depth = '1') ifTrue: [
                | pkg |
                pkg := self packageNamed: pkgName.
                pkg ifNotNil: [
                    pkg definedClasses do: [ :cls |
                        | path |
                        path := '/', pkgName, '/', cls name asString.
                        stream nextPutAll: (self makeXmlNodeFor: path method: nil).
                    ].
                ].
            ].
        ].
        
        segments size = 2 ifTrue: [
            | className class |
            className := segments second asString.
            stream nextPutAll: (self makeXmlNodeFor: ('/', pkgName, '/', className) method: nil).
            (depth = '1') ifTrue: [
                class := Smalltalk globals at: className asSymbol ifAbsent: [ nil ].
                class ifNotNil: [
                    class selectors do: [ :sel |
                        | fileName |
                        fileName := '/', pkgName, '/', className, '/', (self encodeSelector: sel).
                        stream nextPutAll: (self makeXmlNodeFor: fileName method: class >> sel).
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
			^ class notNil ].

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
