# swiftui-functional-component

A Swift macro library that enables to make SwiftUI stateful component from function declaration. It automatically converts a function with parameters into a SwiftUI View struct with proper state management (@State, @Binding) and initialization.

## Overview

```swift
@ViewComponent
func hoge(arg1: Int, arg2: String, arg3: @escaping () -> Void) -> some View {
  
  @State var count: Int = 0
  
  VStack {
    Text("\(count), \(arg1), \(arg2)")
    Button("Click me") {
      count += 1
    }
  }
    
}
```

Macro expands above into this:

```swift
func hoge(arg1: Int, arg2: String, arg3: @escaping () -> Void) -> some View {
  struct Component: View {
    
    let arg1: Int
    let arg2: String
    let arg3: () -> Void
    @State var count: Int = 0
    
    init(arg1: Int, arg2: String, arg3: @escaping () -> Void) {
      self.arg1 = arg1
      self.arg2 = arg2
      self.arg3 = arg3
    }
                  
    var body: some View {
      VStack {
          Text("\(count), \(arg1), \(arg2)")
          Button("Click me") {
            count += 1
          }
        }
    }
              
  }                  
  return Component(arg1: arg1, arg2: arg2, arg3: arg3)
}
```
