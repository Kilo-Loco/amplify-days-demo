// swiftlint:disable all
import Amplify
import Foundation

// Contains the set of classes that conforms to the `Model` protocol. 

final public class AmplifyModels: AmplifyModelRegistration {
  public let version: String = "b56e40f0aa51afaecb19ca140d8c5050"
  
  public func registerModels(registry: ModelRegistry.Type) {
    ModelRegistry.register(modelType: Photo.self)
    ModelRegistry.register(modelType: Photographer.self)
  }
}