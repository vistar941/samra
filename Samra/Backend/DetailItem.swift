//
//  DetailItem.swift
//  Samra
//
//  Created by Serena on 21/02/2023.
// 

import Cocoa
import AssetCatalogWrapper

struct DetailItem: Hashable {
    /// The Primary Text, such as "Height"
    let primaryText: String
    
    /// The Secondary Text, such as the height itself in String form
    let secondaryText: String
    
    init(primaryText: String, secondaryText: String) {
        self.primaryText = primaryText
        self.secondaryText = secondaryText
    }
    
    init<T: CustomStringConvertible>(primaryText: String, secondaryText: T?, fallback: String = "Unknown") {
        self.primaryText = primaryText
        self.secondaryText = secondaryText?.description ?? fallback
    }
}

struct DetailItemSection: Hashable {
    let sectionHeader: String
    let items: [DetailItem]
    
    static func from(assetStorage: CUICommonAssetStorage) -> [DetailItemSection] {
        let toolSection = DetailItemSection(sectionHeader: "Authoring Tool", items: [
            DetailItem(primaryText: "Tool", secondaryText: assetStorage.authoringTool()),
            DetailItem(primaryText: "Version", secondaryText: String(cString: assetStorage.versionString())),
        ])
        
        let argumentsSection = DetailItemSection(sectionHeader: "Arguments", items: [
            DetailItem(primaryText: "Thinning Arguments", secondaryText: assetStorage.thinningArguments())
        ])
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, d MMM yyyy h:mm a"
        let date = Date(timeIntervalSince1970: TimeInterval(assetStorage.storageTimestamp()))
        
        let dateSection = DetailItemSection(sectionHeader: "Date", items: [
            DetailItem(primaryText: "Date", secondaryText: dateFormatter.string(from: date)),
            DetailItem(primaryText: "UNIX Timestamp", secondaryText: assetStorage.storageTimestamp())
        ])
        
        let coreUIVersionText = assetStorage.responds(to: #selector(CUICommonAssetStorage.coreuiVersion)) ? assetStorage.coreuiVersion().description : "Unknown"
        let coreUISection = DetailItemSection(sectionHeader: "Other", items: [
            DetailItem(primaryText: "CoreUI Version", secondaryText: coreUIVersionText),
            DetailItem(primaryText: "Schema Version", secondaryText: assetStorage.schemaVersion()),
        ])
        
        return [toolSection, argumentsSection, dateSection, coreUISection]
    }
    
    static func from(rendition: Rendition) -> [DetailItemSection] {
        let cuiRend = rendition.cuiRend
        let namedLookup = rendition.namedLookup
        
        let formatter = ByteCountFormatter()
        formatter.countStyle = .memory
        formatter.includesActualByteCount = true
        
        let diskSize = formatter.string(fromByteCount: Int64(cuiRend.srcData.count))
        
        let sizeOnDisk = DetailItem(primaryText: "Size On Disk", secondaryText: diskSize)
        var items: [DetailItemSection] = []

        switch rendition.type {
        case .namedGradient:
            items.append(DetailItemSection(sectionHeader: "Base Attributes", items: [
                DetailItem(primaryText: "Rendition Name", secondaryText: cuiRend.name()),
                DetailItem(primaryText: "Lookup Name", secondaryText: namedLookup.name),
                sizeOnDisk,
            ]))

            if let gradient = rendition.namedGradient {
                let stops = gradient.stops.enumerated().map { index, stop in
                    DetailItem(
                        primaryText: "Stop \(index + 1)",
                        secondaryText: "\(Self.colorDescription(stop.color)) @ \(Self.percentDescription(stop.location))"
                    )
                }

                items.append(DetailItemSection(sectionHeader: "Gradient Attributes", items: [
                    DetailItem(primaryText: "Start Point", secondaryText: Self.pointDescription(gradient.startPoint)),
                    DetailItem(primaryText: "End Point", secondaryText: Self.pointDescription(gradient.endPoint)),
                    DetailItem(primaryText: "Stops", secondaryText: gradient.stops.count),
                ] + stops))
            }

        case .rawData:
            items.append(DetailItemSection(sectionHeader: "Base Attributes", items: [
                DetailItem(primaryText: "Name", secondaryText: namedLookup.name),
                sizeOnDisk,
                DetailItem(primaryText: "Compression", secondaryText:cuiRend.bitmapEncoding())
            ]))
            var details : [DetailItem] = []
            if let data = cuiRend.data() {
                let size = formatter.string(fromByteCount: Int64(data.count))
                details.append(DetailItem(primaryText: "Data Length", secondaryText:size))

            }
            if let uti = cuiRend.utiType() {
                details.append(DetailItem(primaryText: "UTI", secondaryText:uti))
            }
            items.append(DetailItemSection(sectionHeader: "Data Attributes", items: details))

        case .color:
            items.append(DetailItemSection(sectionHeader: "Base Attributes", items: [
                DetailItem(primaryText: "Name", secondaryText: cuiRend.name()),
                sizeOnDisk,
            ]))
            let cgColor = cuiRend.cgColor().takeUnretainedValue()
            let nsColor = NSColor(cgColor:cgColor)?.usingColorSpace(.deviceRGB)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            nsColor?.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

            items.append(DetailItemSection(sectionHeader: "Color Attributes", items: [
                DetailItem(primaryText: "Red", secondaryText: Int(red * 255)),
                DetailItem(primaryText: "Green", secondaryText: Int(green * 255)),
                DetailItem(primaryText: "Blue", secondaryText: Int(blue * 255)),
                DetailItem(primaryText: "Alpha", secondaryText: "\(Int(alpha * 100))%"),
            ]))

        case .svg, .pdf:
            items.append(DetailItemSection(sectionHeader: "Base Attributes", items: [
                DetailItem(primaryText: "Rendition Name", secondaryText: cuiRend.name()),
                DetailItem(primaryText: "Lookup Name", secondaryText: namedLookup.name),
                sizeOnDisk,
            ]))
            var size = CGSizeZero
            switch rendition.type {
            case .svg:
                if let svgDoc = cuiRend.svgDocument() {
                    size = CGSVGDocumentGetCanvasSize(svgDoc)
                }
            case .pdf:
                if let pdfDoc = cuiRend.pdfDocument()?.takeUnretainedValue(), let page = pdfDoc.page(at:1) {
                    size = page.getBoxRect(.artBox).size
                }
            default:
                break
            }
            items.append(DetailItemSection(sectionHeader: "Dimensions", items: [
                DetailItem(primaryText: "Width", secondaryText: size.width),
                DetailItem(primaryText: "Height", secondaryText: size.height),
            ]))

        default:
            items.append(DetailItemSection(sectionHeader: "Base Attributes", items: [
                DetailItem(primaryText: "Rendition Name", secondaryText: cuiRend.name()),
                DetailItem(primaryText: "Lookup Name", secondaryText: namedLookup.name),
                sizeOnDisk,
                DetailItem(primaryText: "Compression", secondaryText:cuiRend.bitmapEncoding())
            ]))
            let size = cuiRend.unslicedSize()
            items.append(DetailItemSection(sectionHeader: "Dimensions", items: [
                DetailItem(primaryText: "Width", secondaryText: size.width),
                DetailItem(primaryText: "Height", secondaryText: size.height),
                DetailItem(primaryText: "Scale", secondaryText: cuiRend.scale())
            ]))
        }
        
        let key = namedLookup.key
        items.append(DetailItemSection(sectionHeader: "Rendition Information", items: [
            DetailItem(primaryText: "Display Gamut", secondaryText: Rendition.DisplayGamut(key)),
            DetailItem(primaryText: "Appearance", secondaryText: namedLookup.appearance),
            DetailItem(primaryText: "Idiom", secondaryText: Rendition.Idiom(key))
        ]))
        
        return items
    }

    private static func pointDescription(_ point: CGPoint) -> String {
        "\(Self.decimalDescription(point.x)), \(Self.decimalDescription(point.y))"
    }

    private static func percentDescription(_ value: CGFloat) -> String {
        "\(Int((value * 100).rounded()))%"
    }

    private static func colorDescription(_ color: CGColor) -> String {
        guard let nsColor = NSColor(cgColor: color)?.usingColorSpace(.deviceRGB) else {
            return "Unknown Color"
        }

        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        nsColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return "R \(Int(red * 255)), G \(Int(green * 255)), B \(Int(blue * 255)), A \(Int(alpha * 100))%"
    }

    private static func decimalDescription(_ value: CGFloat) -> String {
        let number = NSNumber(value: Double(value))
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 3
        formatter.minimumFractionDigits = 0
        return formatter.string(from: number) ?? value.description
    }
}
