=head1 LICENSE

 Copyright [2019] EMBL-European Bioinformatics Institute

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.

=head1 CONTACT

 Please email comments or questions to the public Ensembl
 developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

 Questions may also be sent to the Ensembl help desk at
 <http://www.ensembl.org/Help/Contact>.

=cut

=head1 NAME

Bio::EnsEMBL::Analysis::Runnable::Star

=head1 SYNOPSIS

  my $runnable =
    Bio::EnsEMBL::Analysis::Runnable::Star->new();

 $runnable->run;
 my @results = $runnable->output;

=head1 DESCRIPTION

This module uses Star to align fastq to a genomic sequence. Star is a splice aware
aligner. It creates output files with the reads overlapping splice sites and the reads
aligning on the exons. Some reads are aligned multiple times in the genome.

=head1 METHODS

=cut


package Bio::EnsEMBL::Analysis::Runnable::Minimap2;

use warnings;
use strict;
use feature 'say';

use File::Spec;

use Bio::EnsEMBL::Gene;
use Bio::EnsEMBL::Transcript;
use Bio::EnsEMBL::Exon;
use Bio::EnsEMBL::Analysis::Tools::GeneBuildUtils::TranslationUtils qw(compute_translation);
use Bio::EnsEMBL::Utils::Argument qw( rearrange );

use parent ('Bio::EnsEMBL::Analysis::Runnable');


=head2 new

 Arg [DECOMPRESS]           : String as a command like 'gzip -c -'
 Arg [EXPECTED_ATTRIBUTES]  : String specify the attribute expected for the output, see STAR manual
 Description                : Creates a  object to align reads to a genome using STAR
 Returntype                 : 
 Exceptions                 : Throws if WORKDIR does not exist
                              Throws if the genome has not been indexed

=cut

sub new {
  my ( $class, @args ) = @_;

  my $self = $class->SUPER::new(@args);
  my ($genome_index, $input_file, $paftools_path, $database_adaptor, $delete_input_file) = rearrange([qw (GENOME_INDEX INPUT_FILE PAFTOOLS_PATH DATABASE_ADAPTOR DELETE_INPUT_FILE)],@args);
  $self->genome_index($genome_index);
  $self->input_file($input_file);
  $self->paftools_path($paftools_path);
  $self->database_adaptor($database_adaptor);
  $self->delete_input_file($delete_input_file);
  return $self;
}

=head2 run

 Arg [1]    : None
 Description: Run Star to align reads to an indexed genome. The resulting output file will be stored in $self->output
 Returntype : None
 Exceptions : None

=cut

sub run {
  my ($self) = @_;

  my $file_name = $self->create_filename();
  my $sam_file = $file_name.".sam";
  my $bed_file = $file_name.".bed";
  $self->files_to_delete($sam_file);
  $self->files_to_delete($bed_file);

  my $genome_index  = $self->genome_index;
  my $input_file    = $self->input_file;
  if($self->delete_input_file) {
    $self->files_to_delete($input_file);
  }

  my $paftools_path = $self->paftools_path;
  my $options       = $self->options;

  unless($paftools_path) {
    $self->throw("Paftools path was empty");
  }

  # run minimap2
  my $minimap2_command = $self->program." --cs -N 1 -ax splice -uf -C5 ".$genome_index." ".$input_file." > ".$sam_file;
  $self->warning("Command:\n".$minimap2_command."\n");
  if(system($minimap2_command)) {
    $self->throw("Error running minimap2\nError code: $?\n");
  }

  my $percent_id_hash = {};
  my $coverage_hash = {};
  $self->parse_sam($sam_file,$percent_id_hash,$coverage_hash);

  my $paftools_command = $paftools_path." splice2bed ".$sam_file." > ".$bed_file;
  $self->warning("Command:\n".$paftools_command."\n");
  if(system($paftools_command)) {
    $self->throw("Error running paftools\nError code: $?\n");
  }

  $self->output($self->parse_results($bed_file,$percent_id_hash,$coverage_hash));
}


sub parse_sam {
  my ($self,$sam_file,$percent_id_hash,$coverage_hash) = @_;

  unless(open(IN,$sam_file)) {
    $self->throw("Could not open the sam file for processing. Path:\n".$sam_file);
  }

  while(<IN>) {
    my $line = $_;
    if($line =~ /^@/) {
      next;
    }

    my @results = split("\t",$line);
    my $num_cols = scalar(@results);

    # Column number is variable. Should probably just use one of the column identifiers that is always present
    unless($num_cols >= 20) {
      $self->warning("Unexpected number of result columns, skipping line. Line:\n".$line."Number of cols: ".$num_cols);
      next;
    }

    my $read_name = $results[0];
    # Sometimes this does not have any seq for some reason, so this value becomes 1 incorrectly. This
    # is dealt with in the coverage calc later on. Really should look up the faidx for the seq if this
    # col does not have it
    my $seq_length = length($results[9]);

    # The index of this varies because the columns vary with each result
    my $cs;
    for(my $i=0; $i<scalar(@results); $i++) {
      if($results[$i] =~ /^cs\:Z\:/) {
        $cs = $results[$i];
        last;
      }
    }

    unless($cs) {
      $self->throw("CS column not parsed successfully. Line contents:\n".$line);
    }

    say "FERGAL DEBUG CS: ".$cs;

    my $mismatch_count = () = $cs =~ /\*/gi;
    my $match_count = 0;
    while($cs =~ s/\:(\d+)//) {
      $match_count += $1;
    }

    my $aligned_count = ($match_count + $mismatch_count);

    say "FERGAL DEBUG MATCH COUNT: ".$match_count;
    say "FERGAL DEBUG MISMATCH COUNT: ".$mismatch_count;
    say "FERGAL DEBUG ALIGNED COUNT: ".$aligned_count;

    my $percent_identity = 100 * ($match_count / $aligned_count);
    $percent_identity = sprintf("%.2f",$percent_identity);

    # Sometimes the read isn't included in the output for some reason. We could look it up in the file, though this could
    # be a little slow if the file is big
    # Will probably add this is later
    if($aligned_count > $seq_length) {
      $self->warning("The number of aligned bases listed in the cs:Z is greater than calculated seq length. Likely that the sequence ".
                     "was not included in the sam (represented by *?). Will set to same value as aligned bases. This will make the coverage ".
                     "100 percent. Seq column entry:\n".$results[9]);
      $seq_length = $aligned_count;
    }

    my $coverage = 100 * ($aligned_count / $seq_length);
    $coverage = sprintf("%.2f",$coverage);
    unless(($percent_identity >= 0 && $percent_identity <= 100) &&
           ($coverage >= 0 && $coverage <= 100)) {
      $self->throw("Issue with coverage/percent id calculation. Got values outside of expected range.".
                   "\nPercent id: ".$percent_identity."\nCoverage: ".$coverage."\nRead id: ".$read_name);
    }

    unless(exists $percent_id_hash->{$read_name}) {
      $percent_id_hash->{$read_name} = $percent_identity;
      $coverage_hash->{$read_name} = $coverage;
    } else {
      $self->warning("Found two result lines for a read. Only calculating percent id for the first one. ID: ".$read_name);
    }
  }
  close IN;
}

sub parse_results {
  my ($self,$output_file,$percent_id_hash,$coverage_hash) = @_;

# 13  0   84793   ENST00000380152.7   1000    +   0   84793   0,128,255   27  194,106,249,109,50,41,115,50,112,1116,4932,96,70,428,182,188,171,355,156,145,122,199,164,139,245,147,2105,  0,948,3603,9602,10627,10768,11025,13969,15445,16798,20791,29084,31353,39387,40954,42268,47049,47705,54928,55482,61196,63843,64276,64533,79215,81424,82688,

  my $percent_id_cutoff = 98;
  my $coverage_cutoff = 95;

  say "Parsing minimap2 output";
  my $dba = $self->database_adaptor();
  my $slice_adaptor = $dba->get_SliceAdaptor();
  my $genes = [];

  unless(-e $output_file) {
    $self->throw("Output file does not exist. Path used:\n".$output_file);
  }

  open(IN,$output_file);
  while(<IN>) {
    my $line = $_;
    say "Output:\n".$line;
    my @results = split("\t",$line);
    my $hit_name = $results[3];
    my $percent_identity = $percent_id_hash->{$hit_name};
    my $coverage = $coverage_hash->{$hit_name};
    unless($percent_identity >= $percent_id_cutoff) {
      $self->warning("Percent id for the hit fails the cutoff.\nHit name: ".$hit_name."\nPercent id: ".$percent_identity.
                     "\nCut-off: ".$percent_id_cutoff);
      next;
    }

    unless($coverage >= $coverage_cutoff) {
      $self->warning("Coverage for the hit fails the cutoff.\nHit name: ".$hit_name."\nCoverage: ".$coverage.
                     "\nCut-off: ".$coverage_cutoff);
      next;
    }

    my $seq_region_name = $results[0];
    my $offset = $results[1];
    my $slice = $slice_adaptor->fetch_by_region('toplevel',$seq_region_name);
    my $strand = $results[5];
    if($strand eq '+') {
      $strand = 1;
    } elsif($strand eq '-') {
      $strand = -1;
    } else {
      $self->throw("Expected strand info to be + or -, found: ".$strand);
    }
    my $block_sizes = $results[10];
    my $block_starts = $results[11];

    my @block_sizes = split(",",$block_sizes);
    my @block_starts = split(",",$block_starts);

    my @exons = ();
    for(my $i=0; $i<scalar(@block_sizes); $i++) {
      my $block_start = $offset + $block_starts[$i] + 1; # We need to convert to 1-based
      my $block_end = $block_start + $block_sizes[$i] - 1;
      if($block_end < $block_start) {
        $self->warning("Block end < block start due to a 0 length block size. Setting block end to block start");
        $block_end = $block_start;
      }

      my $exon = $self->create_exon($slice,$block_start,$block_end,$strand);
      unless($exon) {
        $self->throw("Tried to create an exon and failed: ".$seq_region_name.", ".$block_start.", ".$block_end.", ".$strand);
      }
      push(@exons,$exon);
    }

    if($strand == -1) {
      @exons = reverse(@exons);
    }

    my $gene = $self->create_gene(\@exons,$slice,$hit_name);
    # We aren't going to store a supporting feature, but we can store the coverage and percent id on the gene
    $coverage = int($coverage);
    $gene->version($coverage);
    $gene->description($percent_identity);
    unless($self->filter_gene($gene)) {
      push(@$genes,$gene);
    }
  }
  close IN;

  say "Finished parsing output";
  return($genes);
}


sub create_exon {
  my ($self,$slice,$exon_start,$exon_end,$strand) = @_;

  my $exon = Bio::EnsEMBL::Exon->new(-start     => $exon_start,
                                     -end       => $exon_end,
                                     -strand    => $strand,
                                     -phase     => -1,
                                     -end_phase => -1,
                                     -analysis  => $self->analysis,
                                     -slice     => $slice);

#  if($exon_start > $exon_end) {
#    $self->throw("FERGAL EXON S > E: ".$slice->name." ".$exon->start."..".$exon->end." ".$strand);
#  }
#  say "Created exon: ".$slice->name." (".$exon_start."..".$exon_end.":".$strand.")";
  return($exon);
}


sub create_gene {
  my ($self,$exons,$slice,$hit_name) = @_;

  my $transcript = Bio::EnsEMBL::Transcript->new(-exons    => $exons,
                                                 -slice    => $slice,
                                                 -analysis => $self->analysis);

#  if($transcript->start > $transcript->end) {
#    $self->throw("FERGAL TRANSCRIPT S > E: ".$slice->name." ".$transcript->start."..".$transcript->end." ".$transcript->strand);
#  }

  compute_translation($transcript);
  my $gene = Bio::EnsEMBL::Gene->new(-slice    => $slice,
                                     -analysis => $self->analysis);

  $transcript->biotype('cdna');
  $gene->biotype('cdna');
  $transcript->stable_id($hit_name);
  $gene->stable_id($hit_name);

  $gene->add_Transcript($transcript);

  return($gene);
}


sub filter_gene {
  my ($self) = @_;
  return(0);
}


sub genome_index {
  my ($self, $val) = @_;

  if ($val) {
    $self->{_genome_index} = $val;
  }

  return $self->{_genome_index};
}


sub input_file {
  my ($self, $val) = @_;

  if ($val) {
    $self->{_input_file} = $val;
  }

  return $self->{_input_file};
}


sub paftools_path {
  my ($self, $val) = @_;

  if ($val) {
    $self->{_paftools_path} = $val;
  }

  return $self->{_paftools_path};
}


sub database_adaptor {
  my ($self, $val) = @_;

  if (defined $val) {
    throw(ref($val).' is not a Bio::EnsEMBL::DBSQL::DBAdaptor')
      unless ($val->isa('Bio::EnsEMBL::DBSQL::DBAdaptor'));
    $self->{_database_adaptor} = $val;
  }

  return $self->{_database_adaptor};
}


sub delete_input_file {
  my ($self, $val) = @_;

  if ($val) {
    $self->{_delete_input_file} = $val;
  }

  return $self->{_delete_input_file};
}

1;