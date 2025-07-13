//
//  Blast_Parser.swift
//  blast_parser
//
//  Created by João Varela on 31/08/2024.
//

import Foundation
import ArgumentParser

@main

// root command
struct BlastParser: ParsableCommand {
static let configuration = CommandConfiguration(
        abstract: """
            Imports an NCBI ranked taxonomy dump file and exports it into a PostGresSQL \
            database and then retrieves and parses the taxonomy information to populate \
            the BLAST results with the respective taxa.
            """,
        usage: "blast_parser <subcommand>",
        version: "0.3.0",
		subcommands: [Import.self, Export.self, Parse.self, Merge.self, MergeQiime.self],
        defaultSubcommand: Import.self
    )
}

// common options
struct Options:ParsableArguments {
}

extension BlastParser {
	struct Import: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Imports an NCBI ranked taxonomy dump file into a CSV file.",
			usage: "blast_parser import --input <input> [--output <output>]",
			aliases: ["imp"]
		)
		
		@OptionGroup var options: Options
		
		@Option(name: [.short, .customLong("input")],
				help: "Path to rankedlineage.dmp file to be imported.")
		var inputFile:String
		
		@Option(name: [.short, .customLong("output")],
				help: "Path to the output CSV file, which will be overwritten if it already exists.")
		var outputFile: String? = nil
		
		mutating func run() throws {
			let inputURL = URL(fileURLWithPath: inputFile)
			guard FileManager.default.fileExists(atPath: inputFile) else {
				throw RuntimeError("Input file at \(inputFile) not found.")
			}
			
			var outputPath = String()
			if outputFile == nil {
				let oldFilenameURL = inputURL.deletingPathExtension()
				outputPath = oldFilenameURL.appendingPathExtension("csv").path
			} else {
				outputPath = outputFile!
			}
			
			let database = Database(path: inputFile, outputPath: outputPath)
			database.parse()
		}
	}
	
	struct Export: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Exports the imported CSV file into a local PostGresSQL database.",
			usage: "blast_parser export --input <input> --database <database> [--table <table>]",
			aliases: ["exp"]
		)
		
		@OptionGroup var options: Options
		
		@Option(name: [.short, .customLong("input")],
				help: "Path to rankedlineage.csv file to be imported.")
		var inputFile:String
		
		@Option(name: [.short, .customLong("database")],
				help: "Name of the database to which rankedlineage.csv file will be exported.")
		var database:String
		
		@Option(name: [.short, .customLong("table")],
				help: "Name of the table that will be created in the database. [OPTIONAL]")
		var table:String?
		
		mutating func run() throws {
			let database = SQLDatabase(database: database, table: table)
			database.createDatabase()
			database.importDatabase(pathToCSVFile: inputFile)
		}
	}
	
	struct Parse: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Parses a Kraken2 counts report to determine which sequences should be validated by BLASTN.",
			usage: "blast_parser parse --report <report> --classification <classification> --sequences <sequences> [--output <output>] [--asvformart <asvformat>] [--max-sequences-per-bin <max-sequences-per-bin>]",
			aliases: ["prs"]
		)
		
		@OptionGroup var options: Options
		
		@Option(name: [.short, .customLong("report")],
				help: "Path to Kraken2 counts report to be parsed.")
		var report:String
		
		@Option(name: [.short, .customLong("classification")],
				help: "Path to the Kraken2 taxonomic assignment file.")
		var classification:String
		
		@Option(name: [.short, .customLong("asvformat")],
				help: "ASV format file. It can be either standard (5 columns: U/C sequenceID taxon(taxID) length LCA) or epi2me (6 columns: U/C sequenceID taxID length LCA lineage). [OPTIONAL, default = standard]")
		var asvFormat:String?
		
		@Option(name: [.short, .customLong("sequences")],
				help: "Path to the sample sequences file. It can be either a fasta file with the .fa or .fasta extension or a fastq file with the .fastq extension.")
		var sequences:String
		
		@Option(name: [.short, .customLong("output")],
				help: "Name of the output file. [OPTIONAL]")
		var outputFile:String?
		
		@Option(name: [.short, .customLong("max-sequences-per-bin")],
				help: "Maximum number of sequences per bin. [OPTIONAL, default = 10]")
		var maxSequencesPerBin:Int?
		
		mutating func run() throws {
			guard let parser = KrakenParser(report: report,
											classification: classification,
											sequences: sequences) else {
				throw RuntimeError("Invalid path to an input file.")
			}
			
			if let sequencesPerBin = maxSequencesPerBin {
				parser.sequencesPerBin = sequencesPerBin
			}
			
			try parser.parseReport()
			try parser.printReport(to: outputFile)
			try parser.parseASVs(asvFormat: asvFormat)
			try parser.printParsedClassification(to: outputFile)
			try parser.parseSequences()
			try parser.printParsedSequences(to: outputFile)
		}
	}
	
	struct Merge: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Merges a Kraken2 counts report with the best hits of a BLAST search.",
			usage: "blast_parser merge --asvs <asvs> --blasthits <blasthits> [--parsed-taxonomy <parsed-taxonomy>] [--output <output>] [--hits-per-asv <hits-per-asv>] [--sort <sort>]",
			aliases: ["mrg"]
		)
		
		@OptionGroup var options: Options
		
		@Option(name: [.short, .customLong("asvs")],
				help: "Path to the Kraken2 counts output file of the parse subcommand.")
		var asvs:String
		
		@Option(name: [.short, .customLong("blasthits")],
				help: "Path to the BLAST output file using a 13 columns format with following order: qsedid pident length evalue bitscore score nident saccver stitle qcovs staxids sscinames sskingdoms.")
		var blasthits:String
		
		@Option(name: [.short, .customLong("parsed-taxonomy")],
				help: "Path to the Kraken2 output file of the parse subcommand containing a parsed hierarchical taxonomy. [OPTIONAL]")
		var parsedTaxonomy:String?
		
		@Option(name: [.short, .customLong("output")],
				help: "Name of the output file. [OPTIONAL]")
		var outputFile:String?
		
		@Option(name: [.customLong("hits-per-asv")],
				help: "Maximum number of sequences per bin. [OPTIONAL, default = 1]")
		var hitsPerAsv:Int?
		
		@Option(name: [.short, .customLong("sort")],
				help: "Sorting order of the output file, which can be either pident, bitscore or evalue. [OPTIONAL, default = bitscore]")
		var sort:String?
		
		mutating func run() throws {
			guard let parser = BlastKrakenOutputParser(path: blasthits,
													   asvs: asvs,
													   taxonomy: parsedTaxonomy)
			else {
				throw RuntimeError("Could not find a valid Kraken2 counts file to be merged with the BLAST hits file.")
			}
			
			if let hitsPerAsv = self.hitsPerAsv {
				parser.hitsPerASV = hitsPerAsv
			}
			
			if let sort = self.sort {
				if let criterion = BlastHit.SortCriterion(rawValue: sort) {
					try parser.parse(criterion: criterion)
				} else {
					throw RuntimeError("Wrong criterion for sorting the output file. Please use either pident, bitscore or evalue.")
				}
			} else {
				try parser.parse()
			}
			
			try parser.print(to: outputFile)
		}
	}
	struct MergeQiime: ParsableCommand {
		static let configuration = CommandConfiguration(
			abstract: "Merges a Qiime2 merge.tsv file with the best hits of a BLAST search.",
			usage: "blast_parser merge-qiime --asvs <asvs> --blasthits <blasthits> [--output <output>] [--hits-per-asv <hits-per-asv>] [--sort <sort>]",
			aliases: ["mrgq"] )
		
		@OptionGroup var options: Options
		
		@Option(name: [.short, .customLong("asvs")],
				help: "Path to a table file generated by Qiime2 containing ASVs and their respective read counts and taxonomic classification.")
		var asvs:String
		
		@Option(name: [.short, .customLong("blasthits")],
				help: "Path to the BLAST output file using a 13 columns format with following order: qsedid pident length evalue bitscore score nident saccver stitle qcovs staxids sscinames sskingdoms.")
		var blasthits:String
		
		
		@Option(name: [.short, .customLong("output")],
				help: "Name of the output file. [OPTIONAL, default = (original name)_output.tsv]")
		var outputFile:String? = nil
		
		@Option(name: [.customLong("hits-per-asv")],
				help: "Maximum number of sequences per bin. [OPTIONAL, default = 1]")
		var hitsPerAsv:Int?
		
		@Option(name: [.short, .customLong("sort")],
				help: "Sorting order of the output file, which can be either pident, bitscore or evalue. [OPTIONAL, default = bitscore]")
		var sort:String?
		
		
		mutating func run() throws {
			guard let parser = BlastQiimeOutputParser(path: blasthits, asvs: asvs)
			else {
				throw RuntimeError("Could not find a valid Qiime 2 file to be merged with the BLAST hits file.")
			}
			
			if let hitsPerAsv = self.hitsPerAsv {
				parser.hitsPerASV = hitsPerAsv
			}
			
			if let sort = self.sort {
				if let criterion = BlastHit.SortCriterion(rawValue: sort) {
					try parser.parse(criterion: criterion)
				} else {
					throw RuntimeError("Wrong criterion for sorting the output file. Please use either pident, bitscore or evalue.")
				}
			} else {
				try parser.parse()
			}
			
			//sets default name
			if outputFile == nil{
				let fileName = URL(fileURLWithPath: asvs).deletingPathExtension().lastPathComponent
				outputFile = "\(fileName)_output.tsv"
			}
		
			try parser.print(outputFile!)
		}
	}
}



