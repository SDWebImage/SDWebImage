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

![Other Linker Flags](https://user-images.githubusercontent.com/6919743/30030628-be2daf6a-91c0-11e7-8b5c-e0ac92d16b80.png)

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
