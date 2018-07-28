#!/usr/bin/perl

# pandoc-turabian.pl uses pandoc to produce a .docx file from a .tex 
# file with a "turabian-researchpaper" document class.
# Copyright (C) 2018  Omar Abdool
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# 
# Required support files:
#	$HOME/.pandoc/
#		chicago-note-bibliography.csl
#		turabian-latex-preamble.tex
#		turabian-style-reference.docx
#	$HOME/bin/
#		pandoc-turabian-formatDoc.pl
#		pandoc-turabian-prepTeX.pl
#		pandoc-turabian.pl
# 
# Command:	pandoc-turabian.pl [FileName]
# Output:	[FileName].docx
# 	Output if "filecontents" environment for .bib: [BibFileName.bib]
# 
# Version:	2018/07/27
# 

use strict;
use utf8;
use File::Basename;


print "Turabian Formatting with Pandoc (version 2018/07/27)\n";


# Get file name from command line and use for output file
my ($texFileName, $texFilePath, $texFileExt) = fileparse($ARGV[0], qr/\.[^.]*/);


# Endnotes option and bib resource name
my $endnotesOption = '';
my $bibResName = '';


# Construct notice string
sub noticeOut {
	my ($noticeType, $noticeStr, $subNoticeStr) = @_;
 	$subNoticeStr //= '';
	return "\n  ${noticeType}: ${noticeStr}\n    $subNoticeStr\n";
}


# Subroutine to get endnotes option and bib resource name
sub getOptionsFromFile {
	
	open(my $originalFile, "<${texFileName}.tex")
		or die noticeOut("Error", "Could not open '${texFileName}.tex'.");
	binmode $originalFile, ":encoding(UTF-8)";

	my $exitSearch = 0;
	while (<$originalFile>) {
		if ( $exitSearch == 0 ) {
			if ( $_ =~ m/\\documentclass([^.]*)endnotes([^.]*){turabian-researchpaper}/ ) {
				$endnotesOption = 'endnotes';
				print "Document class option found: $endnotesOption\n";
				print noticeOut("Warning", "Support for endnotes in beta.");
			} elsif ( $_ =~ m/\Q\addbibresource{\E([^.]*).bib\Q}\E/ ) {
				$bibResName = $1;
				if ( $bibResName eq '\jobname' ) {
					$bibResName = $texFileName;
				}
				$exitSearch = 0;
				last;
			} elsif ( $_ =~ m/\Q\begin{document}\E/ ) {
				$exitSearch = 0;
				last;
			}
		}
	}
	
	close($originalFile);

	return;
}


sub RunPandoc {

	my $pandocUserDir = $ENV{"HOME"} . "/.pandoc";

	my $tempFileName = "${texFileName}-pandoc.tex";
	my $outputFileName = "${texFileName}.docx";

	my $cslFileName = "chicago-note-bibliography.csl";
	my $refDocName = "turabian-style-reference.docx";

	print "\nRunning Pandoc on temporary file with...\n";

	# Verify file then set reference settings for pandoc
	my $bibFileCall = "";
	my $cslFileCall = "";

	if ( -e "${bibResName}.bib" ) {
		$bibFileCall = "--bibliography=${bibResName}.bib";
		print "  Bibliography = ${bibResName}.bib\n";
		$cslFileCall = "--csl=${pandocUserDir}/${cslFileName}";	
		print "  CSL = ${cslFileName}\n";
	}
	else {
		print "  Bibliography file not found.\n";
	}

	print "  Reference Doc = ${refDocName}\n";

	system("pandoc ${tempFileName} --from latex+smart ${bibFileCall} ${cslFileCall} -o ${outputFileName} --reference-doc=${pandocUserDir}/${refDocName}");

	print "Pandoc done.\n";
	print "Created new file: ${outputFileName}\n";

	# Remove formatted .tex file used by pandoc
 	unlink "$tempFileName";
 	print "Removed temporary file: ${tempFileName}\n";

	return;
}

	# Get options from [FileName].tex
	getOptionsFromFile();

	# Format .tex file for use with pandoc, using pandoc-turabian.pl
	system("pandoc-turabian-prepTeX.pl ${texFileName}.tex $endnotesOption");

	# Process formatted .tex file using pandoc
	RunPandoc();

	# Format .docx file generated by pandoc
	system("pandoc-turabian-formatDocx.pl ${texFileName}.docx $endnotesOption");

	print "\npandoc-turabian.pl done converting \"${texFileName}.tex\". Enjoy!\n";