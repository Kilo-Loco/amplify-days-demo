// swiftlint:disable all
import Amplify
import Foundation

public struct Photo: Model {
  public let id: String
  public var key: String
  public var isFeatured: Bool
  public var photographer: Photographer?
  
  public init(id: String = UUID().uuidString,
      key: String,
      isFeatured: Bool,
      photographer: Photographer? = nil) {
      self.id = id
      self.key = key
      self.isFeatured = isFeatured
      self.photographer = photographer
  }
}