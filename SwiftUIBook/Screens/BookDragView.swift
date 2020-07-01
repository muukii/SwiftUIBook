import SwiftUI

struct BookDragView: View {

  @State private var currentPosition: CGSize = .zero
  @State private var newPosition: CGSize = .zero

  var body: some View {
    ZStack {

      Color.white.opacity(0.001) /** to enable hit testing*/

      ZStack {
        DraggableView {
          Components.MockView(name: "MyView")
        }
        DraggableView {
          ExpandableView {
            Circle()
              .frame(width: 100, height: 100)
              .foregroundColor(Color.red)
          }
        }
        //        DraggableView {
        //          Circle()
        //            .frame(width: 100, height: 100)
        //            .foregroundColor(Color.red)
        //        }
      }
    }
    .onTapGesture {
      UIApplication.shared.endEditing()
    }
  }

}

extension BookDragView {

  enum Components {

    struct MockView: View {

      let name: String

      init(name: String) {
        self.name = name
      }

      var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(Color(white: 0).opacity(0.1))
          .frame(width: 100, height: 100)
          .overlay(
            VStack {
              HStack {
                TextField("Name", text: .constant(name))
                  .font(.headline)
                  .foregroundColor(Color(white: 0.1))
                Spacer()
              }
              Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
          )
      }

    }

  }

  struct ExpandableView<Content: View>: View {

    private let content: Content

    @State private var modifiedFrame: CGSize?

    init(@ViewBuilder content: () -> Content) {
      self.content = content()
    }

    var body: some View {
      content
        .frame(width: modifiedFrame?.width, height: modifiedFrame?.height)
        .padding(8)
        .overlay(
          GeometryReader { (arg: GeometryProxy) in
            ZStack {
              VStack {
                HorizontalHandleView { translationY in
                  updateSize(translateX: nil, translateY: translationY, containerSize: arg.size)
                }

                Spacer()

                HorizontalHandleView { translationY in
                  updateSize(translateX: nil, translateY: translationY * -1, containerSize: arg.size)
                }
              }
              .padding(.horizontal, 16)
              HStack {
                VerticalHandleView { translationX in
                  updateSize(translateX: translationX * -1, translateY: nil, containerSize: arg.size)
                }

                Spacer()

                VerticalHandleView { translationX in
                  updateSize(translateX: translationX, translateY: nil, containerSize: arg.size)
                }
              }
              .padding(.vertical, 16)
            }
          }
        )
    }

    private func updateSize(translateX: CGFloat?, translateY: CGFloat?, containerSize: CGSize) {

      var size = modifiedFrame ?? containerSize

      print(translateX, translateY)

      translateX.map {
        size.width += $0
      }

      translateY.map {
        size.height += $0
      }

      modifiedFrame = size

    }

    private struct VerticalHandleView: View {

      @State private var currentValue: CGFloat = 0

      private let onTranslate: (CGFloat) -> Void

      init(onTranslate: @escaping (CGFloat) -> Void) {
        self.onTranslate = onTranslate
      }

      var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(Color(white: 0.5).opacity(0.5))
          .frame(width: 4)
          .gesture(
            DragGesture(minimumDistance: 0)
              .onChanged { value in
                let old = currentValue
                currentValue = value.translation.width
                onTranslate(currentValue - old)
              }
              .onEnded { value in
                let old = currentValue
                currentValue = value.translation.width
                onTranslate(currentValue - old)
                currentValue = 0
              }
          )
      }
    }

    private struct HorizontalHandleView: View {

      @State private var currentValue: CGFloat = 0

      private let onTranslate: (CGFloat) -> Void

      init(onTranslate: @escaping (CGFloat) -> Void) {
        self.onTranslate = onTranslate
      }

      var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .fill(Color(white: 0.5).opacity(0.5))
          .frame(height: 4)
          .gesture(
            DragGesture(minimumDistance: 0)
              .onChanged { value in
                let old = currentValue
                currentValue = value.translation.height
                onTranslate(old - currentValue)
              }
              .onEnded { value in
                let old = currentValue
                currentValue = value.translation.height
                onTranslate(old - currentValue)
                currentValue = 0
              }
          )
      }
    }
  }

  struct DraggableView<Content: View>: View {

    @State private var currentPosition: CGPoint = .zero
    @State private var newPosition: CGPoint = .zero

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
      self.content = content()
    }

    var body: some View {
      content
        .padding(4)
        .onHover { hovering in
          print(hovering)
        }
        .background(Color(white: 0.1).opacity(0.1).mask(RoundedRectangle(cornerRadius: 16, style: .continuous)))
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
    Group {
      BookDragView.Components.MockView(name: "MyView")

      BookDragView.ExpandableView {
        Text("aa")
          .padding(16)
          .background(Color.orange)
      }
    }
    .background(Color.white)
  }
}
