//
//  KrakenASVBinArray.swift
//  blast_parser
//
//  Created by João Varela on 27/10/2024.
//

import Foundation

struct KrakenASVBinArray {
    private var bins = [KrakenASVBin]()
    
    mutating func append(asv:KrakenASV) {
        if let bin = match(asv: asv) {
            bin.append(asv: asv)
        } else {
            let isClassified = asv.taxonomy.taxID != 0
            let bin = KrakenASVBin(isClassified: isClassified,
                                   taxonomy: asv.taxonomy)
            bin.append(asv: asv)
            bins.append(bin)
        }
    }
    
    func getASVs(sequencesPerBin:Int = 10) -> [KrakenASV] {
        var result = [KrakenASV]()
        for bin in bins {
            result += bin.asvs(sequencesToReturn: sequencesPerBin)
        }
        return result
    }
    
    mutating func sort() {
        bins.sort(by: >)
    }
    
    private func match(asv:KrakenASV) -> KrakenASVBin? {
        for bin in bins {
            if asv.taxonomy == bin.taxonomy {
                return bin
            }
        }
        return nil
    }
}
