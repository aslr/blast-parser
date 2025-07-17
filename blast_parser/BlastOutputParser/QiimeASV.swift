//
//  QiimeASV.swift
//  blast_parser
//
//  Created by João Varela on 14/07/2025.
//

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

struct QiimeASV: CustomStringConvertible {
	let featureID: String
	let samples: [String]
	var taxonomy = [QiimeTaxonomy]()
    
    init(featureID: String, samples: [String], taxonomy:QiimeTaxonomy) {
		self.featureID = featureID
		self.samples = samples
        self.taxonomy.append(taxonomy)
	}
    
    init?(components:[String], taxonIndex:Int?) {
        let count = components.count
        guard count >= 4 else { return nil }
        self.featureID = components[0]
        let taxonIndex = taxonIndex ?? 1
        let sampleStartIndex = (taxonIndex == 1) ? 3 : 1
        let sampleEndIndex = (taxonIndex == 1) ? count-1 : count-3
        self.samples = Array(components[sampleStartIndex...sampleEndIndex])
        let taxonomy = QiimeTaxonomy(taxonomy: components[taxonIndex],
                                     confidence: components[taxonIndex + 1])
        self.taxonomy.append(taxonomy)
    }
    
    mutating func add(taxonomy:QiimeTaxonomy) {
        self.taxonomy.append(taxonomy)
    }
    
    var description: String {
        let samplesDescription = samples.joined(separator: "\t")
        let taxonomyDescription = taxonomy.map { $0.description }.joined(separator: "\t")
        return "\(featureID)\t\(taxonomyDescription)\t\(samplesDescription)"
    }
}
