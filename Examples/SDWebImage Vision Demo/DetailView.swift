/*
* This file is part of the SDWebImage package.
* (c) DreamPiggy <lizhuoli1126@126.com>
*
* For the full copyright and license information, please view the LICENSE
* file that was distributed with this source code.
*/

import SwiftUI
import SDWebImageSwiftUI

struct DetailView: View {
    let url: String
    @State var animated: Bool = true // You can change between WebImage/AnimatedImage
    @State var isAnimating: Bool = true
    
    var body: some View {
        VStack {
            contentView()
            .navigationBarItems(trailing: Button(isAnimating ? "Stop" : "Start") {
                self.isAnimating.toggle()
            })
        }
    }
    func contentView() -> some View {
        HStack {
            if animated {
                AnimatedImage(url: URL(string:url), options: [.progressiveLoad, .delayPlaceholder], isAnimating: $isAnimating)
                .indicator(.progress)
                .resizable()
                .scaledToFit()
            } else {
                WebImage(url: URL(string:url), options: [.progressiveLoad, .delayPlaceholder], isAnimating: $isAnimating)
                .resizable()
                .indicator(.progress)
                .scaledToFit()
            }
        }
    }
}

#if DEBUG
struct DetailView_Previews: PreviewProvider {
    static var previews: some View {
        DetailView(url: "https://nokiatech.github.io/heif/content/images/ski_jump_1440x960.heic", animated: false)
    }
}
#endif
