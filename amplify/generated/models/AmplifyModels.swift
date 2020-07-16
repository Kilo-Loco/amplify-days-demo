// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "b7848c9b20e6f21a61854c404c0184ec"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Photo.self)
  }
}