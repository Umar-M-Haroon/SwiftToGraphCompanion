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
struct ContentView: SwiftUI.View {
    @State var filename = "Filename"
    @State var fileURL: URL?
    @State var files: [URL] = []
    @State var selectedFiles: [Bool] = []
    var body: some SwiftUI.View {
        VStack {
            Text(filename)
            Button("select File"){
                let panel = NSOpenPanel()
                panel.allowsMultipleSelection = false
                panel.canChooseDirectories = true
                if panel.runModal() == .OK {
                    if let url = panel.url {
                        self.filename = panel.url?.lastPathComponent ?? "<none>"
                        self.fileURL = panel.url
                        let allSymbols = FileManager.default
                            .enumerator(at: url, includingPropertiesForKeys: nil)?
                            .compactMap { $0 as? URL }
                            .filter { $0.hasDirectoryPath == false }
                            .filter { $0.pathExtension == "swift" }
                        files = allSymbols ?? []
                        self.selectedFiles = [Bool](repeating: true, count: files.count)
                    }
                }
            }
            List(0..<self.files.count, id: \.self, selection: self.$selectedFiles) { i in
                Toggle(isOn: self.$selectedFiles[i]) {
                    Text(self.files[i].description)
                }
            }
            Button("create graph") {
                do {
                    let allFiles: String = self.files
                        .compactMap({
                            try? String(contentsOf: $0)
                        })
                        .reduce("", +)
                    guard var graph = try? SwiftParser().parse(source: allFiles) else { return }
                    let highlightedEdges = OrderedSet(graph.edges.filter { edge in
                        guard let uNode = graph[edge.u] as? ParserNode,
                              let vNode = graph[edge.v] as? ParserNode else { return false }
                        return uNode.type is FunctionCallExprSyntax && vNode.type is FunctionDeclSyntax ||  vNode.type is FunctionCallExprSyntax && uNode.type is FunctionDeclSyntax
                    })
                    let graphEdges = graph.edges.subtracting(highlightedEdges)
                    
                    let edges = graphEdges.flatMap({EdgeView(edge: $0, attributes: [], uDescription: graph[$0.u].description, vDescription: graph[$0.v].description)})
                    let highlightedEdgeViews = highlightedEdges.flatMap {
                        EdgeView(edge: $0, attributes: [.init(key: EdgeAttributeKey.color, value: "red")], uDescription: graph[$0.u].description, vDescription: graph[$0.v].description)
                    }
                    let nodes = graph.nodes.filter { node in
                        graph.edges.contains { edge in
                            edge.u == node.id || edge.v == node.id
                        }
                    }
                    let views = nodes.flatMap({NodeView(node: $0, attributes: [])})
//                        .removeAll(where: {graph.edges.first(where: { edge in
//                            edge.u == $0.id || edge.v == $0.id
//                        }) == nil})
                    let allViews: [any GraphKit.View] = views + edges + highlightedEdgeViews
                    let graphView = GraphView {
                        allViews
                    }
                    print(graphView.build().joined(separator: "\n"))
                } catch {
                    
                }
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some SwiftUI.View {
        ContentView()
    }
}
