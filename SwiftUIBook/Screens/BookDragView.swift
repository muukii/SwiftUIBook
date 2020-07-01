import SwiftUI

struct BookDragView: View {

  @State private var currentPosition: CGSize = .zero
  @State private var newPosition: CGSize = .zero

  var body: some View {
    ZStack {
      DraggableView {
        Circle()
          .frame(width: 100, height: 100)
          .foregroundColor(Color.red)
      }
      DraggableView {
        Circle()
          .frame(width: 100, height: 100)
          .foregroundColor(Color.red)
      }
      DraggableView {
        Circle()
          .frame(width: 100, height: 100)
          .foregroundColor(Color.red)
      }
    }
  }

}

extension BookDragView {

  struct DraggableView<Content: View>: View {

    @State private var currentPosition: CGPoint = .zero
    @State private var newPosition: CGPoint = .zero

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
      self.content = content()
    }

    var body: some View {
      content
        .offset(x: currentPosition.x, y: currentPosition.y)
        .gesture(
          DragGesture()
            .onChanged { value in
              currentPosition = .init(
                x: value.translation.width + newPosition.x,
                y: value.translation.height + newPosition.y
              )
            }
            .onEnded { value in
              currentPosition = .init(
                x: value.translation.width + newPosition.x,
                y: value.translation.height + newPosition.y
              )
              newPosition = currentPosition
            }
        )
    }

  }
}

struct BookDragView_Previews: PreviewProvider {
  static var previews: some View {
    /*@START_MENU_TOKEN@*/Text("Hello, World!")/*@END_MENU_TOKEN@*/
  }
}
