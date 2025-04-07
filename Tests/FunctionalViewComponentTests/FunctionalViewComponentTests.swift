import MacroTesting
import FunctionalViewComponentMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

final class TrackingMacroTests: XCTestCase {
  
  override func invokeTest() {
    withMacroTesting(
      record: false,
      macros: ["ViewComponent": ViewComponentMacro.self]
    ) {
      super.invokeTest()
    }
  }
  
  func test_primitive() {
    
    assertMacro {
      #"""
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
      """#
    } expansion: {
      """
      """
    }
    
  }
 
}
