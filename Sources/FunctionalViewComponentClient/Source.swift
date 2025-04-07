
import SwiftUI
import FunctionalViewComponent

@ViewComponent
@MainActor
func hoge(arg1: Int, arg2: String, arg3: @escaping () -> Void) -> some View {
  
  @State var count: Int = 0
  
  VStack {
    Text("\(count), \(arg1), \(arg2)")
    Button("Click me") {
      count += 1
    }
  }
    
}

#Preview {
  hoge(arg1: 1, arg2: "hoge", arg3: {
    print("hit")
  })
}
//
//@ViewComponent
//func hoge() -> some View {
//  
//  struct Component: View {
//    
//    let args: Int
//    
//    init(args: Int) {
//      self.args = args
//    }
//    
//    @State var count: Int
//   
//    var body: some View {
//      Text("\(count), \(args)")
//    }
//    
//  }
//}
