//
//  KrakenASVBin.swift
//  blast_parser
//
//  Created by João Varela on 27/10/2024.
//

import Foundation

final class KrakenASVBin {
    let isClassified:Bool
    let taxonomy:KrakenASVTaxonomy
    private var asvs = [KrakenASV]()
    
    var readCount:Int {
        return asvs.count
    }
    
    init(isClassified: Bool, taxonomy:KrakenASVTaxonomy) {
        self.isClassified = isClassified
        if isClassified {
            self.taxonomy = taxonomy
        } else {
            self.taxonomy = KrakenASVTaxonomy()
        }
    }
    
    func append(asv:KrakenASV) {
        asvs.append(asv)
    }
    
    func asvs(sequencesToReturn:Int = 10) -> [KrakenASV] {
        // sort asvs by descending sequence size
        asvs.sort(by: >)
        
        // return the first sequencesToReturn but remove duplicates
        var result = [KrakenASV]()
        for asv in asvs {
            if result.contains(asv) == false {
                result.append(asv)
                guard result.count < sequencesToReturn else { break }
            }
        }
        
        // hack to mutate a struct by using indices
        let count = asvs.count
        for index in result.indices {
            result[index].assignedReads = count
        }
        return result
    }
}

extension KrakenASVBin: Equatable {
    static func == (lhs:KrakenASVBin, rhs:KrakenASVBin) -> Bool {
        return lhs.taxonomy == rhs.taxonomy
    }
    
    static func != (lhs:KrakenASVBin, rhs:KrakenASVBin) -> Bool {
        return lhs.taxonomy != rhs.taxonomy
    }
}

extension KrakenASVBin: Comparable {
    static func > (lhs:KrakenASVBin, rhs:KrakenASVBin) -> Bool {
        return lhs.readCount > rhs.readCount
    }
    
    static func < (lhs:KrakenASVBin, rhs:KrakenASVBin) -> Bool {
        return lhs.readCount < rhs.readCount
    }
}


