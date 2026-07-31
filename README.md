# Zag-GUI
This project supports interaction with Zag-Smalltalk -- currently via Zed and an LSP

### Zag-WebDav
This is a package that contains a WebDav server to expose image entities (Packages, Classes, and Methods) as a filesystem.

In Pharo simply do `ZagWebDav start` and then there will be a WebDav server at localhost:8383.
- You can mount it on MacOS with a Finder CMD-K where you should connect to http://localhost:8383 as guest. Then it will be moounted on `/Volumes/127.0.0.1/'
- You can mount it on Linux with `mount -t davfs http://localhost:8383 /mnt/pharo`

Once mounted you can open any class with `zed /Volumes/127.0.0.1/class/OrderedCollection` and see all the methods or `vi /Volumes/127.0.0.1/A-Package` to see all classes.


This has no security enabled, so it exposes the image to any program on localhost.

This is a work in progress, so new features will be added.

#### Loading
```smalltalk
Metacello new
  repository: 'github://Zag-Research/Zag-GUI:main';
  baseline: 'ZagWebDav';
  load.
```
