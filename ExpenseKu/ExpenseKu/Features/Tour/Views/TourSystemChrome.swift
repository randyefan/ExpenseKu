//
//  TourSystemChrome.swift
//  ExpenseKu
//
//  Where iOS draws the chrome the tour points at but cannot measure: toolbar items, the
//  search field the minimized search expands into, and the Insights tab. Toolbar content reports its frame
//  in the bar's own space, and the search field and tabs report nothing, so these are
//  measured on an iPhone 18 Pro (iOS 27), from the trailing edge and the safe area.
//

import CoreGraphics

enum TourSystemChrome {
    private static let barItem: CGFloat = 44
    private static let barCentre: CGFloat = 22

    static func frame(for target: TourTarget, size: CGSize, safeTop: CGFloat) -> TourTargetFrame? {
        switch target {
        case .addExpense: barItem(centreFromTrailing: 94, size: size, safeTop: safeTop)
        case .searchButton: barItem(centreFromTrailing: 40, size: size, safeTop: safeTop)
        case .planOptions: barItem(centreFromTrailing: 151, size: size, safeTop: safeTop)
        case .readReceipt: barItem(centreFromTrailing: 40, size: size, safeTop: safeTop)
        case .searchField:
            TourTargetFrame(rect: CGRect(x: 16, y: safeTop, width: size.width - 16 - 74, height: barItem),
                            radius: barItem / 2)
        case .insightsTab:
            TourTargetFrame(rect: CGRect(x: size.width / 2 - 48, y: size.height - 77, width: 96, height: 60),
                            radius: 30)
        default: nil
        }
    }

    private static func barItem(centreFromTrailing: CGFloat, size: CGSize, safeTop: CGFloat) -> TourTargetFrame {
        TourTargetFrame(rect: CGRect(x: size.width - centreFromTrailing - barItem / 2, y: safeTop + barCentre - barItem / 2,
                                     width: barItem, height: barItem),
                        radius: barItem / 2)
    }
}
