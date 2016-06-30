MobMuPlatEditor
=========

MobMuPlatEditor is an application to create and edit user interface files for use in the MobMuPlat iOS app.

The application has two versions:
1) A native OSX version (OSX 10.7 and up)
2) A Java version for use in all other operating systems. 

more info at http://www.mobmuplat.com
See the development distribution available at the above website for more info on usage.

###Building for OSX:
- Get the required submodule (vvopensource) by running:
```
$ cd MobMuPlatEditor
$ git submodule update --init --recursive
```

Note that you may get errors on various VV frameworks "There is no SDK with the name or path... ".
To fix, go to each affected VV framework target (VVBasics-mac, MultiClassXPC, VVOSC-mac, VVMIDI), click Build Settings -> Base SDK, and set it to something valid (i.e. "Latest OSX").