//
//  PDFRenderer.swift
//  SwiftToGraphMacTool
//
//  Created by Umar Haroon on 3/2/23.
//

import SwiftUI
import AppKit
import PDFKit

struct PDFRenderer: NSViewRepresentable {
    var data: Data
    func makeNSView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = PDFDocument(data: data)
        return view
    }
    
    func updateNSView(_ nsView: PDFView, context: Context) {
        nsView.document = PDFDocument(data: data)
    }
    
    typealias NSViewType = PDFView
    

}
