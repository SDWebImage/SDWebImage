/*
* This file is part of the SDWebImage package.
* (c) DreamPiggy <lizhuoli1126@126.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

import SwiftUI
import RealityKit
import RealityKitContent
import SDWebImage
import SDWebImageSwiftUI

struct ContentView: View {
    @State var imageURLs = [
    "http://assets.sbnation.com/assets/2512203/dogflops.gif",
    "https://raw.githubusercontent.com/liyong03/YLGIFImage/master/YLGIFImageDemo/YLGIFImageDemo/joy.gif",
    "http://apng.onevcat.com/assets/elephant.png",
    "http://www.ioncannon.net/wp-content/uploads/2011/06/test2.webp",
    "http://www.ioncannon.net/wp-content/uploads/2011/06/test9.webp",
    "http://littlesvr.ca/apng/images/SteamEngine.webp",
    "http://littlesvr.ca/apng/images/world-cup-2014-42.webp",
    "https://isparta.github.io/compare-webp/image/gif_webp/webp/2.webp",
    "https://nokiatech.github.io/heif/content/images/ski_jump_1440x960.heic",
    "https://nokiatech.github.io/heif/content/image_sequences/starfield_animation.heic",
    "https://nr-platform.s3.amazonaws.com/uploads/platform/published_extension/branding_icon/275/AmazonS3.png",
    "https://raw.githubusercontent.com/ibireme/YYImage/master/Demo/YYImageDemo/mew_baseline.jpg",
    "https://via.placeholder.com/200x200.jpg",
    "https://raw.githubusercontent.com/recurser/exif-orientation-examples/master/Landscape_5.jpg",
    "https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/w3c.svg",
    "https://dev.w3.org/SVG/tools/svgweb/samples/svg-files/wikimedia.svg",
    "https://raw.githubusercontent.com/icons8/flat-color-icons/master/pdf/stack_of_photos.pdf",
    "https://raw.githubusercontent.com/icons8/flat-color-icons/master/pdf/smartphone_tablet.pdf"
    ]
    @State var animated: Bool = false // You can change between WebImage/AnimatedImage
    
    // Used to avoid https://twitter.com/fatbobman/status/1572507700436807683?s=20&t=5rfj6BUza5Jii-ynQatCFA
    struct ItemView: View {
        @Binding var animated: Bool
        @State var url: String
        var body: some View {
            NavigationLink(destination: DetailView(url: url, animated: self.animated)) {
                HStack {
                    if self.animated {
                        AnimatedImage(url: URL(string:url))
                        .indicator(.activity)
                        .transition(.fade)
                        .resizable()
                        .scaledToFit()
                        .frame(width: CGFloat(100), height: CGFloat(100), alignment: .center)
                    } else {
                        WebImage(url: URL(string:url))
                        .resizable()
                        .indicator(.activity)
                        .transition(.fade(duration: 0.5))
                        .scaledToFit()
                        .frame(width: CGFloat(100), height: CGFloat(100), alignment: .center)
                    }
                    Text((url as NSString).lastPathComponent)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    
    var body: some View {
        return NavigationView {
            contentView()
            .navigationBarTitle(animated ? "AnimatedImage" : "WebImage")
            .navigationBarItems(leading:
                Button(action: { self.reloadCache() }) {
                    Text("Reload")
                }, trailing:
                Button(action: { self.switchView() }) {
                    Text("Switch")
                }
            )
        }
    }
    
    func contentView() -> some View {
        List {
            ForEach(imageURLs, id: \.self) { url in
                // Must use top level view instead of inlined view structure
                ItemView(animated: $animated, url: url)
            }
            .onDelete { indexSet in
                indexSet.forEach { index in
                    self.imageURLs.remove(at: index)
                }
            }
        }
    }
    
    func reloadCache() {
        SDImageCache.shared.clearMemory()
        SDImageCache.shared.clearDisk(onCompletion: nil)
    }
    
    func switchView() {
        SDImageCache.shared.clearMemory()
        animated.toggle()
    }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
#endif
