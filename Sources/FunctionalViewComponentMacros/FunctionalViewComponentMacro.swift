import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

extension FunctionDeclSyntax {
  struct BodyComponents {
    let stateDeclarations: [VariableDeclSyntax]
    let bindingDeclarations: [VariableDeclSyntax]
    let temporaryDeclarations: [VariableDeclSyntax]
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

    var stateDeclarations: [VariableDeclSyntax] = []
    var bindingDeclarations: [VariableDeclSyntax] = []
    var temporaryDeclarations: [VariableDeclSyntax] = []
    var viewBody: [String] = []

    for statement in body.statements {
      
      if let variableDecl = statement.item.as(VariableDeclSyntax.self) {
      
        for attribute in variableDecl.attributes {
          if attribute.as(AttributeSyntax.self)?.kind == AttributeSyntax.init(stringLiteral: "@State").kind {
            stateDeclarations.append(variableDecl)
          } else if attribute.as(AttributeSyntax.self)?.attributeName.description == "Binding" {
            bindingDeclarations.append(variableDecl)
          } else {
            temporaryDeclarations.append(variableDecl)
          }            
        }
                      
      } else {
        viewBody.append(statement.trimmed.description)
      }
    }

    return BodyComponents(
      stateDeclarations: stateDeclarations,
      bindingDeclarations: bindingDeclarations,
      temporaryDeclarations: temporaryDeclarations,
      viewBody: viewBody
    )
  }

  func initializerComponents() -> [InitializerComponent] {
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

    let initComponents = functionDecl.initializerComponents()

    let bodyComponents = functionDecl.extractBodyComponents()

    let initBlock = """
    init(\(initComponents.map { "\($0.name): \($0.type)" }.joined(separator: ", "))) {
    \(initComponents.map { $0.assignments }.joined(separator: "\n").indented(1))
    }
    """
    
    let bodyBlock = """
    var body: some View {
    \(bodyComponents.viewBody.joined(separator: "\n").indented(1))
    }
    """
        
    let component = """
    struct Component: View {
      
    \(bodyComponents.temporaryDeclarations.map { $0.trimmed.description }.joined(separator: "\n"))
    
    \(initComponents.filter { c in bodyComponents.temporaryDeclarations.contains { $0.bindings.contains { $0.pattern == c.name } } }.map { "let \($0.name): \($0.type.replacingOccurrences(of: "@escaping", with: "").trimmingCharacters(in: .whitespaces))" }.joined(separator: "\n").indented(1))
    
    \(bodyComponents.stateDeclarations.map { $0.trimmed.description }.joined(separator: "\n").indented(1))
    
    \(bodyComponents.bindingDeclarations.map { $0.trimmed.description }.joined(separator: "\n").indented(1))
      
    \(initBlock.indented(1))
    
                    
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

extension VariableDeclSyntax {
  
}
