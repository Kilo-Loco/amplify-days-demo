// swiftlint:disable all
import Amplify
import Foundation

public struct Photo: Model {
  public let id: String
  public var key: String
  public var isFeatured: Bool
  public var photographerId: String
  
  public init(id: String = UUID().uuidString,
      key: String,
      isFeatured: Bool,
      photographerId: String) {
      self.id = id
      self.key = key
      self.isFeatured = isFeatured
      self.photographerId = photographerId
  }
}