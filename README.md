BlurEffect
==========

My working attempt at creating Apple's blur effect dynamically

NOTE: This does NOT use the UINavigationBar hack that a lot of people are using.  This implementation should work for iOS 8 too and will not get rejected for using private APIs etc...

I am planning on doing some refactoring so that the blur effect can be added to a project as a CocoaPod.

NOTE: There are issues with controls floating above the drawer...  I need to figure out the best way to take the snapshot and display it as the drawer is opening
