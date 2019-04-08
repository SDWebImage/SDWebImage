### Manual Installation Guide

#### Clone the repository:

`git clone https://github.com/SDWebImage/SDWebImage.git`

#### Open the `SDWebImage.xcodeproj`, Select the framework target you need

- `SDWebImage` for dynamic framework. You can also change the `Mach-O Type` to `Static Library` to build static framework in `Build Settings`.
- `SDWebImage Static` for static library.
- `SDWebImageMapKit` for MapKit sub component only.

#### Select platform what you need

- `My Mac` for macOS platform.
- `Generic iOS Device` for iOS platform.
- `Generic tvOS Device` for tvOS platform.
- `Generic watchOS Device` for watchOS platform.

#### Generate `SDWebImage.framework` or `libSDWebImage.a`

Click *Archive* button, then export it. Or you can change Build Configuration to *Release* and run project, There are a `SDWebImage.framework` or `libSDWebImage.a` in the build folder. (If you don't see it, change `Skip Install` to YES in build settings and re-try).

#### Apply the framwork or static library to your project

Open your application project, then click `Linkced Frameworks and Libraries` to add the framwork or static library.
