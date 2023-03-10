//
//  ContentView.swift
//  SwiftToGraphMacTool
//
//  Created by Umar Haroon on 2/22/23.
//

import SwiftUI
import SwiftToGraph
import GraphKit
import OrderedCollections
import SwiftSyntax
import UniformTypeIdentifiers
extension DOTLayout: CaseIterable {
    public static var allCases: [DOTLayout] = [.neato, .dot, .circo, .fdp, .nop, .nop1, .nop2, .osage, .patchwork, .twopi, .sfdp]
}
struct ContentView: SwiftUI.View {
    @State var fileURL: URL?
    @State var files: [URL] = []
    @State var selectedFiles: [Bool] = []
    @State var text: String?
    @State var selectedLayout: DOTLayout = .dot
    @StateObject var model: ViewModel
    @State var progress: Double = 0
    var body: some SwiftUI.View {
        NavigationSplitView(sidebar: {
            List(0..<self.files.count, id: \.self, selection: self.$selectedFiles) { i in
                Toggle(isOn: self.$selectedFiles[i]) {
                    Text(self.files[i].relativePath)
                }
            }
            .navigationSplitViewStyle(BalancedNavigationSplitViewStyle())
            List(DOTLayout.allCases, id: \.self, selection: $selectedLayout) { layout in
                Text(layout.rawValue)
            }
        }, detail: {
            if progress > 0 {
                ProgressView("Loading", value: progress, total: 1.0)
            }
            Button {
                let allFiles: String = self.files
                    .enumerated()
                    .filter({ (i, _) in
                        selectedFiles[i]
                    })
                    .compactMap({ (_, file) in
                        try? String(contentsOf: file)
                    })
                    .reduce("", +)
                model.render(allFiles: allFiles, selectedLayout: selectedLayout)
            } label: {
                Text("Build")
            }
            if let pdfData = model.data {
                PDFRenderer(data: pdfData)
            }
        })
        .toolbar {
            Button {
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = true
                if panel.runModal() == .OK {
                    if let url = panel.url {
                        self.fileURL = panel.url
                        var allSymbols = FileManager.default
                            .enumerator(at: url, includingPropertiesForKeys: nil)?
                            .compactMap { $0 as? URL }
                            .filter { $0.hasDirectoryPath == false }
                            .filter { $0.pathExtension == "swift" }
                        files = allSymbols ?? []
                        self.selectedFiles = [Bool](repeating: true, count: files.count)
                    }
                }
            } label: {
                Label("Select Folder", systemImage: "folder")
            }
            
        }
    }
    func write() {
        guard let text = self.text else { return }
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let filename = documentsDirectory.appendingPathComponent("output.dot")
        
        do {
            try text.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch let e {
            print(e)
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static let urls: [URL] = [
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Constants.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/SubscriptionManager.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/GameFormatter.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Favorites.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/SettingsData.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/LiveSportActivityAttributes.swift,")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/UserDefaultStorage.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/NetworkErrors.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/LocalNotificationManager.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/DateFormatters.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/LiveActivityStatusView.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Model/Teams+Extensions.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Model/Cache.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Model/GameManager.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Model/GameViewModel.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/NetworkHandler.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/SportsCalApp.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/AppDelegate.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Date+Extensions.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/PickSportPage.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/OnboardingPage.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/DummySubscriptionOptionView.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/CompetitionView.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/SubscriptionSheet.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/SettingsView.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/NotifyButton.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/IndividualTeamView.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/FavoriteButtonView.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/CalendarButton.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/GameScoreView.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/CalendarRepresentable.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/SubscriptionPage.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/SportsFilterView.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/MiniSubscriptionPage.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/LiveAnimatedView.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/UpcomingGameView.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/LiveActivityButton.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/ContentView.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/SportsTint.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/Confetti.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/CompetitionPage.swift")!,
        URL(string: "file:///Users/umar/Developer/SportsCal/Shared/Views/SportsSelectView.swift")!,
    ]
    
    static var previews: some SwiftUI.View {
        ContentView(files: urls, selectedFiles: [Bool](repeating: true, count: urls.count), model: ViewModel())
    }
}
