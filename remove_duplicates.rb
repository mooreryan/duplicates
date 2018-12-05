#!/usr/bin/env ruby

Signal.trap("PIPE", "EXIT")

require "abort_if"
require "fileutils"
require "parse_fasta"
require "optimist"
require "set"

include AbortIf
include AbortIf::Assert

COPYRIGHT = "2018 Ryan Moore"
CONTACT   = "moorer@udel.edu"
WEBSITE   = "https://github.com/mooreryan/duplicates"
LICENSE   = "MIT"

VERSION = "v0.1.0"
VERSION_BANNER =
  "# Version:   #{VERSION}
# Copyright: #{COPYRIGHT}
# Contact:   #{CONTACT}
# Website:   #{WEBSITE}
# License:   #{LICENSE}"

# Hash a record depending on what duplication you're checking for.
def hash_record! ht, rec, duplicate_type
  case duplicate_type
  when 1 # whole header match
    unless ht.has_key? rec.header
      ht[rec.header] = rec
    end
  when 2 # header ID match
    unless ht.has_key? rec.id
      ht[rec.id] = rec
    end
  when 3 # whole seq match
    unless ht.has_key? rec.seq
      ht[rec.seq] = rec
    end
  when 4 # whole seq + whole header
    key = "#{rec.header}#{rec.seq}"
    unless ht.has_key? key
      ht[key] = rec
    end
  when 5 # whole seq + hedaer ID
    key = "#{rec.id}#{rec.seq}"
    unless ht.has_key? key
      ht[key] = rec
    end
  end
end

def make_key rec, duplicate_type
  key = nil

  case duplicate_type
  when 1 # whole header match
    key = rec.header.hash
  when 2 # header ID match
    key = rec.id.hash
  when 3 # whole seq match
    key = rec.seq.hash
  when 4 # whole seq + whole header
    key = "#{rec.header}#{rec.seq}".hash
  when 5 # whole seq + hedaer ID
    key = "#{rec.id}#{rec.seq}".hash
  end

  key
end

# In low mem mode I just store the hashed values in a set, then need
# to go through a second time to check against the set.  I suppose it
# is possible that a false positive may occur due to collisions, but
# not sure how common that would be.
def hash_record_low_mem! set, rec, duplicate_type
  key = make_key rec, duplicate_type

  set << key
end

def duplicate? set, rec, duplicate_type
  key = make_key rec, duplicate_type

  set.include? key
end

opts = Optimist.options do
  version VERSION_BANNER

  banner <<-EOS

#{VERSION_BANNER}

  Remove duplicate sequences in a variety of ways.

  Duplicate types
  ===============

  Here are the options for what constitutes a "duplicate" sequence.
  Each options specifies what it means for two sequences to be
  duplicates.

  1.  Whole header match (case sensitive) -- The entire header of the
      sequence record must match exactly.  The sequence may or may not
      match.

  2.  Header ID match (case sensitive) -- The ID part of the header
      (everything up to the first space) must match exactly.  E.g.,
      '>seq_1 apple' would match '>seq_1 pie'.  The sequence may or
      may not match.

  3.  Whole sequence match (case sensitive) -- The entire sequence
      matches another entire sequence.  The header may or may not
      match.

  4.  Whole sequence (case sensitive) + Whole header (case sensitive)
      -- The whole sequence and the whole header must match for two
      sequences to be duplicates.

  5.  Whole sequence (case sensitive) + Header ID (case sensitive) --
      The whole sequence must match and but only the ID part of the
      headers must match.

  Regardless of the method chosen, only the first sequence of a
  duplicated set of sequences will be kept.

  Memory
  ======

  By default, I just read everything into hash tables, so I'll use a
  lot of memory, and might get pretty slow with big files.  If you
  need to check a big file and dont have the memory to do it or it is
  just taking forever due to the big memory use, you could pass the
  --low-memory option.

  Options:
  EOS

  opt(:infile,
      "Input file",
      type: :string)
  opt(:outdir,
      "Output directory",
      type: :string,
      default: ".")

  opt(:duplicate_type,
      "What kind of duplicates? (See --help)",
      default: 1)
  opt(:low_memory,
      "Use low memory mode")
end

# Handle duplicate_type arg
duplicate_type = opts[:duplicate_type]
abort_unless duplicate_type >= 1 && duplicate_type <= 5,
             "--duplicate-type must be an int from 1 to 5.  " \
             "Try running --help for help."

# Handle infile arg
abort_unless opts[:infile_given],
             "--infile is a required argument."

abort_unless File.exist?(opts[:infile]),
             "#{opts[:infile]} does not exist."

infile = opts[:infile]
infile_dir = File.dirname infile
infile_ext = File.extname infile
infile_base = File.basename infile, infile_ext

# Handle outdir arg
outdir = opts[:outdir]
FileUtils.mkdir_p outdir

outf = File.join outdir, "#{infile_base}.no_duplicates#{infile_ext}"

if opts[:low_mem]
  recs = Set.new

  # First go through the file and store the hashed vals
  ParseFasta::SeqFile.open(infile).each_record do |rec|
    hash_record_low_mem! recs, rec, duplicate_type
  end

  # Go through a second time to check for matches
  File.open(outf, "w") do |f|
    ParseFasta::SeqFile.open(infile).each_record do |rec|
      unless duplicate?(recs, rec, duplicate_type)
        f.puts rec
      end
    end
  end
else
  rec_ht = {}
  ParseFasta::SeqFile.open(infile).each_record do |rec|
    hash_record! rec_ht, rec, duplicate_type
  end

  File.open(outf, "w") do |f|
    rec_ht.each do |key, rec|
      f.puts rec
    end
  end
end
