=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2021] EMBL-European Bioinformatics Institute

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

package Bio::EnsEMBL::Analysis::Hive::Config::Genome_annotation_conf;

use strict;
use warnings;
use File::Spec::Functions;

use Bio::EnsEMBL::ApiVersion qw/software_version/;
use Bio::EnsEMBL::Analysis::Tools::Utilities qw(get_analysis_settings);
use base ('Bio::EnsEMBL::Analysis::Hive::Config::HiveBaseConfig_conf');

sub default_options {
  my ($self) = @_;
  return {
    # inherit other stuff from the base class
    %{ $self->SUPER::default_options() },

######################################################
#
# Variable settings- You change these!!!
#
######################################################
########################
# Misc setup info
########################
    dbowner                          => '' || $ENV{EHIVE_USER} || $ENV{USER},
    pipeline_name                    => '' || $self->o('production_name').'_'.$self->o('release_number'),
    user_r                           => '', # read only db user
    user                             => '', # write db user
    password                         => '', # password for write db user
    server_set                       => '', # What server set to user, e.g. set1
    pipe_db_server                   => '', # host for pipe db
    databases_server                 => '', # host for general output dbs
    dna_db_server                    => '', # host for dna db
    pipe_db_port                     => '', # port for pipeline host
    databases_port                   => '', # port for general output db host
    dna_db_port                      => '', # port for dna db host
                                    
    registry_host                    => '', # host for registry db
    registry_port                    => '', # port for registry db
    registry_db                      => '', # name for registry db
                                    
    release_number                   => '' || $ENV{ENSEMBL_RELEASE},
    species_name                     => '', # e.g. mus_musculus
    production_name                  => '', # usually the same as species name but currently needs to be a unique entry for the production db, used in all core-like db names
    taxon_id                         => '', # should be in the assembly report file
    species_taxon_id                 => '' || $self->o('taxon_id'), # Species level id, could be different to taxon_id if we have a subspecies, used to get species level RNA-seq CSV data
    genus_taxon_id                   => '' || $self->o('taxon_id'), # Genus level taxon id, used to get a genus level csv file in case there is not enough species level transcriptomic data
    uniprot_set                      => '', # e.g. mammals_basic, check UniProtCladeDownloadStatic.pm module in hive config dir for suitable set,
    output_path                      => '', # Lustre output dir. This will be the primary dir to house the assembly info and various things from analyses
    wgs_id                           => '', # Can be found in assembly report file on ftp://ftp.ncbi.nlm.nih.gov/genomes/genbank/
    assembly_name                    => '', # Name (as it appears in the assembly report file)
    assembly_accession               => '', # Versioned GCA assembly accession, e.g. GCA_001857705.1
    assembly_refseq_accession        => '', # Versioned GCF accession, e.g. GCF_001857705.1
    registry_file                    => '' || catfile($self->o('output_path'), "Databases.pm"), # Path to databse registry for LastaZ and Production sync
    use_genome_flatfile              => '1',# This will read sequence where possible from a dumped flatfile instead of the core db
    species_url                      => '', # sets species.url meta key
    species_division                 => 'EnsemblVertebrates', # sets species.division meta key

    repbase_logic_name               => '', # repbase logic name i.e. repeatmask_repbase_XXXX, ONLY FILL THE XXXX BIT HERE!!! e.g primates
    repbase_library                  => '', # repbase library name, this is the actual repeat repbase library to use, e.g. "Mus musculus"
    replace_repbase_with_red_to_mask => '0', # Setting this will replace 'full_repbase_logic_name' with 'red_logic_name' repeat features in the masking process
    use_repeatmodeler_to_mask        => '0', # Setting this will include the repeatmodeler library in the masking process
    repeatmodeler_library            => '', # This should be the path to a custom repeat library, leave blank if none exists

    stable_id_start                  => '0', # When mapping is not required this is usually set to 0
    stable_id_prefix                 => '', # e.g. ENSPTR. When running a new annotation look up prefix in the assembly registry db
    mapping_required                 => '0', # If set to 1 this will run stable_id mapping sometime in the future. At the moment it does nothing
    mapping_db                       => '', # Tied to mapping_required being set to 1, we should have a mapping db defined in this case, leave undef for now

    paired_end_only                  => '1', # Will only use paired-end rnaseq data if 1
    rnaseq_study_accession           => '', # A study accession for a transcriptomic dataset, if provided, only this data will be used
    long_read_study_accession        => '', # A study accession for a transcriptomic dataset, if provided, only this data will be used
    rnaseq_summary_file              => '' || catfile($self->o('rnaseq_dir'), $self->o('species_name').'.csv'), # Set this if you have a pre-existing cvs file with the expected columns
    rnaseq_summary_file_genus        => '' || catfile($self->o('rnaseq_dir'), $self->o('species_name').'_gen.csv'), # Set this if you have a pre-existing genus level cvs file with the expected columns
    long_read_summary_file           => '' || catfile($self->o('long_read_dir'), $self->o('species_name').'_long_read.csv'), # csv file for minimap2, should have 2 columns tab separated cols: sample_name\tfile_name
    long_read_summary_file_genus     => '' || catfile($self->o('long_read_dir'), $self->o('species_name').'_long_read_gen.csv'), # csv file for minimap2, should have 2 columns tab separated cols: sample_name\tfile_name
    long_read_fastq_dir              => '' || catdir($self->o('long_read_dir'),'input'),

    skip_repeatmodeler               => '0', # Skip using our repeatmodeler library for the species with repeatmasker, will still run standard repeatmasker
    skip_post_repeat_analyses        => '1', # Will everything after the repreats (rm, dust, trf) in the genome prep phase if 1, i.e. skips cpg, eponine, genscan, genscan blasts etc.
    skip_projection                  => '0', # Will skip projection process if 1
    skip_lastz                       => '0', # Will skip lastz if 1 (if skip_projection is enabled this is irrelevant)
    skip_rnaseq                      => '0', # Will skip rnaseq analyses if 1
    skip_long_read                   => '0', # Will skip long read analyses if 1
    skip_ncrna                       => '0', # Will skip ncrna process if 1
    skip_cleaning                    => '0', # Will skip the cleaning phase, will keep more genes/transcripts but some lower quality models may be kept

    # Keys for custom loading, only set/modify if that's what you're doing
    skip_genscan_blasts              => '1',
    load_toplevel_only               => '1', # This will not load the assembly info and will instead take any chromosomes, unplaced and unlocalised scaffolds directly in the DNA table
    custom_toplevel_file_path        => '', # Only set this if you are loading a custom toplevel, requires load_toplevel_only to also be set to 2

###############################
# Sub pipeline configurations
###############################
    hive_load_assembly_config => 'Bio::EnsEMBL::Analysis::Hive::Config::LoadAssembly',
    hive_refseq_import_config => 'Bio::EnsEMBL::Analysis::Hive::Config::Refseq_import_subpipeline',
    hive_repeat_masking_config => 'Bio::EnsEMBL::Analysis::Hive::Config::RepeatMasking',
    hive_lastz_config => 'Bio::EnsEMBL::Analysis::Hive::Config::LastZ',
    hive_projection_config => 'Bio::EnsEMBL::Analysis::Hive::Config::Projection_subpipeline_conf',
    hive_homology_config => 'Bio::EnsEMBL::Analysis::Hive::Config::GenblastHomology',
    hive_best_targeted_config => 'Bio::EnsEMBL::Analysis::Hive::Config::BestTargetted_subpipeline',
    hive_igtr_config => 'Bio::EnsEMBL::Analysis::Hive::Config::IGTR_subpipeline',
    hive_short_ncrna_config => 'Bio::EnsEMBL::Analysis::Hive::Config::ShortncRNA',
    hive_rnaseq_config => 'Bio::EnsEMBL::Analysis::Hive::Config::StarScallopRnaseq',
    hive_long_read_config => 'Bio::EnsEMBL::Analysis::Hive::Config::long_read',
    hive_homology_rnaseq_config => 'Bio::EnsEMBL::Analysis::Hive::Config::HomologyRnaseq',
    hive_transcript_finalisation_config => 'Bio::EnsEMBL::Analysis::Hive::Config::TranscriptSelection',
    hive_core_db_finalisation_config => 'Bio::EnsEMBL::Analysis::Hive::Config::FinaliseCoreDB',
    hive_otherfeatures_db_config => 'Bio::EnsEMBL::Analysis::Hive::Config::OtherFeatureDb',
    hive_rnaseq_db_config => 'Bio::EnsEMBL::Analysis::Hive::Config::production_rnaseq_db',


########################
# Pipe and ref db info
########################
    pipe_db_name                  => $self->o('dbowner').'_'.$self->o('production_name').'_pipe_'.$self->o('release_number'),
    dna_db_name                   => $self->o('dbowner').'_'.$self->o('production_name').'_core_'.$self->o('release_number'),

    reference_db_name            => $self->o('dna_db_name'),
    reference_db_server          => $self->o('dna_db_server'),
    reference_db_port            => $self->o('dna_db_port'),

    refseq_db_server             => $self->o('databases_server'),
    refseq_db_port               => $self->o('databases_port'),

    projection_source_db_name    => '', # This is generally a pre-existing db, like the current human/mouse core for example
    projection_source_db_server  => 'mysql-ens-mirror-1',
    projection_source_db_port    => '4240',
    projection_source_production_name => '',

    compara_db_name     => 'leanne_ensembl_compara_95',
    compara_db_server  => 'mysql-ens-genebuild-prod-5',
    compara_db_port    => 4531,

    projection_db_server  => $self->o('databases_server'),
    projection_db_port    => $self->o('databases_port'),

    genblast_db_server           => $self->o('databases_server'),
    genblast_db_port             => $self->o('databases_port'),

    genblast_nr_db_server           => $self->o('databases_server'),
    genblast_nr_db_port             => $self->o('databases_port'),

    cdna_db_server               => $self->o('databases_server'),
    cdna_db_port                 => $self->o('databases_port'),

    best_targeted_db_server               => $self->o('databases_server'),
    best_targeted_db_port                 => $self->o('databases_port'),

    ig_tr_db_server              => $self->o('databases_server'),
    ig_tr_db_port                => $self->o('databases_port'),

    ncrna_db_server              => $self->o('databases_server'),
    ncrna_db_port                => $self->o('databases_port'),

    rnaseq_db_server             => $self->o('databases_server'),
    rnaseq_db_port               => $self->o('databases_port'),

    rnaseq_refine_db_server       => $self->o('databases_server'),
    rnaseq_refine_db_port         => $self->o('databases_port'),

    rnaseq_blast_db_server       => $self->o('databases_server'),
    rnaseq_blast_db_port         => $self->o('databases_port'),

    long_read_initial_db_server  => $self->o('databases_server'),
    long_read_initial_db_port    => $self->o('databases_port'),

    long_read_final_db_server    => $self->o('databases_server'),
    long_read_final_db_port      => $self->o('databases_port'),

    rnaseq_for_layer_db_server   => $self->o('databases_server'),
    rnaseq_for_layer_db_port     => $self->o('databases_port'),

    rnaseq_for_layer_nr_db_server   => $self->o('databases_server'),
    rnaseq_for_layer_nr_db_port     => $self->o('databases_port'),

    genblast_rnaseq_support_db_server  => $self->o('databases_server'),
    genblast_rnaseq_support_db_port    => $self->o('databases_port'),

    # Layering is one of the most intesnive steps, so separating it off the main output server helps
    # Have also set module to use flatfile seq retrieval, so even if it's on the same server as the
    # core, the core should not be accessed
    layering_db_server           => $self->o('dna_db_server'),
    layering_db_port             => $self->o('dna_db_port'),

    utr_db_server                => $self->o('databases_server'),
    utr_db_port                  => $self->o('databases_port'),

    genebuilder_db_server        => $self->o('databases_server'),
    genebuilder_db_port          => $self->o('databases_port'),

    pseudogene_db_server         => $self->o('databases_server'),
    pseudogene_db_port           => $self->o('databases_port'),

    final_geneset_db_server      => $self->o('databases_server'),
    final_geneset_db_port        => $self->o('databases_port'),

    killlist_db_server           => $self->o('databases_server'),
    killlist_db_port             => $self->o('databases_port'),

    otherfeatures_db_server      => $self->o('databases_server'),
    otherfeatures_db_port        => $self->o('databases_port'),

    # This is used for the ensembl_production and the ncbi_taxonomy databases
    production_db_server         => 'mysql-ens-meta-prod-1',
    production_db_port           => '4483',

    taxonomy_db_server      => $self->o('production_db_server'),
    taxonomy_db_port        => $self->o('production_db_port'),

    databases_to_delete => [],


######################################################
#
# Mostly constant settings
#
######################################################
    assembly_provider_name   => '',
    assembly_provider_url    => '',
    annotation_provider_name => 'Ensembl',
    annotation_provider_url  => 'www.ensembl.org',

    full_repbase_logic_name  => "repeatmask_repbase_".$self->o('repbase_logic_name'),
    red_logic_name           => 'repeatdetector', # logic name for the Red repeat finding analysis
    repeatmodeler_logic_name => 'repeatmask_repeatmodeler',

    ensembl_analysis_script => catdir($self->o('enscode_root_dir'), 'ensembl-analysis', 'scripts'),
    loading_report_script   => catfile($self->o('ensembl_analysis_script'), 'genebuild', 'report_genome_prep_stats.pl'),
    ensembl_misc_script     => catdir($self->o('enscode_root_dir'), 'ensembl', 'misc-scripts'),
    repeat_types_script     => catfile($self->o('ensembl_misc_script'), 'repeats', 'repeat-types.pl'),

    hive_beekeeper_script => catfile($self->o('enscode_root_dir'), 'ensembl-hive', 'scripts', 'beekeeper.pl'),

    rnaseq_dir    => catdir($self->o('output_path'), 'rnaseq'),
    long_read_dir => catdir($self->o('output_path'),'long_read'),

    blast_type => 'ncbi', # It can be 'ncbi', 'wu', or 'legacy_ncbi'
    cdna_threshold => 10, # The lowest number of genes using the cdna_db in the otherfeatures_db


########################
# Extra db settings
########################
    num_tokens => 10,
    mysql_dump_options => '--max_allowed_packet=1000MB',


# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# No option below this mark should be modified
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
########################
# db info
########################
    reference_db => {
      -dbname => $self->o('reference_db_name'),
      -host   => $self->o('reference_db_server'),
      -port   => $self->o('reference_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    refseq_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_refseq_'.$self->o('release_number'),
      -host   => $self->o('refseq_db_server'),
      -port   => $self->o('refseq_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    compara_db => {
      -dbname => $self->o('compara_db_name'),
      -host   => $self->o('compara_db_server'),
      -port   => $self->o('compara_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    projection_source_db => {
      -dbname => $self->o('projection_source_db_name'),
      -host   => $self->o('projection_source_db_server'),
      -port   => $self->o('projection_source_db_port'),
      -user   => $self->o('user_r'),
      -pass   => $self->o('password_r'),
      -driver => $self->o('hive_driver'),
    },

    selected_projection_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_sel_proj_'.$self->o('release_number'),
      -host   => $self->o('projection_db_server'),
      -port   => $self->o('projection_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    genblast_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_genblast_'.$self->o('release_number'),
      -host   => $self->o('genblast_db_server'),
      -port   => $self->o('genblast_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    genblast_nr_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_genblast_nr_'.$self->o('release_number'),
      -host   => $self->o('genblast_nr_db_server'),
      -port   => $self->o('genblast_nr_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    cdna_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_cdna_'.$self->o('release_number'),
      -host   => $self->o('cdna_db_server'),
      -port   => $self->o('cdna_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    best_targeted_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_bt_'.$self->o('release_number'),
      -host   => $self->o('best_targeted_db_server'),
      -port   => $self->o('best_targeted_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    ig_tr_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_igtr_'.$self->o('release_number'),
      -host   => $self->o('ig_tr_db_server'),
      -port   => $self->o('ig_tr_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    ncrna_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_ncrna_'.$self->o('release_number'),
      -host   => $self->o('ncrna_db_server'),
      -port   => $self->o('ncrna_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    rnaseq_refine_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_refine_'.$self->o('release_number'),
      -host   => $self->o('rnaseq_refine_db_server'),
      -port   => $self->o('rnaseq_refine_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    rnaseq_blast_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_rnaseq_blast_'.$self->o('release_number'),
      -host   => $self->o('rnaseq_blast_db_server'),
      -port   => $self->o('rnaseq_blast_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    rnaseq_for_layer_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_rnaseq_layer_'.$self->o('release_number'),
      -host   => $self->o('rnaseq_for_layer_db_server'),
      -port   => $self->o('rnaseq_for_layer_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    rnaseq_for_layer_nr_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_rnalayer_nr_'.$self->o('release_number'),
      -host   => $self->o('rnaseq_for_layer_nr_db_server'),
      -port   => $self->o('rnaseq_for_layer_nr_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    long_read_final_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_lrfinal_'.$self->o('release_number'),
      -host => $self->o('long_read_final_db_server'),
      -port => $self->o('long_read_final_db_port'),
      -user => $self->o('user'),
      -pass => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    genblast_rnaseq_support_nr_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_gb_rnaseq_nr_'.$self->o('release_number'),
      -host   => $self->o('genblast_rnaseq_support_db_server'),
      -port   => $self->o('genblast_rnaseq_support_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    final_geneset_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_final_'.$self->o('release_number'),
      -host   => $self->o('final_geneset_db_server'),
      -port   => $self->o('final_geneset_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    rnaseq_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_rnaseq_'.$self->o('release_number'),
      -host   => $self->o('rnaseq_db_server'),
      -port   => $self->o('rnaseq_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    otherfeatures_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_otherfeatures_'.$self->o('release_number'),
      -host   => $self->o('otherfeatures_db_server'),
      -port   => $self->o('otherfeatures_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    killlist_db => {
      -dbname => $self->o('killlist_db_name'),
      -host   => $self->o('killlist_db_server'),
      -port   => $self->o('killlist_db_port'),
      -user   => $self->o('user_r'),
      -pass   => $self->o('password_r'),
      -driver => $self->o('hive_driver'),
    },

    production_db => {
      -host   => $self->o('production_db_server'),
      -port   => $self->o('production_db_port'),
      -user   => $self->o('user_r'),
      -pass   => $self->o('password_r'),
      -dbname => 'ensembl_production',
      -driver => $self->o('hive_driver'),
    },

    taxonomy_db => {
      -host   => $self->o('production_db_server'),
      -port   => $self->o('production_db_port'),
      -user   => $self->o('user_r'),
      -pass   => $self->o('password_r'),
      -dbname => 'ncbi_taxonomy',
      -driver => $self->o('hive_driver'),
    },

  };
}

sub pipeline_create_commands {
    my ($self) = @_;

    return [
    # inheriting database and hive tables' creation
      @{$self->SUPER::pipeline_create_commands},
      'mkdir -p '.$self->o('rnaseq_dir'),
      'mkdir -p '.$self->o('long_read_fastq_dir'),
    ];
}


sub pipeline_wide_parameters {
  my ($self) = @_;

  # set the logic names for repeat masking
  my $wide_repeat_logic_names;
  if ($self->o('use_repeatmodeler_to_mask')) {
    $wide_repeat_logic_names = [$self->o('full_repbase_logic_name'),$self->o('repeatmodeler_logic_name'),'dust'];
  } elsif ($self->o('replace_repbase_with_red_to_mask')) {
    $wide_repeat_logic_names = [$self->o('red_logic_name'),'dust'];
  } else {
    $wide_repeat_logic_names = [$self->o('full_repbase_logic_name'),'dust'];
  }

  return {
    %{$self->SUPER::pipeline_wide_parameters},
    skip_projection => $self->o('skip_projection'),
    skip_rnaseq => $self->o('skip_rnaseq'),
    skip_ncrna => $self->o('skip_ncrna'),
    skip_long_read => $self->o('skip_long_read'),
    skip_lastz => $self->o('skip_lastz'),
    skip_repeatmodeler => $self->o('skip_repeatmodeler'),
    wide_repeat_logic_names => $wide_repeat_logic_names,
  }
}


## See diagram for pipeline structure
sub pipeline_analyses {
  my ($self) = @_;

  my $db_name_template = "%s_%s_%s_%s";
  my ($load_assembly_pipe_db, $load_assembly_pipe_url, $load_assembly_guihive) = $self->get_meta_db_information(
      undef,
      sprintf($db_name_template, $self->o('dbowner'), $self->o('production_name'), 'load_assembly', $self->o('release_number')),
      $self->o('pipe_db_server')
    );
  my ($repeat_masking_pipe_db, $repeat_masking_pipe_url, $repeat_masking_guihive) = $self->get_meta_db_information(
      undef,
      sprintf($db_name_template, $self->o('dbowner'), $self->o('production_name'), 'repeat_masking', $self->o('release_number')),
      $self->o('pipe_db_server')
    );
  my ($refseq_import_pipe_db, $refseq_import_pipe_url, $refseq_import_guihive) = $self->get_meta_db_information(
      undef,
      sprintf($db_name_template, $self->o('dbowner'), $self->o('production_name'), 'refseq_import', $self->o('release_number')),
      $self->o('pipe_db_server')
    );
  my ($lastz_pipe_db, $lastz_pipe_url, $lastz_guihive) = $self->get_meta_db_information(
      undef,
      sprintf($db_name_template, $self->o('dbowner'), $self->o('production_name'), 'lastz_pipe', $self->o('release_number')),
      $self->o('pipe_db_server')
    );
  my ($projection_pipe_db, $projection_pipe_url, $projection_guihive) = $self->get_meta_db_information(
      undef,
      sprintf($db_name_template, $self->o('dbowner'), $self->o('production_name'), 'projection', $self->o('release_number')),
      $self->o('pipe_db_server')
    );
  my ($homology_pipe_db, $homology_pipe_url, $homology_guihive) = $self->get_meta_db_information(
      undef,
      sprintf($db_name_template, $self->o('dbowner'), $self->o('production_name'), 'homology', $self->o('release_number')),
      $self->o('pipe_db_server')
    );
  my ($best_targeted_pipe_db, $best_targeted_pipe_url, $best_targeted_guihive) = $self->get_meta_db_information(
      undef,
      sprintf($db_name_template, $self->o('dbowner'), $self->o('production_name'), 'best_targeted', $self->o('release_number')),
      $self->o('pipe_db_server')
    );
  my ($igtr_pipe_db, $igtr_pipe_url, $igtr_guihive) = $self->get_meta_db_information(
      undef,
      sprintf($db_name_template, $self->o('dbowner'), $self->o('production_name'), 'igtr', $self->o('release_number')),
      $self->o('pipe_db_server')
    );
  my ($short_ncrna_pipe_db, $short_ncrna_pipe_url, $short_ncrna_guihive) = $self->get_meta_db_information(
      undef,
      sprintf($db_name_template, $self->o('dbowner'), $self->o('production_name'), 'short_ncrna', $self->o('release_number')),
      $self->o('pipe_db_server')
    );
  my ($rnaseq_pipe_db, $rnaseq_pipe_url, $rnaseq_guihive) = $self->get_meta_db_information(
      undef,
      sprintf($db_name_template, $self->o('dbowner'), $self->o('production_name'), 'rnaseq', $self->o('release_number')),
      $self->o('pipe_db_server')
    );
  my ($long_read_pipe_db, $long_read_pipe_url, $long_read_guihive) = $self->get_meta_db_information(
      undef,
      sprintf($db_name_template, $self->o('dbowner'), $self->o('production_name'), 'long_read', $self->o('release_number')),
      $self->o('pipe_db_server')
    );
  my ($homology_rnaseq_pipe_db, $homology_rnaseq_pipe_url, $homology_rnaseq_guihive) = $self->get_meta_db_information(
      undef,
      sprintf($db_name_template, $self->o('dbowner'), $self->o('production_name'), 'homology_rnaseq', $self->o('release_number')),
      $self->o('pipe_db_server')
    );
  my ($transcript_finalisation_pipe_db, $transcript_finalisation_pipe_url, $transcript_finalisation_guihive) = $self->get_meta_db_information(
      undef,
      sprintf($db_name_template, $self->o('dbowner'), $self->o('production_name'), 'set_finalisation', $self->o('release_number')),
      $self->o('pipe_db_server')
    );
  my ($core_db_finalisation_pipe_db, $core_db_finalisation_pipe_url, $core_db_finalisation_guihive) = $self->get_meta_db_information(
      undef,
      sprintf($db_name_template, $self->o('dbowner'), $self->o('production_name'), 'db_finalisation', $self->o('release_number')),
      $self->o('pipe_db_server')
    );
  my ($otherfeatures_db_pipe_db, $otherfeatures_db_pipe_url, $otherfeatures_db_guihive) = $self->get_meta_db_information(
      undef,
      sprintf($db_name_template, $self->o('dbowner'), $self->o('production_name'), 'otherfeatures_db', $self->o('release_number')),
      $self->o('pipe_db_server')
    );
  my ($rnaseq_db_pipe_db, $rnaseq_db_pipe_url, $rnaseq_db_guihive) = $self->get_meta_db_information(
      undef,
      sprintf($db_name_template, $self->o('dbowner'), $self->o('production_name'), 'rnaseq_db', $self->o('release_number')),
      $self->o('pipe_db_server')
    );


  return [
    {
      -logic_name => 'download_rnaseq_csv',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveDownloadCsvENA',
      -rc_name => '1GB',
      -parameters => {
        study_accession => $self->o('rnaseq_study_accession'),
        taxon_id => $self->o('species_taxon_id'),
        inputfile => $self->o('rnaseq_summary_file'),
        paired_end_only => $self->o('paired_end_only'),
      },
      -flow_into => {
        1 => ['download_genus_rnaseq_csv'],
      },
      -input_ids  => [
        {
          assembly_name => $self->o('assembly_name'),
          assembly_accession => $self->o('assembly_accession'),
          assembly_refseq_accession => $self->o('assembly_refseq_accession'),
        },
      ],
    },

    {
      -logic_name => 'download_genus_rnaseq_csv',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveDownloadCsvENA',
      -rc_name => '1GB',
      -parameters => {
        study_accession => $self->o('rnaseq_study_accession'),
        taxon_id => $self->o('genus_taxon_id'),
        inputfile => $self->o('rnaseq_summary_file_genus'),
      },
      -flow_into => {
        1 => ['download_long_read_csv'],
      },
    },

    {
      -logic_name => 'download_long_read_csv',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveDownloadCsvENA',
      -rc_name => '1GB',
      -parameters => {
        study_accession => $self->o('long_read_study_accession'),
        taxon_id => $self->o('species_taxon_id'),
        inputfile => $self->o('long_read_summary_file'),
        read_type => 'isoseq',
      },
      -flow_into => {
        1 => ['download_genus_long_read_csv'],
      },
    },

    {
      -logic_name => 'download_genus_long_read_csv',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveDownloadCsvENA',
      -rc_name => '1GB',
      -parameters => {
        study_accession => $self->o('long_read_study_accession'),
        taxon_id => $self->o('genus_taxon_id'),
        inputfile => $self->o('long_read_summary_file_genus'),
        read_type => 'isoseq',
      },
      -flow_into => {
        1 => ['create_load_assembly_pipeline_job'],
      },
    },

    {
      -logic_name => 'create_load_assembly_pipeline_job',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
      -parameters => {
        column_names => ['meta_pipeline_db', 'ehive_url', 'pipeline_name', 'external_link'],
        inputlist => [[$load_assembly_pipe_db, $load_assembly_pipe_url, 'load_assembly_'.$self->o('production_name'), $load_assembly_guihive]],
        guihive_host => $self->o('guihive_host'),
        guihive_port => $self->o('guihive_port'),
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        '2->A' => ['initialise_load_assembly'],
        'A->1' => ['create_registry']
      }
    },

    {
      -logic_name => 'initialise_load_assembly',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineInit',
      -parameters => {
        hive_config => $self->o('hive_load_assembly_config'),
        databases => ['reference_db', 'dna_db'],
        reference_db => $self->o('reference_db'),
        dna_db => $self->o('dna_db'),
        enscode_root_dir => $self->o('enscode_root_dir'),
        extra_parameters => {
          output_path => $self->o('output_path'),
          user_r => $self->o('user_r'),
          dna_db_server => $self->o('dna_db_server'),
          dna_db_port => $self->o('dna_db_port'),
          repbase_logic_name => $self->o('repbase_logic_name'),
          release_number => $self->o('release_number'),
          species_name => $self->o('species_name'),
          production_name => $self->o('production_name'),
          taxon_id => $self->o('taxon_id'),
          wgs_id => $self->o('wgs_id'),
          assembly_name => $self->o('assembly_name'),
          assembly_accession => $self->o('assembly_accession'),
          stable_id_prefix => $self->o('stable_id_prefix'),
          species_url => $self->o('species_url'),
          load_toplevel_only => $self->o('load_toplevel_only'),
          custom_toplevel_file_path => $self->o('custom_toplevel_file_path'),
          use_repeatmodeler_to_mask => $self->o('use_repeatmodeler_to_mask'),
          replace_repbase_with_red_to_mask => $self->o('replace_repbase_with_red_to_mask'),
          projection_source_db_name => $self->o('projection_source_db_name'),
        },
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        1 => ['run_load_assembly'],
      },
    },

    {
      -logic_name => 'run_load_assembly',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineRun',
      -parameters => {
        beekeeper_script => $self->o('hive_beekeeper_script'),
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
    },

    {
      -logic_name => 'create_registry',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::CreateRegistry',
      -parameters => {
        compara_db => $self->o('compara_db'),
        projection_source_db => $self->o('projection_source_db'),
        target_db => $self->o('reference_db'),
        production_db => $self->o('production_db'),
        registry_file => $self->o('registry_file'),
      },
      -rc_name => 'default',
      -flow_into => {
        1 => ['create_repeat_masking_pipeline_jobs', 'fan_refseq_import'],
      },
    },

###############################################################################
#
# REFSEQ ANNOTATION
#
###############################################################################
    {
      -logic_name => 'fan_refseq_import',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
      -parameters => {
        cmd => 'if [ -n "#assembly_refseq_accession#" ]; then exit 0; else exit 42;fi',
        return_codes_2_branches => {'42' => 2},
      },
      -rc_name => 'default',
      -flow_into  => {
        1 => ['create_refseq_import_jobs'],
      },
    },

    {
      -logic_name => 'create_refseq_import_jobs',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
      -parameters => {
        column_names => ['meta_pipeline_db', 'ehive_url', 'pipeline_name', 'external_link'],
        inputlist => [[$refseq_import_pipe_db, $refseq_import_pipe_url, 'refseq_import_'.$self->o('production_name'), $refseq_import_guihive]],
        guihive_host => $self->o('guihive_host'),
        guihive_port => $self->o('guihive_port'),
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        2 => ['initialise_refseq_import'],
      }
    },

    {
      -logic_name => 'initialise_refseq_import',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineInit',
      -parameters => {
        hive_config => $self->o('hive_refseq_import_config'),
        databases => ['refseq_db', 'dna_db'],
        refseq_db => $self->o('refseq_db'),
        dna_db => $self->o('dna_db'),
        enscode_root_dir => $self->o('enscode_root_dir'),
        extra_parameters => {
          output_path => $self->o('output_path'),
          user_r => $self->o('user_r'),
          dna_db_server => $self->o('dna_db_server'),
          dna_db_port => $self->o('dna_db_port'),
          databases_server => $self->o('databases_server'),
          databases_port => $self->o('databases_port'),
          release_number => $self->o('release_number'),
          production_name => $self->o('production_name'),
          assembly_name => $self->o('assembly_name'),
          assembly_refseq_accession => $self->o('assembly_refseq_accession'),
        },
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        1 => ['run_refseq_import'],
      },
    },

    {
      -logic_name => 'run_refseq_import',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineRun',
      -parameters => {
        beekeeper_script => $self->o('hive_beekeeper_script'),
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
    },


    {
      -logic_name => 'create_repeat_masking_pipeline_jobs',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
      -parameters => {
        column_names => ['meta_pipeline_db', 'ehive_url', 'pipeline_name', 'external_link'],
        inputlist => [[$repeat_masking_pipe_db, $repeat_masking_pipe_url, 'repeat_masking_'.$self->o('production_name'), $repeat_masking_guihive]],
        guihive_host => $self->o('guihive_host'),
        guihive_port => $self->o('guihive_port'),
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        '2->A' => ['initialise_repeat_masking'],
        'A->1' => ['genome_prep_sanity_checks'],
      }
    },

    {
      -logic_name => 'initialise_repeat_masking',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineInit',
      -parameters => {
        hive_config => $self->o('hive_repeat_masking_config'),
        databases => ['reference_db', 'dna_db'],
        reference_db => $self->o('reference_db'),
        dna_db => $self->o('dna_db'),
        enscode_root_dir => $self->o('enscode_root_dir'),
        extra_parameters => {
          output_path => $self->o('output_path'),
          user_r => $self->o('user_r'),
          dna_db_server => $self->o('dna_db_server'),
          dna_db_port => $self->o('dna_db_port'),
          release_number => $self->o('release_number'),
          production_name => $self->o('production_name'),
          assembly_name => $self->o('assembly_name'),
          repbase_logic_name => $self->o('repbase_logic_name'),
          repbase_library => $self->o('repbase_library'),
          species_name => $self->o('species_name'),
          use_genome_flatfile => $self->o('use_genome_flatfile'),
          skip_repeatmodeler => $self->o('skip_repeatmodeler'),
          replace_repbase_with_red_to_mask => $self->o('replace_repbase_with_red_to_mask'),
          red_logic_name => $self->o('red_logic_name'),
          repeatmodeler_library => $self->o('repeatmodeler_library'),
          use_repeatmodeler_to_mask => $self->o('use_repeatmodeler_to_mask'),
        },
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        1 => ['run_repeat_masking'],
      },
    },

    {
      -logic_name => 'run_repeat_masking',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineRun',
      -parameters => {
        beekeeper_script => $self->o('hive_beekeeper_script'),
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
    },


    {
      -logic_name => 'genome_prep_sanity_checks',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveAnalysisSanityCheck',
      -parameters => {
        target_db => $self->o('dna_db'),
        sanity_check_type => 'genome_preparation_checks',
        min_allowed_feature_counts => get_analysis_settings('Bio::EnsEMBL::Analysis::Hive::Config::SanityChecksStatic',
            'genome_preparation_checks')->{$self->o('uniprot_set')},
      },

      -flow_into =>  {
        1 => ['set_repeat_types'],
      },
      -rc_name    => '15GB',
    },


    {
      -logic_name => 'set_repeat_types',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
      -parameters => {
        cmd => 'perl '.$self->o('repeat_types_script').
          ' -user '.$self->o('reference_db', '-user').
          ' -pass '.$self->o('reference_db', '-pass').
          ' -host '.$self->o('reference_db','-host').
          ' -port '.$self->o('reference_db','-port').
          ' -dbpattern '.$self->o('reference_db','-dbname')
      },
      -rc_name => 'default',
      -flow_into => { 1 => ['backup_core_db'] },
    },


    {
      -logic_name => 'backup_core_db',
      -module     => 'Bio::EnsEMBL::Hive::RunnableDB::DatabaseDumper',
      -parameters => {
        src_db_conn => $self->o('dna_db'),
        output_file => catfile($self->o('output_path'), 'core_bak.sql.gz'),
        dump_options => $self->o('mysql_dump_options'),
      },
      -rc_name    => '2GB',
      -flow_into => {
        1 => ['assembly_loading_report', 'create_transcript_finalisation_pipeline_job'],
      },
    },


    {
      -logic_name => 'create_transcript_finalisation_pipeline_job',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
      -parameters => {
        column_names => ['meta_pipeline_db', 'ehive_url', 'pipeline_name', 'external_link'],
        inputlist => [[$transcript_finalisation_pipe_db, $transcript_finalisation_pipe_url, 'transcript_finalisation_'.$self->o('production_name'), $transcript_finalisation_guihive]],
        guihive_host => $self->o('guihive_host'),
        guihive_port => $self->o('guihive_port'),
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        '2->A' => ['initialise_transcript_finalisation'],
        'A->1' => ['create_core_db_finalisation_pipeline_job']
      }
    },

    {
      -logic_name => 'initialise_transcript_finalisation',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineInit',
      -parameters => {
        hive_config => $self->o('hive_transcript_finalisation_config'),
        enscode_root_dir => $self->o('enscode_root_dir'),
        databases => ['final_geneset_db', 'ncrna_db', 'dna_db'],
        final_geneset_db => $self->o('final_geneset_db'),
        ncrna_db => $self->o('ncrna_db'),
        dna_db => $self->o('dna_db'),
        extra_parameters => {
          output_path => $self->o('output_path'),
          user_r => $self->o('user_r'),
          dna_db_server => $self->o('dna_db_server'),
          dna_db_port => $self->o('dna_db_port'),
          databases_server => $self->o('databases_server'),
          databases_port => $self->o('databases_port'),
          release_number => $self->o('release_number'),
          production_name => $self->o('production_name'),
          species_name => $self->o('species_name'),
          use_genome_flatfile => $self->o('use_genome_flatfile'),
          skip_projection => $self->o('skip_projection'),
          skip_rnaseq => $self->o('skip_rnaseq'),
          skip_cleaning => $self->o('skip_cleaning'),
          layering_input_gene_dbs => [],
          utr_donor_dbs => [],
          split_intergenic_dbs => [],
          create_toplevel_dbs => [],
          uniprot_set => $self->o('uniprot_set'),
        },
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        '1->A' => ['fan_projection'],
        'A->1' => ['run_transcript_finalisation'],
      },
    },

    {
      -logic_name => 'run_transcript_finalisation',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineRun',
      -parameters => {
        beekeeper_script => $self->o('hive_beekeeper_script'),
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
    },

    {
      -logic_name => 'assembly_loading_report',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
      -parameters => {
        cmd => 'perl '.$self->o('loading_report_script').
          ' -user '.$self->o('user_r').
          ' -host '.$self->o('dna_db','-host').
          ' -port '.$self->o('dna_db','-port').
          ' -dbname '.$self->o('dna_db','-dbname').
          ' -report_type assembly_loading'.
          ' > '.catfile($self->o('output_path'), 'loading_report.txt'),
      },
      -rc_name => 'default',
      -flow_into => { 1 => ['email_loading_report'] },
    },

    {
      -logic_name => 'email_loading_report',
      -module => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::TextfileByEmail',
      -parameters => {
        email => $self->o('email_address'),
        subject => 'AUTOMATED REPORT: assembly loading and feature annotation for '.$self->o('dna_db','-dbname').' completed',
        text => 'Assembly loading and feature annotation have completed for '.$self->o('dna_db','-dbname').". Basic stats can be found below",
        file => catfile($self->o('output_path'), 'loading_report.txt'),
      },
      -rc_name => 'default',
      -flow_into => {
        1 =>['repeat_masker_coverage'],
      },
    },


    {
      -logic_name => 'repeat_masker_coverage',
      -module => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveRepeatCoverage',
      -parameters => {
        source_db => $self->o('reference_db'),
        repeat_logic_names => '#wide_repeat_logic_names#',
        coord_system_version => '#assembly_name#',
        email => $self->o('email_address'),
      },
      -rc_name => '10GB',
      -flow_into => {
        1 =>['repeatmodeler_coverage'],
      },
    },


    {
      -logic_name => 'repeatmodeler_coverage',
      -module => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveRepeatCoverage',
      -parameters => {
        source_db => $self->o('reference_db'),
        repeat_logic_names => [$self->o('repeatmodeler_logic_name')],
        coord_system_version => '#assembly_name#',
        email => $self->o('email_address'),
      },
      -rc_name => '4GB',
    },

    {
      -logic_name => 'skip_lastz',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
      -parameters => {
        cmd => 'if [ #skip_lastz# -ne 0 ]; then exit 42; else exit 0;fi',
        return_codes_2_branches => {'42' => 2},
      },
      -rc_name => 'default',
      -flow_into  => {
        1 => ['create_lastz_jobs'],
      },
    },

    {
      -logic_name => 'create_lastz_jobs',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
      -parameters => {
        column_names => ['meta_pipeline_db', 'ehive_url', 'pipeline_name', 'external_link'],
        inputlist => [[$lastz_pipe_db, $lastz_pipe_url, 'lastz_'.$self->o('production_name'), $lastz_guihive]],
        guihive_host => $self->o('guihive_host'),
        guihive_port => $self->o('guihive_port'),
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        2 => ['initialise_lastz'],
      }
    },

    {
      -logic_name => 'initialise_lastz',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineInit',
      -parameters => {
        hive_config => $self->o('hive_lastz_config'),
        databases => ['projection_source_db', 'compara_db', 'dna_db'],
        projection_source_db => $self->o('projection_source_db'),
        compara_db => $self->o('compara_db'),
        dna_db => $self->o('dna_db'),
        enscode_root_dir => $self->o('enscode_root_dir'),
        extra_parameters => {
          output_path => $self->o('output_path'),
          user_r => $self->o('user_r'),
          dna_db_server => $self->o('dna_db_server'),
          dna_db_port => $self->o('dna_db_port'),
          release_number => $self->o('release_number'),
          production_name => $self->o('production_name'),
          species_name => $self->o('species_name'),
          registry_file => $self->o('registry_file'),
          projection_source_db_name => $self->o('projection_source_db_name'),
          projection_source_production_name => $self->o('projection_source_production_name'),
        },
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        1 => ['run_lastz'],
      },
    },

    {
      -logic_name => 'run_lastz',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineRun',
      -parameters => {
        beekeeper_script => $self->o('hive_beekeeper_script'),
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
    },

    {
      -logic_name => 'fan_projection',
      -module     => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
      -parameters => {},
      -rc_name    => 'default',
      -flow_into  => {
        '1->A' => ['skip_projection'],
        'A->1' => ['create_homology_pipeline_job'],
      },
    },

    {
      -logic_name => 'skip_projection',
      -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
      -parameters => {
        cmd => 'if [ #skip_projection# -ne 0 ]; then exit 42; else exit 0;fi',
        return_codes_2_branches => {'42' => 2},
      },
      -rc_name    => 'default',
      -flow_into  => {
        '1->A' => ['skip_lastz'],
        'A->1' => ['create_projection_pipeline_jobs'],
      },
    },

    {
      -logic_name => 'create_projection_pipeline_jobs',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
      -parameters => {
        column_names => ['meta_pipeline_db', 'ehive_url', 'pipeline_name', 'external_link'],
        inputlist => [[$projection_pipe_db, $projection_pipe_url, 'projection_'.$self->o('production_name'), $projection_guihive]],
        guihive_host => $self->o('guihive_host'),
        guihive_port => $self->o('guihive_port'),
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        2 => ['initialise_projection'],
      }
    },

    {
      -logic_name => 'initialise_projection',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineInit',
      -parameters => {
        hive_config => $self->o('hive_projection_config'),
        databases => ['projection_lastz_db', 'selected_projection_db', 'projection_source_db', 'dna_db'],
        selected_projection_db => $self->o('selected_projection_db'),
        projection_source_db => $self->o('projection_source_db'),
        projection_lastz_db => $lastz_pipe_db,
        dna_db => $self->o('dna_db'),
        enscode_root_dir => $self->o('enscode_root_dir'),
        extra_parameters => {
          output_path => $self->o('output_path'),
          user_r => $self->o('user_r'),
          dna_db_server => $self->o('dna_db_server'),
          dna_db_port => $self->o('dna_db_port'),
          databases_server => $self->o('databases_server'),
          databases_port => $self->o('databases_port'),
          release_number => $self->o('release_number'),
          production_name => $self->o('production_name'),
          projection_source_db_name => $self->o('projection_source_db_name'),
          uniprot_set => $self->o('uniprot_set'),
          transcript_selection_url => $transcript_finalisation_pipe_url,
        },
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        1 => ['run_projection'],
      },
    },

    {
      -logic_name => 'run_projection',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineRun',
      -parameters => {
        beekeeper_script => $self->o('hive_beekeeper_script'),
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
    },

    {
      -logic_name => 'create_homology_pipeline_job',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
      -parameters => {
        column_names => ['meta_pipeline_db', 'ehive_url', 'pipeline_name', 'external_link'],
        inputlist => [[$homology_pipe_db, $homology_pipe_url, 'homology_'.$self->o('production_name'), $homology_guihive]],
        guihive_host => $self->o('guihive_host'),
        guihive_port => $self->o('guihive_port'),
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        '2->A' => ['initialise_homology'],
        'A->1' => ['create_best_targeted_pipeline_job']
      }
    },

    {
      -logic_name => 'initialise_homology',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineInit',
      -parameters => {
        hive_config => $self->o('hive_homology_config'),
        databases => ['genblast_db', 'genblast_nr_db', 'killlist_db', 'dna_db'],
        genblast_db => $self->o('genblast_db'),
        genblast_nr_db => $self->o('genblast_nr_db'),
        killlist_db => $self->o('killlist_db'),
        dna_db => $self->o('dna_db'),
        enscode_root_dir => $self->o('enscode_root_dir'),
        extra_parameters => {
          output_path => $self->o('output_path'),
          user_r => $self->o('user_r'),
          dna_db_server => $self->o('dna_db_server'),
          dna_db_port => $self->o('dna_db_port'),
          databases_server => $self->o('databases_server'),
          databases_port => $self->o('databases_port'),
          release_number => $self->o('release_number'),
          production_name => $self->o('production_name'),
          species_name => $self->o('species_name'),
          taxon_id => $self->o('taxon_id'),
          uniprot_set => $self->o('uniprot_set'),
          use_genome_flatfile => $self->o('use_genome_flatfile'),
          transcript_selection_url => $transcript_finalisation_pipe_url,
        },
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        1 => ['run_homology'],
      },
    },

    {
      -logic_name => 'run_homology',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineRun',
      -parameters => {
        beekeeper_script => $self->o('hive_beekeeper_script'),
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
    },

    {
      -logic_name => 'create_best_targeted_pipeline_job',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
      -parameters => {
        column_names => ['meta_pipeline_db', 'ehive_url', 'pipeline_name', 'external_link'],
        inputlist => [[$best_targeted_pipe_db, $best_targeted_pipe_url, 'best_targeted_'.$self->o('production_name'), $best_targeted_guihive]],
        guihive_host => $self->o('guihive_host'),
        guihive_port => $self->o('guihive_port'),
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        '2->A' => ['initialise_best_targeted'],
        'A->1' => ['create_igtr_pipeline_job']
      }
    },

    {
      -logic_name => 'initialise_best_targeted',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineInit',
      -parameters => {
        hive_config => $self->o('hive_best_targeted_config'),
        databases => ['cdna_db', 'best_targeted_db', 'killlist_db', 'dna_db'],
        cdna_db => $self->o('cdna_db'),
        best_targeted_db => $self->o('best_targeted_db'),
        killlist_db => $self->o('killlist_db'),
        dna_db => $self->o('dna_db'),
        enscode_root_dir => $self->o('enscode_root_dir'),
        extra_parameters => {
          output_path => $self->o('output_path'),
          user_r => $self->o('user_r'),
          dna_db_server => $self->o('dna_db_server'),
          dna_db_port => $self->o('dna_db_port'),
          databases_server => $self->o('databases_server'),
          databases_port => $self->o('databases_port'),
          release_number => $self->o('release_number'),
          production_name => $self->o('production_name'),
          species_name => $self->o('species_name'),
          taxon_id => $self->o('taxon_id'),
          wide_repeat_logic_names => '#wide_repeat_logic_names#',
          transcript_selection_url => $transcript_finalisation_pipe_url,
        },
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        1 => ['run_best_targeted'],
      },
    },

    {
      -logic_name => 'run_best_targeted',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineRun',
      -parameters => {
        beekeeper_script => $self->o('hive_beekeeper_script'),
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
    },

    {
      -logic_name => 'create_igtr_pipeline_job',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
      -parameters => {
        column_names => ['meta_pipeline_db', 'ehive_url', 'pipeline_name', 'external_link'],
        inputlist => [[$igtr_pipe_db, $igtr_pipe_url, 'igtr_'.$self->o('production_name'), $igtr_guihive]],
        guihive_host => $self->o('guihive_host'),
        guihive_port => $self->o('guihive_port'),
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        '2->A' => ['initialise_igtr'],
        'A->1' => ['fan_short_ncrna']
      }
    },

    {
      -logic_name => 'initialise_igtr',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineInit',
      -parameters => {
        hive_config => $self->o('hive_igtr_config'),
        databases => ['ig_tr_db', 'dna_db'],
        ig_tr_db => $self->o('ig_tr_db'),
        dna_db => $self->o('dna_db'),
        enscode_root_dir => $self->o('enscode_root_dir'),
        extra_parameters => {
          output_path => $self->o('output_path'),
          user_r => $self->o('user_r'),
          dna_db_server => $self->o('dna_db_server'),
          dna_db_port => $self->o('dna_db_port'),
          databases_server => $self->o('databases_server'),
          databases_port => $self->o('databases_port'),
          release_number => $self->o('release_number'),
          production_name => $self->o('production_name'),
          species_name => $self->o('species_name'),
          uniprot_set => $self->o('uniprot_set'),
          use_genome_flatfile => $self->o('use_genome_flatfile'),
          transcript_selection_url => $transcript_finalisation_pipe_url,
        },
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        1 => ['run_igtr'],
      },
    },

    {
      -logic_name => 'run_igtr',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineRun',
      -parameters => {
        beekeeper_script => $self->o('hive_beekeeper_script'),
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
    },

    {
      -logic_name => 'fan_short_ncrna',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
      -parameters => {},
      -rc_name => 'default',
      -flow_into  => {
        '1->A' => ['skip_ncrna'],
        'A->1' => ['fan_rnaseq'],
      },
    },

    {
      -logic_name => 'skip_ncrna',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
      -parameters => {
        cmd => 'if [ #skip_ncrna# -eq 0 ]; then exit 0; else exit 42;fi',
        return_codes_2_branches => {'42' => 2},
      },
      -rc_name => 'default',
      -flow_into  => {
        1 => ['create_short_ncrna_pipeline_job'],
      },
    },

    {
      -logic_name => 'create_short_ncrna_pipeline_job',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
      -parameters => {
        column_names => ['meta_pipeline_db', 'ehive_url', 'pipeline_name', 'external_link'],
        inputlist => [[$short_ncrna_pipe_db, $short_ncrna_pipe_url, 'short_ncrna_'.$self->o('production_name'), $short_ncrna_guihive]],
        guihive_host => $self->o('guihive_host'),
        guihive_port => $self->o('guihive_port'),
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        2 => ['initialise_short_ncrna'],
      }
    },

    {
      -logic_name => 'initialise_short_ncrna',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineInit',
      -parameters => {
        hive_config => $self->o('hive_short_ncrna_config'),
        databases => ['ncrna_db', 'dna_db'],
        ncrna_db => $self->o('ncrna_db'),
        dna_db => $self->o('dna_db'),
        enscode_root_dir => $self->o('enscode_root_dir'),
        extra_parameters => {
          output_path => $self->o('output_path'),
          user_r => $self->o('user_r'),
          dna_db_server => $self->o('dna_db_server'),
          dna_db_port => $self->o('dna_db_port'),
          databases_server => $self->o('databases_server'),
          databases_port => $self->o('databases_port'),
          release_number => $self->o('release_number'),
          production_name => $self->o('production_name'),
          species_name => $self->o('species_name'),
          taxon_id => $self->o('taxon_id'),
          uniprot_set => $self->o('uniprot_set'),
          repbase_logic_name => $self->o('repbase_logic_name'),
          use_genome_flatfile => $self->o('use_genome_flatfile'),
        },
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        1 => ['run_short_ncrna'],
      },
    },

    {
      -logic_name => 'run_short_ncrna',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineRun',
      -parameters => {
        beekeeper_script => $self->o('hive_beekeeper_script'),
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
    },

    {
      -logic_name => 'fan_rnaseq',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
      -parameters => {},
      -rc_name => 'default',
      -flow_into  => {
        '1->A' => ['skip_rnaseq'],
        'A->1' => ['fan_long_read'],
      },
    },

    {
      -logic_name => 'skip_rnaseq',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
      -parameters => {
        cmd => 'if [ #skip_rnaseq# -eq 0 ]; then exit 0; else exit 42;fi',
        return_codes_2_branches => {'42' => 2},
      },
      -rc_name => 'default',
      -flow_into  => {
        1 => ['create_rnaseq_pipeline_job'],
      },
    },

    {
      -logic_name => 'create_rnaseq_pipeline_job',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
      -parameters => {
        column_names => ['meta_pipeline_db', 'ehive_url', 'pipeline_name', 'external_link'],
        inputlist => [[$rnaseq_pipe_db, $rnaseq_pipe_url, 'rnaseq_'.$self->o('production_name'), $rnaseq_guihive]],
        guihive_host => $self->o('guihive_host'),
        guihive_port => $self->o('guihive_port'),
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        '2->A' => ['initialise_rnaseq'],
        'A->1' => ['create_homology_rnaseq_pipeline_job'],
      }

    },

    {
      -logic_name => 'initialise_rnaseq',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineInit',
      -parameters => {
        hive_config => $self->o('hive_rnaseq_config'),
        databases => ['rnaseq_refine_db', 'rnaseq_for_layer_nr_db', 'rnaseq_for_layer_db', 'dna_db'],
        rnaseq_refine_db => $self->o('rnaseq_refine_db'),
        rnaseq_for_layer_db => $self->o('rnaseq_for_layer_db'),
        rnaseq_for_layer_nr_db => $self->o('rnaseq_for_layer_nr_db'),
        dna_db => $self->o('dna_db'),
        enscode_root_dir => $self->o('enscode_root_dir'),
        extra_parameters => {
          output_path => $self->o('output_path'),
          user_r => $self->o('user_r'),
          dna_db_server => $self->o('dna_db_server'),
          dna_db_port => $self->o('dna_db_port'),
          databases_server => $self->o('databases_server'),
          databases_port => $self->o('databases_port'),
          release_number => $self->o('release_number'),
          production_name => $self->o('production_name'),
          species_name => $self->o('species_name'),
          taxon_id => $self->o('taxon_id'),
          uniprot_set => $self->o('uniprot_set'),
          use_genome_flatfile => $self->o('use_genome_flatfile'),
          transcript_selection_url => $transcript_finalisation_pipe_url,
          homology_rnaseq_url => $homology_rnaseq_pipe_url,
        },
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        1 => ['run_rnaseq'],
      },
    },

    {
      -logic_name => 'run_rnaseq',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineRun',
      -parameters => {
        beekeeper_script => $self->o('hive_beekeeper_script'),
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
    },


    {
      -logic_name => 'create_homology_rnaseq_pipeline_job',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
      -parameters => {
        column_names => ['meta_pipeline_db', 'ehive_url', 'pipeline_name', 'external_link'],
        inputlist => [[$homology_rnaseq_pipe_db, $homology_rnaseq_pipe_url, 'homology_rnaseq_'.$self->o('production_name'), $homology_rnaseq_guihive]],
        guihive_host => $self->o('guihive_host'),
        guihive_port => $self->o('guihive_port'),
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        2 => ['initialise_homology_rnaseq'],
      }
    },

    {
      -logic_name => 'initialise_homology_rnaseq',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineInit',
      -parameters => {
        hive_config => $self->o('hive_homology_rnaseq_config'),
        databases => ['genblast_db', 'rnaseq_refine_db', 'genblast_rnaseq_support_nr_db', 'dna_db'],
        genblast_db => $self->o('genblast_db'),
        rnaseq_refine_db => undef,
        genblast_rnaseq_support_nr_db => $self->o('genblast_rnaseq_support_nr_db'),
        dna_db => $self->o('dna_db'),
        enscode_root_dir => $self->o('enscode_root_dir'),
        extra_parameters => {
          output_path => $self->o('output_path'),
          user_r => $self->o('user_r'),
          dna_db_server => $self->o('dna_db_server'),
          dna_db_port => $self->o('dna_db_port'),
          databases_server => $self->o('databases_server'),
          databases_port => $self->o('databases_port'),
          release_number => $self->o('release_number'),
          production_name => $self->o('production_name'),
          species_name => $self->o('species_name'),
          taxon_id => $self->o('taxon_id'),
          uniprot_set => $self->o('uniprot_set'),
          use_genome_flatfile => $self->o('use_genome_flatfile'),
          transcript_selection_url => $transcript_finalisation_pipe_url,
        },
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        1 => ['run_homology_rnaseq'],
      },
    },

    {
      -logic_name => 'run_homology_rnaseq',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineRun',
      -parameters => {
        beekeeper_script => $self->o('hive_beekeeper_script'),
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
    },

    {
      -logic_name => 'fan_long_read',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
      -parameters => {},
      -rc_name => 'default',
      -flow_into  => {
        1 => ['skip_long_read'],
      },
    },

    {
      -logic_name => 'skip_long_read',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
      -parameters => {
        cmd => 'if [ #skip_long_read# -eq 0 ]; then exit 0; else exit 42;fi',
        return_codes_2_branches => {'42' => 2},
      },
      -rc_name => 'default',
      -flow_into  => {
        1 => ['create_long_read_pipeline_job'],
      },
    },

    {
      -logic_name => 'create_long_read_pipeline_job',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
      -parameters => {
        column_names => ['meta_pipeline_db', 'ehive_url', 'pipeline_name', 'external_link'],
        inputlist => [[$long_read_pipe_db, $long_read_pipe_url, 'long_read_'.$self->o('production_name'), $long_read_guihive]],
        guihive_host => $self->o('guihive_host'),
        guihive_port => $self->o('guihive_port'),
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        2 => ['initialise_long_read'],
      }
    },

    {
      -logic_name => 'initialise_long_read',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineInit',
      -parameters => {
        hive_config => $self->o('hive_long_read_config'),
        databases => ['long_read_final_db', 'dna_db'],
        long_read_final_db => $self->o('long_read_final_db'),
        dna_db => $self->o('dna_db'),
        enscode_root_dir => $self->o('enscode_root_dir'),
        extra_parameters => {
          output_path => $self->o('output_path'),
          user_r => $self->o('user_r'),
          dna_db_server => $self->o('dna_db_server'),
          dna_db_port => $self->o('dna_db_port'),
          databases_server => $self->o('databases_server'),
          databases_port => $self->o('databases_port'),
          release_number => $self->o('release_number'),
          production_name => $self->o('production_name'),
          species_name => $self->o('species_name'),
          long_read_summary_file => $self->o('long_read_summary_file'),
          long_read_summary_file_genus => $self->o('long_read_summary_file_genus'),
          use_genome_flatfile => $self->o('use_genome_flatfile'),
          transcript_selection_url => $transcript_finalisation_pipe_url,
        },
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        1 => ['run_long_read'],
      },
    },

    {
      -logic_name => 'run_long_read',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineRun',
      -parameters => {
        beekeeper_script => $self->o('hive_beekeeper_script'),
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
    },


    {
      -logic_name => 'create_core_db_finalisation_pipeline_job',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
      -parameters => {
        column_names => ['meta_pipeline_db', 'ehive_url', 'pipeline_name', 'external_link'],
        inputlist => [[$core_db_finalisation_pipe_db, $core_db_finalisation_pipe_url, 'core_db_finalisation_'.$self->o('production_name'), $core_db_finalisation_guihive]],
        guihive_host => $self->o('guihive_host'),
        guihive_port => $self->o('guihive_port'),
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        '2->A' => ['initialise_core_db_finalisation'],
        'A->1' => ['fan_data_dbs']
      }
    },

    {
      -logic_name => 'initialise_core_db_finalisation',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineInit',
      -parameters => {
        hive_config => $self->o('hive_core_db_finalisation_config'),
        databases => ['reference_db', 'final_geneset_db', 'dna_db'],
        reference_db => $self->o('reference_db'),
        final_geneset_db => $self->o('final_geneset_db'),
        dna_db => $self->o('dna_db'),
        enscode_root_dir => $self->o('enscode_root_dir'),
        extra_parameters => {
          output_path => $self->o('output_path'),
          user_r => $self->o('user_r'),
          dna_db_server => $self->o('dna_db_server'),
          dna_db_port => $self->o('dna_db_port'),
          databases_server => $self->o('databases_server'),
          databases_port => $self->o('databases_port'),
          release_number => $self->o('release_number'),
          production_name => $self->o('production_name'),
          species_name => $self->o('species_name'),
          uniprot_set => $self->o('uniprot_set'),
          registry_host => $self->o('registry_host'),
          registry_port => $self->o('registry_port'),
          registry_db => $self->o('registry_db'),
          assembly_name => $self->o('assembly_name'),
          assembly_accession => $self->o('assembly_accession'),
          stable_id_prefix => $self->o('stable_id_prefix'),
          stable_id_start => $self->o('stable_id_start'),
          mapping_required => $self->o('mapping_required'),
          skip_projection => $self->o('skip_projection'),
          skip_rnaseq => $self->o('skip_rnaseq'),
          mapping_db => $self->o('mapping_db'),
          projection_source_db_name => $self->o('projection_source_db_name'),
          use_genome_flatfile => $self->o('use_genome_flatfile'),
        },
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        1 => ['run_core_db_finalisation'],
      },
    },

    {
      -logic_name => 'run_core_db_finalisation',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineRun',
      -parameters => {
        beekeeper_script => $self->o('hive_beekeeper_script'),
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
    },


    {
      -logic_name => 'fan_data_dbs',
      -module     => 'Bio::EnsEMBL::Hive::RunnableDB::Dummy',
      -parameters => {},
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        1 => ['skip_rnaseq_db', 'skip_otherfeatures_db'],
      }
    },

    {
      -logic_name => 'skip_otherfeatures_db',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
      -parameters => {
        cmd => 'if [[ -n "#assembly_refseq_accession#" ]] || [[ #skip_long_read# -eq 0 ]] || [[ $(#cdna_query#) -gt #cdna_threshold# ]]; then exit 0; else exit 42;fi',
        return_codes_2_branches => {'42' => 2},
        cdna_query => 'mysql -h #expr(#cdna_db#->{-host})expr# -P #expr(#cdna_db#->{-port})expr# -u #expr(#cdna_db#->{-user})expr# -p#expr(#cdna_db#->{-pass})expr# #expr(#cdna_db#->{-dbname})expr# -NB -e "SELECT COUNT(*) FROM gene"',
        cdna_threshold => $self->o('cdna_threshold'),
        cdna_db => $self->o('cdna_db'),
      },
      -rc_name => 'default',
      -flow_into  => {
        1 => ['create_otherfeatures_db_pipeline_job'],
      },
    },

    {
      -logic_name => 'create_otherfeatures_db_pipeline_job',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
      -parameters => {
        column_names => ['meta_pipeline_db', 'ehive_url', 'pipeline_name', 'external_link'],
        inputlist => [[$otherfeatures_db_pipe_db, $otherfeatures_db_pipe_url, 'otherfeatures_db_'.$self->o('production_name'), $otherfeatures_db_guihive]],
        guihive_host => $self->o('guihive_host'),
        guihive_port => $self->o('guihive_port'),
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        2 => ['initialise_otherfeatures_db'],
      }
    },

    {
      -logic_name => 'initialise_otherfeatures_db',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineInit',
      -parameters => {
        hive_config => $self->o('hive_otherfeatures_db_config'),
        databases => ['cdna_db', 'refseq_db', 'otherfeatures_db', 'dna_db'],
        cdna_db => $self->o('cdna_db'),
        refseq_db => $self->o('refseq_db'),
        otherfeatures_db => $self->o('otherfeatures_db'),
        dna_db => $self->o('dna_db'),
        enscode_root_dir => $self->o('enscode_root_dir'),
        extra_parameters => {
          output_path => $self->o('output_path'),
          user_r => $self->o('user_r'),
          dna_db_server => $self->o('dna_db_server'),
          dna_db_port => $self->o('dna_db_port'),
          databases_server => $self->o('databases_server'),
          databases_port => $self->o('databases_port'),
          release_number => $self->o('release_number'),
          production_name => $self->o('production_name'),
          species_name => $self->o('species_name'),
          registry_host => $self->o('registry_host'),
          registry_port => $self->o('registry_port'),
          registry_db => $self->o('registry_db'),
          assembly_name => $self->o('assembly_name'),
          assembly_accession => $self->o('assembly_accession'),
          assembly_refseq_accession => $self->o('assembly_refseq_accession'),
          use_genome_flatfile => $self->o('use_genome_flatfile'),
        },
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        1 => ['run_otherfeatures_db'],
      },
    },

    {
      -logic_name => 'run_otherfeatures_db',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineRun',
      -parameters => {
        beekeeper_script => $self->o('hive_beekeeper_script'),
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
    },


    {
      -logic_name => 'skip_rnaseq_db',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
      -parameters => {
        cmd => 'if [ #skip_rnaseq# -eq 0 ]; then exit 0; else exit 42;fi',
        return_codes_2_branches => {'42' => 2},
      },
      -rc_name => 'default',
      -flow_into  => {
        1 => ['create_rnaseq_db_pipeline_job'],
      },
    },

    {
      -logic_name => 'create_rnaseq_db_pipeline_job',
      -module => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
      -parameters => {
        column_names => ['meta_pipeline_db', 'ehive_url', 'pipeline_name', 'external_link'],
        inputlist => [[$rnaseq_db_pipe_db, $rnaseq_db_pipe_url, 'rnaseq_db_'.$self->o('production_name'), $rnaseq_db_guihive]],
        guihive_host => $self->o('guihive_host'),
        guihive_port => $self->o('guihive_port'),
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        2 => ['initialise_rnaseq_db'],
      }
    },

    {
      -logic_name => 'initialise_rnaseq_db',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineInit',
      -parameters => {
        hive_config => $self->o('hive_rnaseq_db_config'),
        databases => ['rnaseq_db', 'rnaseq_refine_db', 'rnaseq_blast_db', 'dna_db'],
        rnaseq_db => $self->o('rnaseq_db'),
        rnaseq_refine_db => $self->o('rnaseq_refine_db'),
        rnaseq_blast_db => $self->o('rnaseq_blast_db'),
        dna_db => $self->o('dna_db'),
        enscode_root_dir => $self->o('enscode_root_dir'),
        extra_parameters => {
          output_path => $self->o('output_path'),
          user_r => $self->o('user_r'),
          dna_db_server => $self->o('dna_db_server'),
          dna_db_port => $self->o('dna_db_port'),
          databases_server => $self->o('databases_server'),
          databases_port => $self->o('databases_port'),
          release_number => $self->o('release_number'),
          production_name => $self->o('production_name'),
          species_name => $self->o('species_name'),
          registry_host => $self->o('registry_host'),
          registry_port => $self->o('registry_port'),
          registry_db => $self->o('registry_db'),
          assembly_name => $self->o('assembly_name'),
          assembly_accession => $self->o('assembly_accession'),
        },
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        1 => ['run_rnaseq_db'],
      },
    },

    {
      -logic_name => 'run_rnaseq_db',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveMetaPipelineRun',
      -parameters => {
        beekeeper_script => $self->o('hive_beekeeper_script'),
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
    },
  ];
}


sub resource_classes {
  my $self = shift;

  return {
    '1GB' => { LSF => $self->lsf_resource_builder('production', 1000, [$self->default_options->{'pipe_db_server'}, $self->default_options->{'dna_db_server'}], [$self->default_options->{'num_tokens'}])},
    '2GB' => { LSF => $self->lsf_resource_builder('production', 2000, [$self->default_options->{'pipe_db_server'}, $self->default_options->{'dna_db_server'}], [$self->default_options->{'num_tokens'}])},
    '4GB' => { LSF => $self->lsf_resource_builder('production', 4000, [$self->default_options->{'pipe_db_server'}, $self->default_options->{'dna_db_server'}], [$self->default_options->{'num_tokens'}])},
    '10GB' => { LSF => $self->lsf_resource_builder('production', 10000, [$self->default_options->{'pipe_db_server'}, $self->default_options->{'dna_db_server'}], [$self->default_options->{'num_tokens'}])},
    '15GB' => { LSF => $self->lsf_resource_builder('production', 15000, [$self->default_options->{'pipe_db_server'}, $self->default_options->{'dna_db_server'}], [$self->default_options->{'num_tokens'}])},
    'default' => { LSF => $self->lsf_resource_builder('production', 900, [$self->default_options->{'pipe_db_server'}, $self->default_options->{'dna_db_server'}], [$self->default_options->{'num_tokens'}])},
  }
}


1;
