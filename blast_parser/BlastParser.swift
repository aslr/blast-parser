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
            blast_parser is a bioinformatic tool that parses Qiime2 output files for Illumina short reads or Kraken2 or minimap2 output files for Nanopore long reads. It then merges this output with the output of NCBI blastn+ tool, producing a full taxonomical lineage from a local PostgresSQL database imported from the NCBI ranked taxonomy dump file available at the NCBI FTP server inside the new_taxonomy folder.
            """,
        usage: "blast_parser <subcommand>",
        version: "0.5.1",
        subcommands: [Import.self, Export.self, Parse.self, Merge.self, MergeQiime.self, ParseMinimap.self],
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
			abstract: "Merges one or more tab-separated Qiime2 ASV read count files with the best hits of a BLAST search.",
			usage: "blast_parser merge-qiime --asvs <asvs> --blasthits <blasthits> [--prefixes <prefixes>] [--output <output>] [--hits-per-asv <hits-per-asv>] [--sort <sort>]",
			aliases: ["mrgq"] )
		
		@OptionGroup var options: Options
		
		@Option(name: [.short, .customLong("asvs")],
				help: "Path(s) to table file(s) generated by Qiime2 containing ASVs and their respective read counts and taxonomic classification separated by space(s).")
		var asvs:String
        
        @Option(name: [.short, .customLong("prefixes")],
                help: "Prefix(es) to add to the Qiime ASV taxonomic assignment header separated by spaces to distinguish between different classifiers or databases (e.g., 'silva pr2 eukaryome'). [OPTIONAL, default = parent directory name of the directory where the asv file is located, i.e., 2 levels up]")
        var prefixes:String?
		
		@Option(name: [.short, .customLong("blasthits")],
				help: "Path to the BLAST output file using a 13 columns format with following order: qsedid pident length evalue bitscore score nident saccver stitle qcovs staxids sscinames sskingdoms.")
		var blasthits:String
		
		@Option(name: [.short, .customLong("output")],
				help: "Name of the output file. [OPTIONAL, default = (BLASTn output filename)_output.tsv]")
		var outputFile:String? = nil
		
		@Option(name: [.customLong("hits-per-asv")],
				help: "Maximum number of sequences per bin. [OPTIONAL, default = 1]")
		var hitsPerAsv:Int?
		
		@Option(name: [.short, .customLong("sort")],
				help: "Sorting order of the output file, which can be either pident, bitscore or evalue. [OPTIONAL, default = bitscore]")
		var sort:String?
		
		mutating func run() throws {
			guard let parser = BlastQiimeOutputParser(path: blasthits,
                                                      asvs: asvs,
                                                      prefixes: prefixes)
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
			
			// sets default name
			if outputFile == nil{
				let fileName = URL(fileURLWithPath: blasthits).deletingPathExtension().lastPathComponent
				outputFile = "\(fileName)_merged_output.tsv"
			}
		
			try parser.print(outputFile!)
		}
	}
    
    struct ParseMinimap: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Parses a minimap2 output tsv file containing a header row with the following columns: Query_ID, Reference_ID, Alignment_Score, Alignment_Length, Taxonomy and then outputs files containing selected sequences in fastq and/or fasta format to be remapped by minimap2 with other databases or in fasta format to be the input to BLASTN and/or a read count stats file per taxon found. Warning: an error will be generated if no output file is specified.",
            usage: "blast_parser parse-minimap --input <input> --reads <fastq-file> [--output <fastq-output>] [--fastaOutput <fasta-output>] [--stats-output <stats-output>] [--hits-per-bin <hits-per-bin>]",
            aliases: ["prsm"] )
        
        @OptionGroup var options: Options
        
        @Option(name: [.short, .customLong("input")],
                help: "Path to the minimap2 output table containing the following columns: QueryID, Reference_ID, Alignment_Score, Alignment_Length and Taxonomy")
        var input:String
        
        @Option(name: [.short, .customLong("reads")],
                help: "Path to the fastq file containing the reads that were mapped with minimap2.")
        var reads:String
        
        @Option(name: [.short, .customLong("fastq-output")],
                help: "Path to the output fastq file. [OPTIONAL]")
        var output:String?
        
        @Option(name: [.short, .customLong("fasta-output")],
                help: "Path to the output fasta file. [OPTIONAL]")
        var fastaOutput:String?
        
        @Option(name: [.short, .customLong("stats-output")],
                help: "Path to the output file containing the read count stats per taxon. [OPTIONAL]")
        var statsOutput:String?
        
        @Option(name: [.short, .customLong("hits-per-bin")],
                help: "Maximum number of reads to include in each taxon bin. [OPTIONAL, default = 5")
        var hitsPerBin:Int = 5
        
        mutating func run() throws {
            guard let parser = MinimapParser(path: input,
                                             readsPath: reads,
                                             hitsPerBin: hitsPerBin) else {
                throw RuntimeError("Unable to parse minimap2 output file as no valid file was found.")
            }
            parser.fastqOutputPath = output
            parser.fastaOutputPath = fastaOutput
            parser.statsOutputPath = statsOutput
            try parser.parse()
            try parser.print()
        }
    }
    
    struct MergeMinimap: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Merges minimap2 output tsv files containing a header row with the following columns: Query_ID, Reference_ID, Alignment_Score, Alignment_Length, Taxonomy with a with the best hits of a BLAST search. ",
            usage: "blast_parser merge-minimap --hits <minimaphits> --main-hits <main-hits> --blasthits <blasthits> --reads <fasta-file> [--output <output>]",
            aliases: ["mrgm"] )
        
        @OptionGroup var options: Options
        
        @Option(name: [.short, .customLong("hits")],
                help: "Path(s) to the minimap2 output table(s) containing the hits selected by the parse-minimap subcommand. Each table should contain the following columns: QueryID, Reference_ID, Alignment_Score, Alignment_Length and Taxonomy. Multiple file or paths, separated by spaces, can be given to merge multiple tables. If a path to a directory is given, all the files with the suffix '_representative_classified.tsv' will be used.")
        var minimapHits:String
        
        @Option(name: [.short, .customLong("main-hits")],
                help: "Path to the minimap2 hits table containing the top 5 taxonomic assignments of all reads with the following columns: QueryID, Reference_ID, Alignment_Score, Alignment_Length and Taxonomy.")
        var minimapStats:String
        
        @Option(name: [.short, .customLong("blasthits")],
                help: "Path to the BLAST output file using a 13 columns format with following order: qsedid pident length evalue bitscore score nident saccver stitle qcovs staxids sscinames sskingdoms.")
        var blasthits:String
        
        @Option(name: [.short, .customLong("output")],
                help: "Name of the output file. [OPTIONAL, default = (BLASTn output filename)_merged_output.tsv].")
        var outputFile:String? = nil
        
        @Option(name: [.short, .customLong("prefixes")],
                help: "Prefix(es) to add to the output file header row separated by spaces to distinguish between different classifiers or databases. If no prefix is given no header row will be generated (e.g., 'silva pr2 eukaryome') [OPTIONAL].")
        var prefixes:String?
    }
}



