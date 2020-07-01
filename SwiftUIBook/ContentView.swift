
import SwiftUI

struct ContentView: View {
  
  private let pages: [Page] = [
    Page(title: "Matched", destination: BookMatchedAnimationView()),
    Page(title: "ModalPresentation", destination: MultipleModalView()),
    Page(title: "CustomButtonView", destination: CustomButtonView()),
    Page(title: "IgnoringSafeAreaInsetsView", destination: IgnoringSafeAreaInsetsView()),
    Page(title: "PublishedContentView", destination: PublishedContentView()),
    Page(title: "Flux", destination: FluxContentView()),
    Page(title: "MountUnmountTransitionView", destination: MountUnmountTransitionView()),
    Page(title: "Dragging", destination: BookDragView())
  ]
  
  var body: some View {
    NavigationView {
      List(pages) { page in
        page
      }
      .navigationBarTitle("SwiftUIBook")
    }
  }
}

#if DEBUG
struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
#endif

fileprivate struct Page: View, Identifiable {

  let id: UUID = UUID()

  let title: String
  let destination: AnyView

  init<D: View>(title: String, destination: D) {
    self.title = title
    self.destination = AnyView(destination)
  }

  var body: some View {
    NavigationLink(destination: destination) {
      Text(title)
    }
  }
}
