//
//  KrakenReportLine.swift
//  blast_parser
//
//  Created by João Varela on 29/09/2024.
//

import Foundation

struct KrakenReportLine {
    var lineNumber = 0
    var percentage = 0.0
    var reads = 0
    var assignedReads = 0
    var rank:Rank!
    var hierarchy:Hierarchy!
    var taxID = 0
    
    init() {}
    
    func getLine() -> String {
        assert(rank != nil && hierarchy != nil,
               "Rank and hierarchy should not be nil")
        var result = "\(lineNumber)\t\(percentage)\t\(reads)\t\(assignedReads)\t"
        result += "\(rank.abbreviation)\t\(rank.variant)\t\(rank.taxonName)\t"
        result += "\(taxID)\t\(hierarchy.description)"
        return result
    }
}

extension KrakenReportLine: Equatable {
    static func == (lhs:KrakenReportLine, rhs:KrakenReportLine) -> Bool {
        return lhs.assignedReads == rhs.assignedReads
    }
    
    static func != (lhs:KrakenReportLine, rhs:KrakenReportLine) -> Bool {
        return lhs.assignedReads != rhs.assignedReads
    }
}

extension KrakenReportLine: Comparable {
    static func > (lhs:KrakenReportLine, rhs:KrakenReportLine) -> Bool {
        return lhs.assignedReads > rhs.assignedReads
    }
    
    static func < (lhs:KrakenReportLine, rhs:KrakenReportLine) -> Bool {
        return lhs.assignedReads < rhs.assignedReads
    }
}
