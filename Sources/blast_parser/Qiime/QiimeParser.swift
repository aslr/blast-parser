//
//  QiimeParser.swift
//  blast_parser
//
//  Created by Catarina Alexandre on 29/05/2025.
//
import Foundation
import ArgumentParser

final class QiimeParser: FileParser {
    /// Parses a Qiime2 ASV read counts table with the following columns:
    /// Feature ID, sample(s) counts, taxonomy, confidence (of the assignment)
    /// - Returns: An array of QiimeASVs
	func parse() throws -> [QiimeASV] {
        var lines = [QiimeASV]()
        var index = 0
        
        for line in readStream {
            if index == 0 {
                // validation
                let cleanLine = line.trimmingCharacters(in: .newlines)
                let header = cleanLine.replacingOccurrences(of: "-", with: "CN").components(separatedBy: "\t")
                guard header.contains("id"), header.contains("Taxon"),
                      header.contains("Confidence") else
                    { throw ValidationError("Invalid Qiime 2 ASV read counts file") }
                
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
