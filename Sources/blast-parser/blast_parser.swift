//
//  blast_parser.swift
//  blast-parser
//
//  Created by João Varela on 29/05/2026.
//


import Foundation
import ArgumentParser
import Crypto

@main
struct BlastParser: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: """
            blast-parser is a bioinformatic tool that parses Qiime2 output files for Illumina short reads or Kraken2 or minimap2 output files for Nanopore long reads. It then merges this output with the output of NCBI blastn+ tool, producing a full taxonomical lineage from a local PostgresSQL database imported from the NCBI ranked taxonomy dump file available at the NCBI FTP server inside the new_taxonomy folder.
            """,
        usage: "blast-parser <subcommand>",
        version: "0.9.0",
        subcommands: [Import.self, ParseKraken.self, MergeKraken.self, MergeQiime.self, ParseMinimap.self, MergeMinimap.self],
        defaultSubcommand: Import.self
    )
}



