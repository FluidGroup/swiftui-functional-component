// The Swift Programming Language
// https://docs.swift.org/swift-book

@attached(body) 
public macro ViewComponent() = #externalMacro(module: "FunctionalViewComponentMacros", type: "ViewComponentMacro")

#if DEBUG
import SwiftUI
@ViewComponent
@MainActor
func basic(
  arg1: Int,
  arg2: String,  
  arg3: @escaping () -> Void
) -> some View {
  
  @State var count: Int = 0  
  
  VStack {
    Text("\(count), \(arg1), \(arg2)")
    Button("Click me") {
      count += 1
    }
  }
  
}

@ViewComponent
@MainActor
func objcct(
  obj: AnyObject
) -> some View {
  
//  unowned let obj = obj
  
  @State var count: Int = 0  
  
  VStack {
  }
  
}

#Preview {
  basic(arg1: 1, arg2: "hoge", arg3: {
    print("hit")
  })
}
#endif
