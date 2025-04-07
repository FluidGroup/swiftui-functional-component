import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension FunctionDeclSyntax {
  struct BodyComponents {
    let stateDeclarations: [String]
    let bindingDeclarations: [String]
    let temporaryDeclarations: [String]
    let viewBody: [String]
  }

  struct InitializerComponent {
    let name: String
    let assignments: String
    let type: String
  }

  func extractBodyComponents() -> BodyComponents {
    guard let body = self.body else {
      fatalError("Function body is required")
    }

    var stateDeclarations: [String] = []
    var bindingDeclarations: [String] = []
    var temporaryDeclarations: [String] = []
    var viewBody: [String] = []

    for statement in body.statements {
      let statementText = statement.trimmed.description

      if statementText.contains("@State") {
        stateDeclarations.append(statementText)
      } else if statementText.contains("@Binding") {
        bindingDeclarations.append(statementText)
      } else if statementText.contains("var ") || statementText.contains("let ")
        || statementText.contains("unowned let") || statementText.contains("weak var")
      {
        temporaryDeclarations.append(statementText)
      } else {
        viewBody.append(statementText)
      }
    }

    return BodyComponents(
      stateDeclarations: stateDeclarations,
      bindingDeclarations: bindingDeclarations,
      temporaryDeclarations: temporaryDeclarations,
      viewBody: viewBody
    )
  }

  var initializerComponents: [InitializerComponent] {
    let parameters = self.signature.parameterClause.parameters
    return parameters.map { param in
      let name = param.secondName?.text ?? param.firstName.text
      let type = param.type.description.trimmingCharacters(in: .whitespaces)
      return InitializerComponent(
        name: name,
        assignments: "self.\(name) = \(name)",
        type: type
      )
    }
  }
}

public struct ViewComponentMacro: BodyMacro {

  public static var formatMode: FormatMode {
    .disabled
  }

  public static func expansion(
    of node: AttributeSyntax,
    providingBodyFor declaration: some DeclSyntaxProtocol,
    in context: some MacroExpansionContext
  ) throws -> [CodeBlockItemSyntax] {

    guard let functionDecl = declaration.as(FunctionDeclSyntax.self) else {
      fatalError("ViewComponentMacro can only be applied to function declarations.")
    }

    // 関数名を取得
    let functionName = functionDecl.name.text

    // イニシャライザのコンポーネントを取得
    let initComponents = functionDecl.initializerComponents

    // ボディのコンポーネントを取得
    let components = functionDecl.extractBodyComponents()

    let initBlock = """
    init(\(initComponents.map { "\($0.name): \($0.type)" }.joined(separator: ", "))) {
    \(initComponents.map { $0.assignments }.joined(separator: "\n").indented(1))
    }
    """
    
    let bodyBlock = """
    var body: some View {
    \(components.viewBody.joined(separator: "\n").indented(1))
    }
    """
    
    let component = """
    struct Component: View {
      
    \(initComponents.map { "let \($0.name): \($0.type.replacingOccurrences(of: "@escaping", with: "").trimmingCharacters(in: .whitespaces))" }.joined(separator: "\n").indented(1))
    
    \(components.stateDeclarations.joined(separator: "\n").indented(1))
    
    \(components.bindingDeclarations.joined(separator: "\n").indented(1))
      
    \(initBlock.indented(1))
    
    \(components.temporaryDeclarations.joined(separator: "\n"))
                    
    \(bodyBlock.indented(1))
                
    }
    """
    // 新しいボディを生成
    let newBody = """
      \(component.indented(1))                  
      return Component(\(initComponents.map { "\($0.name): \($0.name)" }.joined(separator: ", ")))
      """

    return [
      CodeBlockItemSyntax(
        item:
          .expr(
            ExprSyntax(stringLiteral: newBody)
              .formatted(
              using: .init(
                indentationWidth: .spaces(2), initialIndentation: .spaces(0), viewMode: .all)
            ).cast(
              ExprSyntax.self
            )
          )
      )
    ]
  }
}

extension String {
  consuming func indented(_ level: Int) -> String {
    let indent = String(repeating: " ", count: level * 2)
    return self.split(separator: "\n").map { "\(indent)\($0)" }.joined(separator: "\n")
  }
}

@main
struct FunctionalViewComponentPlugin: CompilerPlugin {
  let providingMacros: [Macro.Type] = [
    ViewComponentMacro.self
  ]
}
