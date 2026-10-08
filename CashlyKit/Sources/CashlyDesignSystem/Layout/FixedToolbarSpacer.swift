import SwiftUI

public struct FixedToolbarSpacer: ToolbarContent {
    public init() {}

    public var body: some ToolbarContent {
        #if os(visionOS)
            ToolbarItem { EmptyView() }
        #else
            ToolbarSpacer(.fixed)
        #endif
    }
}
