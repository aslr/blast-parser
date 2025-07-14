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
    
    init(components:[String]) {
        let count = components.count
        self.featureID = components[0]
        self.samples = Array(components[1..<count-2])
        let taxonomy = QiimeTaxonomy(taxonomy: components[count-2], confidence:                             components[count-1])
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
