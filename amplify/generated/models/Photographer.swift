// swiftlint:disable all
import Amplify
import Foundation

public struct Photographer: Model {
  public let id: String
  public var photos: List<Photo>?
  
  public init(id: String = UUID().uuidString,
      photos: List<Photo>? = []) {
      self.id = id
      self.photos = photos
  }
}