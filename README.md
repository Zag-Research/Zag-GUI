# Zag-GUI
This project supports interaction with Zag-Smalltalk -- the target is via Zed and an LSP. The best we have right now is WebDav.

### Zag-WebDav
This is a package that contains a WebDav server to expose image entities (Packages, Classes, and Methods) as a filesystem.

In Pharo simply do `ZagWebDav start` and then there will be a WebDav server at localhost:8383.
- You can mount it on MacOS with a Finder CMD-K where you should connect to http://localhost:8383 as guest. Then it will be mounted on `/Volumes/127.0.0.1/'
- You can mount it on Linux with `mount -t davfs http://localhost:8383 /mnt/pharo`
- `ZagWebDev stop` to shut it down.

Once mounted you can open any class with `zed /Volumes/127.0.0.1/class/OrderedCollection` and see all the methods or `vim /Volumes/127.0.0.1/A-Package` to see all classes in the package.

It is somewhat featureful except for security. From an editor, you can edit or create methods and class Comments, although not create classes or change properties like categories, inheritance, instance variables, or class variables. You can also "mount" a filesystem on the Pharo side which, for example, can let you implement a read-only Zag image at `/Volumes/127.0.0.1/zagImage/SomeClass/someUnarySelector/`.

This has no security enabled, so it exposes the image to any program on localhost. But it's only visible on 127.0.0.1, so shouldn't be an issue on a personal workstation.

#### Loading
```smalltalk
Metacello new
  repository: 'github://Zag-Research/Zag-GUI:main';
  baseline: 'ZagWebDav';
  load.
```
