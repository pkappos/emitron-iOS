/// Copyright (c) 2019 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import SwiftUI

struct DownloadImageName {
  static let active: String = "downloadActive"
  static let inActive: String = "downloadInactive"
}

struct ContentSummaryView: View {

  @State var showHudView: Bool = false
  @State var showSuccess: Bool = false
  var callback: ((ContentDetailsModel, Bool) -> Void)?
  @ObservedObject var downloadsMC: DownloadsMC
  @ObservedObject var contentSummaryMC: ContentSummaryMC
//  var details: ContentDetailsModel
  var body: some View {
    createVStack()
  }
  
  private var bookmarkImage: some View {
    return Button(action: {
      // Download Action
      self.bookmark()
    }) {
      // ISSUE: Not sure why this view is not re-rendering, so I'm forcing a re-render through the state observable
      if !contentSummaryMC.data.bookmarked && contentSummaryMC.state == .hasData {
        Image("bookmarkActive")
          .resizable()
          .frame(width: 20, height: 20)
          .padding([.trailing], 20)
          .foregroundColor(.coolGrey)
      } else {
        Image("bookmarkActive")
          .resizable()
          .frame(width: 20, height: 20)
          .padding([.trailing], 20)
          .foregroundColor(.appGreen)
      }
    }
  }
  
  private var completedTag: AnyView? {
    guard let progression = contentSummaryMC.data.progression, progression.finished else { return nil }
    
    let view = ZStack {
      Rectangle()
        .foregroundColor(.appGreen)
        .cornerRadius(6)
        .frame(width: 86, height: 22) // ISSUE: Commenting out this line causes the entire app to crash, yay
      
      Text("COMPLETED")
        .foregroundColor(.white)
        .font(.uiUppercase)
    }
    
    return AnyView(view)
  }
  
  private var proTag: some View {
    return
      ZStack {
        Rectangle()
          .foregroundColor(.appGreen)
          .cornerRadius(6)
          .frame(width: 36, height: 22) // ISSUE: Commenting out this line causes the entire app to crash, yay
        
        Text("PRO")
          .foregroundColor(.white)
          .font(.uiUppercase)
    }
  }

  private func createVStack() -> some View {
    return VStack(alignment: .leading) {

      HStack {
        Text(contentSummaryMC.data.technologyTripleString.uppercased())
          .font(.uiUppercase)
          .foregroundColor(.battleshipGrey)
          .kerning(0.5)
        // ISSUE: This isn't wrapping to multiple lines, not sure why yet, only .footnote and .caption seem to do it properly without setting a frame? Further investigaiton needed
        Spacer()

        if contentSummaryMC.data.professional {
          proTag
        }
      }

      Text(contentSummaryMC.data.name)
        .font(.uiTitle1)
        .lineLimit(nil)
        //.frame(idealHeight: .infinity) // ISSUE: This line is causing a crash
        // ISSUE: Somehow spacing is added here without me actively setting it to a positive value, so we have to decrease, or leave at 0
        .fixedSize(horizontal: false, vertical: true)

      Text(contentSummaryMC.data.releasedAtDateTimeString)
        .font(.uiCaption)
        .foregroundColor(.battleshipGrey)
        .padding([.top], 5)

      HStack {
        Button(action: {
          // Download Action
          self.download()
        }) {
          self.setUpImageAndProgress()
        }
        bookmarkImage
        completedTag // If needed
      }
      .padding([.top], 20)

      Text(contentSummaryMC.data.description)
        .font(.uiCaption)
        .foregroundColor(.battleshipGrey)
        // ISSUE: Below line causes a crash, but somehow the UI renders the text into multiple lines, with the addition of
        // '.frame(idealHeight: .infinity)' to the TITLE...
        //.frame(idealHeight: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .padding([.top], 20)
        .lineLimit(nil)

      Text("By \(contentSummaryMC.data.contributorString)")
        .font(.uiFootnote)
        .foregroundColor(.battleshipGrey)
        .lineLimit(2)
        .fixedSize(horizontal: false, vertical: true)
        .padding([.top], 5)
    }
  }

  private func setUpImageAndProgress() -> AnyView {
    let imageColor: Color = downloadImageName() == DownloadImageName.inActive ? .appGreen : .coolGrey
    let image = Image(self.downloadImageName())
      .resizable()
      .frame(width: 19, height: 19)
      .foregroundColor(imageColor)
      .onTapGesture {
        self.download()
    }

    // Only show progress on model that is currently being downloaded
    guard let downloadModel = downloadsMC.data.first(where: { $0.content.id == contentSummaryMC.data.id }),
          downloadModel.content.id == downloadsMC.downloadedModel?.content.id else {
      return AnyView(image)
    }

    switch downloadsMC.state {
    case .loading:
      return AnyView(CircularProgressBar(progress: downloadModel.downloadProgress))

    default:
      return AnyView(image)
    }
  }

  private func downloadImageName() -> String {
    let content = ContentSummaryModel(contentDetails: contentSummaryMC.data)
    return downloadsMC.data.contains(where: { $0.content.id == content.id }) ? DownloadImageName.inActive : DownloadImageName.active
  }

  private func download() {
    let success = downloadImageName() != DownloadImageName.inActive
    callback?(contentSummaryMC.data, success)
  }

  private func bookmark() {
    contentSummaryMC.toggleBookmark(for: contentSummaryMC.data.bookmark?.id)
  }
}
