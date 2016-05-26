### Installation by cloning the repository

In order to gain access to all the files from the repository, you should clone it.
```
git clone --recursive https://github.com/rs/SDWebImage.git
```

... TO BE CHECKED AND DESCRIBED IN DETAIL

### Add dependencies

- In you application project app’s target settings, find the "Build Phases" section and open the "Link Binary With Libraries" block:
- Click the "+" button again and select the "ImageIO.framework", this is needed by the progressive download feature:

### Add Linker Flag

Open the "Build Settings" tab, in the "Linking" section, locate the "Other Linker Flags" setting and add the "-ObjC" flag:

![Other Linker Flags](http://dl.dropbox.com/u/123346/SDWebImage/10_other_linker_flags.jpg)

Alternatively, if this causes compilation problems with frameworks that extend optional libraries, such as Parse,  RestKit or opencv2, instead of the -ObjC flag use:
```
-force_load SDWebImage.framework/Versions/Current/SDWebImage
```

If you're using Cocoa Pods and have any frameworks that extend optional libraries, such as Parsen RestKit or opencv2, instead of the -ObjC flag use:
```
-force_load $(TARGET_BUILD_DIR)/libPods.a
```
and this:
```
$(inherited)
```