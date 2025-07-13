//
//  QiimeParser.swift
//  blast_parser
//
//  Created by Catarina Alexandre on 29/05/2025.
//
import Foundation

//parses Qiime2 merged.tsv file

struct QiimeASV: CustomStringConvertible {
	let featureID: String
	let samples: [String]
	var taxonomy = [QiimeTaxonomy]()
    
    init(featureID: String, samples: [String], taxonomy:QiimeTaxonomy) {
		self.featureID = featureID
		self.samples = samples
        self.taxonomy.append(taxonomy)
	}
    
    var description: String {
        let samplesDescription = samples.joined(separator: "\t")
        let taxonomyDescription = taxonomy.map { $0.description }.joined(separator: "\t")
        return "\(featureID)\t\(taxonomyDescription)\t\(samplesDescription)"
    }
}

struct QiimeTaxonomy: CustomStringConvertible {
    let taxonomy: String
    let confidence: String
    
    init(taxonomy: String, confidence: String) {
        self.taxonomy = taxonomy
        self.confidence = confidence.trimmingCharacters(in: .newlines)
    }
    
    var description: String {
        return "\(taxonomy)\t\(confidence)"
    }
}

final class QiimeParser: FilesParser {
	var lines = [QiimeASV]()
	func parse() throws -> [QiimeASV] {
        for parser in self.parsers {
            
        }
		var index = 0
		for line in readStream {
			if index == 0 {
				// validation
				let cleanLine = line.trimmingCharacters(in: .newlines)
				let header = cleanLine.replacingOccurrences(of: "-", with: "CN").components(separatedBy: "\t")
				guard header.contains("id"), header.contains("Taxon"),
					  header.contains("Confidence") else
					{ throw RuntimeError("Invalid Qiime 2 merged file") }
				
				let asv = getASV(line: header, count: header.count)
				lines.append(asv)
			} else if index > 1 {
				let items = line.components(separatedBy: "\t")
				let asv = getASV(line: items, count: items.count)
				lines.append(asv)
			}
			index += 1
		}
		return lines
	}
	
	private func getASV(line:[String], count:Int) -> QiimeASV {
		let lineID = line[0].trimmingCharacters(in: .whitespaces)
		let samples = Array(line[1..<(count-2)]).map { $0.trimmingCharacters(in: .whitespaces)}
		let taxon = line[count - 2].trimmingCharacters(in: .whitespaces)
		let confidence = line[count-1].trimmingCharacters(in: .whitespaces)
        let taxonomy = QiimeTaxonomy(taxonomy: taxon, confidence: confidence)
		return QiimeASV(featureID: lineID, samples: samples, taxonomy: taxonomy)
	}
}
