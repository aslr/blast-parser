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
	let taxonomy: String
	let confidence: String
	
	var description: String {
		let samplesDescription = samples.joined(separator: "\t")
		return "\(featureID)\t\(taxonomy)\t\(confidence)\t\(samplesDescription)"
	}
    
	init(featureID: String, samples: [String], taxonomy: String, confidence: String) {
		self.featureID = featureID
		self.samples = samples
		self.taxonomy = taxonomy
		self.confidence = confidence.trimmingCharacters(in: .newlines)
	}
}

final class QiimeParser: FileParser {
	var lines = [QiimeASV]()
	func parse() throws -> [QiimeASV] {
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
		return QiimeASV(featureID: lineID, samples: samples, taxonomy: taxon, confidence: confidence)
	}
	
}
