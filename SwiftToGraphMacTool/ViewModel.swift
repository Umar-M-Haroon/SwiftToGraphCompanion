//
//  ViewModel.swift
//  SwiftToGraphMacTool
//
//  Created by Umar Haroon on 3/8/23.
//

import Foundation
import GraphKit
import SwiftToGraph
import OrderedCollections
import SwiftSyntax
class ViewModel: ObservableObject {
    var graphCache: Cache<String, String>
    @Published
    var data: Data?
    @Published
    var progress = 0.0
    init() {
        let folderURLs = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        var graphFileURL = folderURLs[0]
        graphFileURL.appendPathComponent("graphs" + ".cache")
        do {
            let data = try JSONDecoder().decode(Cache<String, String>.self, from: Data(contentsOf: graphFileURL))
            graphCache = data
        } catch let error {
            graphCache = Cache<String, String>()
            print(error.localizedDescription)
        }
    }
    
    func render(allFiles: String, selectedLayout: DOTLayout) {
        if let dot = graphFor(files: allFiles) {
            DispatchQueue.global().async {
                let renderer = DOTRenderer(layout: selectedLayout)
                print(dot)
                self.write(dot: dot)
                
                renderer.render(dotString: dot, format: .pdf, options: .none, completion: { result in
                    switch result {
                    case .failure(let error):
                        print(error.localizedDescription)
                        print(error)
                    case .success(let data):
                        DispatchQueue.main.async {
                            self.progress += 0.05
                            self.data = data
                        }
                    }
                })
            }
            return
        }
        self.progress += 0.2
        guard var graph = try? SwiftParser().parse(source: allFiles) else { return }
        self.progress += 0.2
        var highlightedEdges: OrderedSet<GraphKit.Edge> = []
        graph.nodes
            .compactMap({$0 as? ParserNode})
            .filter({$0.type is FunctionCallExprSyntax})
            .forEach { caller in
                guard let funcCallSyntax = caller.type as? FunctionCallExprSyntax else { return }
                let args = funcCallSyntax.argumentList.compactMap({$0.label?.description}).joined(separator: "")
                guard let v = graph.nodes
                    .compactMap({$0 as? ParserNode})
                    .filter({$0.type is FunctionDeclSyntax})
                    .first(where: { called in
                        guard let funcDeclSyntax = called.type as? FunctionDeclSyntax else { return false }
                        let params = funcDeclSyntax.signature.input.parameterList.compactMap({$0.firstName?.text}).joined(separator: "")
                        return args == params && called.name == caller.name
                    }) else { return }
                //                        graph.nodes.compactMap({$0 as? ParserNode}).forEach({print($0.description)})
                graph.addDirectedEdge(u: caller.id, v: v.id)
                //                    graph4.removeNodeAndMoveEdges(id: caller.id, newV: v.id)
                graph.edges = OrderedSet(graph.edges.map { edge in
                    if edge.v == caller.id {
                        let newEdge = Edge(u: edge.u, v: v.id)
                        highlightedEdges.append(newEdge)
                        return newEdge
                    }
                    return edge
                })
                graph.removeNode(id: caller.id)
            }
        self.progress += 0.2
        let graphEdges = graph.edges.subtracting(highlightedEdges)
            .filter { edge in
                edge.u != edge.v
            }
        
        let edges = graphEdges.map({EdgeView(edge: $0, attributes: [], uDescription: graph[$0.u].description, vDescription: graph[$0.v].description)})
        let highlightedEdgeViews = highlightedEdges.map {
            EdgeView(edge: $0, attributes: [.init(key: EdgeAttributeKey.color, value: "red")], uDescription: graph[$0.u].description, vDescription: graph[$0.v].description)
        }
        let nodes = graph.nodes.filter { node in
            graph.edges.contains { edge in
                edge.u == node.id || edge.v == node.id
            }
        }
        let views = nodes.map({NodeView(node: $0, attributes: [])})
        let allViews: [any DOTView] = highlightedEdgeViews + edges + views
        let graphView = GraphView {
            allViews
        }
        let graphDOT = graphView.build().joined(separator: "\n")
        print(graphDOT)
        write(dot: graphDOT)
        addToCache(files: allFiles, graph: graphDOT)
        DispatchQueue.global().async {
            let renderer = DOTRenderer(layout: selectedLayout)
            renderer.render(view: graphView, format: .pdf, options: .none, completion: { result in
                switch result {
                case .failure(let error):
                    print(error.localizedDescription)
                    print(error)
                case .success(let data):
                    DispatchQueue.main.async {
                        self.progress += 0.4
                        self.data = data
                    }
                }
            })
        }
    }
    
    func addToCache(files: String, graph: String) {
        graphCache.insert(files, for: graph)
        do {
            try graphCache.saveToDisk(with: "graphs")
        } catch let error {
            print(error.localizedDescription)
        }
    }
    
    func graphFor(files: String) -> String? {
        return graphCache.value(for: files)
    }
    
    func write(dot: String) {
        let paths = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        let filename = documentsDirectory.appendingPathComponent("output.dot")
        print("writing to: ", filename.absoluteString)
        do {
            try dot.write(to: filename, atomically: true, encoding: String.Encoding.utf8)
        } catch let e {
            print(e)
            // failed to write file – bad permissions, bad filename, missing permissions, or more likely it can't be converted to the encoding
        }
    }
}
