import SwiftUI

extension Text {
    init(appLocalized resource: LocalizedStringResource) {
        self.init(verbatim: AppLocalization.string(resource))
    }
}
