// swiftlint:disable all
import Amplify
import Foundation

extension Photographer {
  // MARK: - CodingKeys 
   public enum CodingKeys: String, ModelKey {
    case id
    case photos
  }
  
  public static let keys = CodingKeys.self
  //  MARK: - ModelSchema 
  
  public static let schema = defineSchema { model in
    let photographer = Photographer.keys
    
    model.pluralName = "Photographers"
    
    model.fields(
      .id(),
      .hasMany(photographer.photos, is: .optional, ofType: Photo.self, associatedWith: Photo.keys.photographer)
    )
    }
}