//
//  BlastOutputParser.swift
//  blast_parser
//
//  Created by João Varela on 13/07/2025.
//

class BlastOutputParser: FileParser{
	var hits = [BlastHit]()
	var bins = [BlastHitBin]()
	var hitsPerASV = 1
	let defaultReportSuffix = "blast-report.tsv"
	var taxonomyDatabase = "taxonomy_ncbi"
	var taxonomyTable = "taxonomy"
}
