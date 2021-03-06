import Vapor
import Leaf

public final class Provider: Vapor.Provider {
  public init(config: Config) throws {}

  public func boot(_ drop: Droplet) {
    let stem = (drop.view as? LeafRenderer)?.stem
    let tags: [Tag] = [ErrorsForField(), IfFieldHasErrors(), LabelForField(), LoopErrorsForField(), ValueForField()]
    tags.forEach {
      stem?.register($0)
    }
  }

  public func beforeRun(_ drop: Droplet) {} // Remove when able
}
