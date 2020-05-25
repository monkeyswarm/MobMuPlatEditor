MobMuPlatEditor
=========

MobMuPlatEditor is an application to create and edit user interface files for use in the MobMuPlat iOS app.

The application has two versions:
1) A native OSX version (OSX 10.7 and up)
2) A Java version for use in all other operating systems.

**If you just want the compiled applications**, go to http://www.mobmuplat.com and download the development package .zip file, linked in the "setup" section. More info on usage, including sample files, is in that package.

###Building for OSX:
- Get the required submodule (vvopensource) by running:
```
$ cd MobMuPlatEditor
$ git submodule update --init --recursive
```

Note that you may get errors on various VV frameworks "There is no SDK with the name or path... ".
To fix, go to each affected VV framework target (VVBasics-mac, MultiClassXPC, VVOSC-mac, VVMIDI), click Build Settings -> Base SDK, and set it to something valid (i.e. "Latest OSX").

###Building the Java/Swing editor:
-The 'vvopensource'submodule is not required.
```
$ cd MobMuPlatEditor/MobMuPlatEditor-Java
$ javac -cp src:lib/gson-2.2.4.jar @sources.txt
$ java -cp src:lib/gson-2.2.4.jar com.iglesiaintermedia.MobMuPlatEditor.MMPWindow
```
You can create a jar by copying the gson-2.2.4.jar into /src, then unpacking all its classes into /src/com/... (with "tar xf gson-2.2.4.jar"), then
```
$ cd src
$ jar cvfm MobMuPlatEditor.jar ../manifest.txt .
```

