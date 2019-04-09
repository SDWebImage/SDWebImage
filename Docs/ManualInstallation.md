## Manual Installation Guide

### Build SDWebImage as Framework or Static Library

For most user, to use SDWebImage, just need to build SDWebImage source code into a framework or static library.

For framework, you can choose to use Dynamic Framework (Link during runtime) or Static Framework (Link to the main executable file like Static Library).

It's strongly recommended to use Framework instead of Static Library. Framework can bundle resource and header files together, and have module map for clang module. Which make it easy to use.

And more importantly, Swift can only import the Objective-C code by using modular framework, or using the Bridging Header. (Bridging header contains its own disadvantage but this is beyond the topic).

#### Clone the repository:

```
git clone https://github.com/SDWebImage/SDWebImage.git
```

Then open the `SDWebImage.xcodeproj`.

#### Select the Build Scheme you need

- `SDWebImage` for dynamic framework. You can also change the `Mach-O Type` to `Static Library` to build static framework in `Build Settings`.
- `SDWebImage Static` for static library.
- `SDWebImageMapKit` for MapKit sub component only.

#### Select Build Platform you need

- `My Mac` for macOS platform.
- `Generic iOS Device` for iOS platform.
- `Generic tvOS Device` for tvOS platform.
- `Generic watchOS Device` for watchOS platform.

#### Prepare for archive

Don't try to click `Build` (Command + R). Because by default it will produce the `DEBUG` configuration, which it not suitable for production.

Instead, we use `Archive`. But before we click the button. You have to change the `Skip Install` in `Build Settings`. Or the archived product will not contains any framework.

You can do this by modify the xcconfig file `Module-Shared.xcconfig`. Or you can change it using Xcode GUI of Build Settings.

```
SKIP_INSTALL = NO
```

#### Build the Framework or Static Library

Now, you can click the `Archive` button (`Product -> Archive`). After the build success. Xcode will pop-up the Organizer window.

Click `Distribute Content`. Then ensure the `Built Products` is selected. Click `Next` and select a build folder your want to export. Click `Export`.

You can find a `SDWebImage.framework`, or `libSDWebImage.a` and the Headers Files inside the build folder.

![](https://user-images.githubusercontent.com/6919743/55800822-2bd83880-5b07-11e9-8d72-0d57a848aaf4.png)

#### Link the Framework or Static Library to your project

Under your Project folder. You can create a `Vendor` folder to place the Framework or Static Library.

##### For Framework

For Framework (Dynamic or Static), the Headers are inside the framework. Just copy the `SDWebImage.framework` into the `Vendor` folder.

Open your application Xcode Project, click `Linked Frameworks and Libraries`. Select `Add Other...` and select the `SDWebImage.framework`.

Then all things done if you use Framework.

![](https://user-images.githubusercontent.com/6919743/55804348-af495800-5b0e-11e9-828c-70711ea5fdca.png)

##### For Static Library

For Static Library, you need copy both the `libSDWebImage.a` as well as the Headers into the `Vendor` folder.

![](https://user-images.githubusercontent.com/6919743/55804133-4e218480-5b0e-11e9-86ac-f17aabf6e0c5.png)

Open your application Xcode Project, click `Linked Frameworks and Libraries`. Select `Add Other...` and select the `libSDWebImage.a`.

After link, you need to specify the Header Search Path for headers. Check Build Settings's `Header Search Path`, add the Header Search Path, where there must be a `SDWebImage` parent directory of `SDWebImage.h` this umbrella header file.

The example above can using the following path.

```
$(SRCROOT)/Vendor
```

Then all things done if you use Static Library.

### Using SDWebImage as Sub Xcode Project

You can also embed SDWebImage as a Sub Xcode Project using in your Xcode Workspace. This can be used for some specify environment which does not support external dependency manager.

#### Clone the repository as submodule

To embed the Sub Xcode Project, you can simply add SDWebImage entire project using Git Submodule. 

```
cd Vendor/
git submodule add https://github.com/SDWebImage/SDWebImage.git
```

#### Ensure you have a Workspace

If you don't have a Xcode Workspace, you can simply create one.

Open your exist Xcode Project. Click `File -> Save As Workspace...`. You can save it to the same directory of your original Project.

#### Add `SDWebImage.xcodeproj` into your Workspace

Just drag the `SDWebImage.xcodeproj` you cloned, into your Xcode Workspace's Project Navigator. Put it the same level of your original Project.

![](https://user-images.githubusercontent.com/6919743/55799669-802de900-5b04-11e9-84c0-08d4d9452549.png)

#### Link to your App/Framework Target

To use SDWebImage, you should link the `SDWebImage` target.

Go to your App/Framework target's `General` page. Then click `Lined Frameworks and Libraries`, and add the `SDWebImage.framework` or `libSDWebImage.a` (Depends on your use case).

Then all things done.

![](https://user-images.githubusercontent.com/6919743/55799628-68eefb80-5b04-11e9-8f0b-4b7818c5d1fd.png)


