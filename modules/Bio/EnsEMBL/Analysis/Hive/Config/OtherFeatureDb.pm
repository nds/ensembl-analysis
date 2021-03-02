=head1 LICENSE

Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
Copyright [2016-2020] EMBL-European Bioinformatics Institute

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

package Bio::EnsEMBL::Analysis::Hive::Config::OtherFeatureDb;

use strict;
use warnings;
use File::Spec::Functions;

use Bio::EnsEMBL::ApiVersion qw/software_version/;
use Bio::EnsEMBL::Analysis::Tools::Utilities qw(get_analysis_settings);
use Bio::EnsEMBL::Hive::PipeConfig::HiveGeneric_conf;
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
    'dbowner'                   => '' || $ENV{EHIVE_USER} || $ENV{USER},
    'pipeline_name'             => '' || $self->o('production_name').'_'.$self->o('ensembl_release'),
    'user_r'                    => '', # read only db user
    'user'                      => '', # write db user
    'password'                  => '', # password for write db user
    'server_set'                => '', # What server set to user, e.g. set1
    'pipe_db_server'            => '', # host for pipe db
    'databases_server'          => '', # host for general output dbs
    'dna_db_server'             => '', # host for dna db
    'pipe_db_port'              => '', # port for pipeline host
    'databases_port'            => '', # port for general output db host
    'dna_db_port'               => '', # port for dna db host
    'registry_host'             => '', # host for registry db
    'registry_port'             => '', # port for registry db
    'registry_db'               => '', # name for registry db
    'release_number'            => '' || $self->o('ensembl_release'),
    'species_name'              => '', # e.g. mus_musculus
    'production_name'           => '', # usually the same as species name but currently needs to be a unique entry for the production db, used in all core-like db names
    'output_path'               => '', # Lustre output dir. This will be the primary dir to house the assembly info and various things from analyses
    'assembly_name'             => '', # Name (as it appears in the assembly report file)
    'assembly_accession'        => '', # Versioned GCA assembly accession, e.g. GCA_001857705.1
    'assembly_refseq_accession' => '', # Versioned GCF accession, e.g. GCF_001857705.1
    'registry_file'             => '' || catfile($self->o('output_path'), "Databases.pm"), # Path to databse registry for LastaZ and Production sync
    'stable_id_prefix'          => '', # e.g. ENSPTR. When running a new annotation look up prefix in the assembly registry db
    'species_url'               => '', # sets species.url meta key
    'species_division'          => 'EnsemblVertebrates', # sets species.division meta key
    'uniprot_version'           => 'uniprot_2019_04', # What UniProt data dir to use for various analyses
    'mt_accession'              => undef, # This should be set to undef unless you know what you are doing. If you specify an accession, then you need to add the parameters to the load_mitochondrion analysis

    # Keys for custom loading, only set/modify if that's what you're doing
    'protein_entry_loc'            => catfile($self->o('base_blast_db_path'), 'uniprot', $self->o('uniprot_version'), 'entry_loc'), # Used by genscan blasts and optimise daf/paf. Don't change unless you know what you're doing


########################
# Pipe and ref db info
########################

    'projection_source_db_name'    => '', # This is generally a pre-existing db, like the current human/mouse core for example
    'projection_source_db_server'  => 'mysql-ens-mirror-1',
    'projection_source_db_port'    => '4240',
    'projection_source_production_name' => '',

    'compara_db_name'     => 'leanne_ensembl_compara_95',
    'compara_db_server'  => 'mysql-ens-genebuild-prod-5',
    'compara_db_port'    => 4531,

    # The following might not be known in advance, since the come from other pipelines
    # These values can be replaced in the analysis_base table if they're not known yet
    # If they are not needed (i.e. no projection or rnaseq) then leave them as is

    'assembly_provider_name'        => '',
    'assembly_provider_url'         => '',
    'annotation_provider_name'      => 'Ensembl',
    'annotation_provider_url'       => 'www.ensembl.org',

    'pipe_db_name'                  => $self->o('dbowner').'_'.$self->o('production_name').'_pipe_'.$self->o('release_number'),
    'dna_db_name'                   => $self->o('dbowner').'_'.$self->o('production_name').'_core_'.$self->o('release_number'),

    'cdna_db_server'               => $self->o('databases_server'),
    'cdna_db_port'                 => $self->o('databases_port'),

    'refseq_db_server'             => $self->o('databases_server'),
    'refseq_db_port'               => $self->o('databases_port'),

    'otherfeatures_db_server'      => $self->o('databases_server'),
    'otherfeatures_db_port'        => $self->o('databases_port'),

    # This is used for the ensembl_production and the ncbi_taxonomy databases
    'ensembl_release'              => $ENV{ENSEMBL_RELEASE}, # this is the current release version on staging to be able to get the correct database
    'production_db_server'         => 'mysql-ens-meta-prod-1',
    'production_db_port'           => '4483',


    databases_to_delete => ['cdna_db', 'refseq_db', 'otherfeatures_db'],#, 'projection_realign_db'

########################
# BLAST db paths
########################
    'base_blast_db_path'        => $ENV{BLASTDB_DIR},

######################################################
#
# Mostly constant settings
#
######################################################

    ensembl_analysis_script           => catdir($self->o('enscode_root_dir'), 'ensembl-analysis', 'scripts'),
    load_optimise_script              => catfile($self->o('ensembl_analysis_script'), 'genebuild', 'load_external_db_ids_and_optimize_af.pl'),

    ensembl_misc_script        => catdir($self->o('enscode_root_dir'), 'ensembl', 'misc-scripts'),
    meta_coord_script          => catfile($self->o('ensembl_misc_script'), 'meta_coord', 'update_meta_coord.pl'),
    meta_levels_script         => catfile($self->o('ensembl_misc_script'), 'meta_levels.pl'),
    frameshift_attrib_script   => catfile($self->o('ensembl_misc_script'), 'frameshift_transcript_attribs.pl'),
    select_canonical_script    => catfile($self->o('ensembl_misc_script'),'canonical_transcripts', 'select_canonical_transcripts.pl'),
    assembly_name_script       => catfile($self->o('ensembl_analysis_script'), 'update_assembly_name.pl'),


########################
# Extra db settings
########################

    'num_tokens' => 10,

########################
# Executable paths
########################


# Best targetted stuff

    exonerate_protein_pid => 95,
    exonerate_protein_cov => 50,
    exonerate_max_intron => 200000,

# RNA-seq pipeline stuff
    # You have the choice between:
    #  * using a csv file you already created
    #  * using a study_accession like PRJEB19386
    #  * using the taxon_id of your species
    # 'rnaseq_summary_file' should always be set. If 'taxon_id' or 'study_accession' are not undef
    # they will be used to retrieve the information from ENA and to create the csv file. In this case,
    # 'file_columns' and 'summary_file_delimiter' should not be changed unless you know what you are doing

    # If your reads are unpaired you may want to run on slices to avoid
    # making overlong rough models.  If you want to do this, specify a
    # slice length here otherwise it will default to whole chromosomes.
    slice_length => 10000000,

## Add in genewise path and put in matching code
    'genewise_pid'                        => '50',
    'genewise_cov'                        => '50',
    'genewise_region_padding'             => '50000',
    'genewise_calculate_coverage_and_pid' => '1',

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# No option below this mark should be modified
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
#
########################################################
# URLs for retrieving the INSDC contigs and RefSeq files
########################################################
    'ncbi_base_ftp'           => 'ftp://ftp.ncbi.nlm.nih.gov/genomes/all',
    'insdc_base_ftp'          => $self->o('ncbi_base_ftp').'/#expr(substr(#assembly_accession#, 0, 3))expr#/#expr(substr(#assembly_accession#, 4, 3))expr#/#expr(substr(#assembly_accession#, 7, 3))expr#/#expr(substr(#assembly_accession#, 10, 3))expr#/#assembly_accession#_#assembly_name#',
    'assembly_ftp_path'       => $self->o('insdc_base_ftp'),
    'refseq_base_ftp'         => $self->o('ncbi_base_ftp').'/#expr(substr(#assembly_refseq_accession#, 0, 3))expr#/#expr(substr(#assembly_refseq_accession#, 4, 3))expr#/#expr(substr(#assembly_refseq_accession#, 7, 3))expr#/#expr(substr(#assembly_refseq_accession#, 10, 3))expr#/#assembly_refseq_accession#_#assembly_name#',
    'refseq_import_ftp_path'  => $self->o('refseq_base_ftp').'/#assembly_refseq_accession#_#assembly_name#_genomic.gff.gz',
    'refseq_mrna_ftp_path'    => $self->o('refseq_base_ftp').'/#assembly_refseq_accession#_#assembly_name#_rna.fna.gz',
    'refseq_report_ftp_path' => $self->o('refseq_base_ftp').'/#assembly_refseq_accession#_#assembly_name#_assembly_report.txt',
##################################
# Memory settings for the analyses
##################################
    'default_mem'          => '900',
    'genblast_mem'         => '1900',
    'genblast_retry_mem'   => '4900',
    'genewise_mem'         => '3900',
    'genewise_retry_mem'   => '5900',
    'refseq_mem'           => '9900',
    'projection_mem'       => '1900',
    'layer_annotation_mem' => '3900',
    'genebuilder_mem'      => '1900',


########################
# db info
########################
    'cdna_db' => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_cdna_'.$self->o('release_number'),
      -host   => $self->o('cdna_db_server'),
      -port   => $self->o('cdna_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    'projection_source_db' => {
      -dbname => $self->o('projection_source_db_name'),
      -host   => $self->o('projection_source_db_server'),
      -port   => $self->o('projection_source_db_port'),
      -user   => $self->o('user_r'),
      -pass   => $self->o('password_r'),
      -driver => $self->o('hive_driver'),
    },

    'refseq_db' => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_refseq_'.$self->o('release_number'),
      -host   => $self->o('refseq_db_server'),
      -port   => $self->o('refseq_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    'production_db' => {
      -host   => $self->o('production_db_server'),
      -port   => $self->o('production_db_port'),
      -user   => $self->o('user_r'),
      -pass   => $self->o('password_r'),
      -dbname => 'ensembl_production',
      -driver => $self->o('hive_driver'),
    },

    'otherfeatures_db' => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_otherfeatures_'.$self->o('release_number'),
      -host   => $self->o('otherfeatures_db_server'),
      -port   => $self->o('otherfeatures_db_port'),
      -user   => $self->o('user'),
      -pass   => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

  };
}

sub pipeline_create_commands {
    my ($self) = @_;

    return [
    # inheriting database and hive tables' creation
      @{$self->SUPER::pipeline_create_commands},
    ];
}


sub pipeline_wide_parameters {
  my ($self) = @_;


  return {
    %{$self->SUPER::pipeline_wide_parameters},
    wide_ensembl_release => $self->o('ensembl_release'),
  }
}

## See diagram for pipeline structure
sub pipeline_analyses {
    my ($self) = @_;

    my %genblast_params = (
      wu    => '-P wublast -gff -e #blast_eval# -c #blast_cov#',
      ncbi  => '-P blast -gff -e #blast_eval# -c #blast_cov# -W 3 -softmask -scodon 50 -i 30 -x 10 -n 30 -d 200000 -g T',
      wu_genome    => '-P wublast -gff -e #blast_eval# -c #blast_cov#',
      ncbi_genome  => '-P blast -gff -e #blast_eval# -c #blast_cov# -W 3 -softmask -scodon 50 -i 30 -x 10 -n 30 -d 200000 -g T',
      wu_projection    => '-P wublast -gff -e #blast_eval# -c #blast_cov# -n 100 -x 5 ',
      ncbi_projection  => '-P blast -gff -e #blast_eval# -c #blast_cov# -W 3 -scodon 50 -i 30 -x 10 -n 30 -d 200000 -g T',
      );
    my %commandline_params = (
      'ncbi' => '-num_threads 3 -window_size 40',
      'wu' => '-cpus 3 -hitdist 40',
      'legacy_ncbi' => '-a 3 -A 40',
      );
    my $header_line = create_header_line($self->default_options->{'file_columns'});

    return [

      {
        -logic_name => 'create_otherfeatures_db',
        -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveCreateDatabase',
        -parameters => {
                         source_db => $self->o('cdna_db'),
                         target_db => $self->o('otherfeatures_db'),
                         create_type => 'copy',
                       },
        -rc_name    => 'default',
        -flow_into  => {
                         1 => ['update_cdna_analyses'],
                       },
      },



      {
        -logic_name => 'update_cdna_analyses',
        -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SqlCmd',
        -parameters => {
          db_conn => $self->o('otherfeatures_db'),
          sql => [
            'UPDATE gene, analysis SET gene.analysis_id = analysis.analysis_id WHERE analysis.logic_name = "cdna_alignment"',
            'UPDATE transcript join gene using(gene_id) set transcript.analysis_id=gene.analysis_id',
            'UPDATE gene set biotype="cDNA"',
            'UPDATE transcript set biotype="cDNA"',
            'UPDATE dna_align_feature, analysis SET dna_align_feature.analysis_id = analysis.analysis_id WHERE analysis.logic_name = "cdna_alignment"',
          ],
        },
        -rc_name    => 'default',
        -flow_into => {
                        '1->A' => ['create_refseq_import_ids_to_copy'],
                        'A->1' => ['update_otherfeatures_db'],
                      },
      },



      {
        -logic_name => 'create_refseq_import_ids_to_copy',
        -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveSubmitAnalysis',
        -parameters => {
                         target_db    => $self->o('refseq_db'),
                         iid_type     => 'feature_id',
                         feature_type => 'gene',
                         batch_size   => 500,
                      },
        -flow_into => {
                       '2' => ['copy_refseq_genes_to_otherfeatures'],
                      },

        -rc_name    => 'default',
      },


      {
        -logic_name => 'copy_refseq_genes_to_otherfeatures',
        -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveCopyGenes',
        -parameters => {
                         copy_genes_directly => 1,
                         source_db => $self->o('refseq_db'),
                         dna_db => $self->o('dna_db'),
                         target_db => $self->o('otherfeatures_db'),
                       },
        -rc_name    => 'default',
      },


      {
        -logic_name => 'update_otherfeatures_db',
        -module => 'Bio::EnsEMBL::Hive::RunnableDB::SqlCmd',
        -parameters => {
          db_conn => $self->o('otherfeatures_db'),
          sql => [
            'DELETE analysis_description FROM analysis_description join analysis using(analysis_id)'.
              ' WHERE logic_name NOT IN ("refseq_import","cdna_alignment")',
            'DELETE FROM analysis WHERE logic_name NOT IN ("refseq_import","cdna_alignment")',
            'DELETE FROM meta WHERE meta_key LIKE "%.level"',
            'DELETE FROM meta WHERE meta_key LIKE "assembly.web_accession%"',
            'DELETE FROM meta WHERE meta_key LIKE "removed_evidence_flag.%"',
            'DELETE FROM meta WHERE meta_key LIKE "marker.%"',
            'DELETE FROM meta WHERE meta_key = "repeat.analysis"',
            'DELETE FROM meta WHERE meta_key IN'.
              ' ("genebuild.last_geneset_update","genebuild.method","genebuild.projection_source_db","genebuild.start_date")',
            'INSERT INTO meta (species_id,meta_key,meta_value) VALUES (1,"genebuild.last_otherfeatures_update",NOW())',
            'UPDATE transcript JOIN transcript_supporting_feature USING(transcript_id)'.
              ' JOIN dna_align_feature ON feature_id = dna_align_feature_id SET stable_id = hit_name',
          ],
        },
        -rc_name    => 'default',
        -flow_into => {
                        1 => ['set_otherfeatures_meta_coords'],
                      },
      },


      {
        -logic_name => 'set_otherfeatures_meta_coords',
        -module => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
        -parameters => {
                         cmd => 'perl '.$self->o('meta_coord_script').
                                ' -user '.$self->o('user').
                                ' -pass '.$self->o('password').
                                ' -host '.$self->o('otherfeatures_db','-host').
                                ' -port '.$self->o('otherfeatures_db','-port').
                                ' -dbpattern '.$self->o('otherfeatures_db','-dbname')
                       },
        -rc_name => 'default',
        -flow_into => {
                        1 => ['set_otherfeatures_meta_levels'],
                      },
      },


      {
        -logic_name => 'set_otherfeatures_meta_levels',
        -module => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
        -parameters => {
                         cmd => 'perl '.$self->o('meta_levels_script').
                                ' -user '.$self->o('user').
                                ' -pass '.$self->o('password').
                                ' -host '.$self->o('otherfeatures_db','-host').
                                ' -port '.$self->o('otherfeatures_db','-port').
                                ' -dbname '.$self->o('otherfeatures_db','-dbname')
                       },
        -rc_name => 'default',
        -flow_into => { 1 => ['set_otherfeatures_frameshift_introns'] },
      },


      {
        -logic_name => 'set_otherfeatures_frameshift_introns',
        -module => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
        -parameters => {
                         cmd => 'perl '.$self->o('frameshift_attrib_script').
                                ' -user '.$self->o('user').
                                ' -pass '.$self->o('password').
                                ' -host '.$self->o('otherfeatures_db','-host').
                                ' -port '.$self->o('otherfeatures_db','-port').
                                ' -dbpattern '.$self->o('otherfeatures_db','-dbname')
                       },
        -rc_name => '4GB',
        -flow_into => { 1 => ['set_otherfeatures_canonical_transcripts'] },
      },


      {
        -logic_name => 'set_otherfeatures_canonical_transcripts',
        -module => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
        -parameters => {
                         cmd => 'perl '.$self->o('select_canonical_script').
                                ' -dbuser '.$self->o('user').
                                ' -dbpass '.$self->o('password').
                                ' -dbhost '.$self->o('otherfeatures_db','-host').
                                ' -dbport '.$self->o('otherfeatures_db','-port').
                                ' -dbname '.$self->o('otherfeatures_db','-dbname').
                                ' -dnadbuser '.$self->o('user_r').
                                ' -dnadbhost '.$self->o('dna_db','-host').
                                ' -dnadbport '.$self->o('dna_db','-port').
                                ' -dnadbname '.$self->o('dna_db','-dbname').
                                ' -coord toplevel -write'
                       },
        -rc_name => '2GB',
        -flow_into => { 1 => ['populate_production_tables_otherfeatures'] },
      },


      {
        -logic_name => 'populate_production_tables_otherfeatures',
        -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveAssemblyLoading::HivePopulateProductionTables',
        -parameters => {
                         'target_db'        => $self->o('otherfeatures_db'),
                         'output_path'      => $self->o('output_path'),
                         'enscode_root_dir' => $self->o('enscode_root_dir'),
                         'production_db'    => $self->o('production_db'),
                       },
        -rc_name    => 'default',
        -flow_into  => {
                         1 => ['null_otherfeatures_columns'],
                       },
      },


      {
        -logic_name => 'null_otherfeatures_columns',
        -module => 'Bio::EnsEMBL::Hive::RunnableDB::SqlCmd',
        -parameters => {
          db_conn => $self->o('otherfeatures_db'),
          sql => [
            'UPDATE dna_align_feature SET external_db_id = NULL',
          ],
        },
        -rc_name    => 'default',
        -flow_into => {
                        1 => ['load_external_db_ids_and_optimise_otherfeatures'],
                      },
      },


      {
        -logic_name => 'load_external_db_ids_and_optimise_otherfeatures',
        -module => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
        -parameters => {
                         cmd => 'perl '.$self->o('load_optimise_script').
                                ' -output_path '.catdir($self->o('output_path'), 'optimise_otherfeatures').
                                ' -uniprot_filename '.$self->o('protein_entry_loc').
                                ' -dbuser '.$self->o('user').
                                ' -dbpass '.$self->o('password').
                                ' -dbport '.$self->o('otherfeatures_db','-port').
                                ' -dbhost '.$self->o('otherfeatures_db','-host').
                                ' -dbname '.$self->o('otherfeatures_db','-dbname').
                                ' -prod_dbuser '.$self->o('user_r').
                                ' -prod_dbhost '.$self->o('production_db','-host').
                                ' -prod_dbname '.$self->o('production_db','-dbname').
                                ' -prod_dbport '.$self->o('production_db','-port').
                                ' -verbose'
                       },
        -max_retry_count => 0,
        -rc_name => '4GB',
        -flow_into => {
                        1 => ['otherfeatures_sanity_checks'],
                      },
      },


      {
        -logic_name => 'otherfeatures_sanity_checks',
        -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveAnalysisSanityCheck',
        -parameters => {
                         target_db => $self->o('otherfeatures_db'),
                         sanity_check_type => 'gene_db_checks',
                         min_allowed_feature_counts => get_analysis_settings('Bio::EnsEMBL::Analysis::Hive::Config::SanityChecksStatic',
                                                                             'gene_db_checks')->{'otherfeatures'},
                       },

        -rc_name    => '4GB',
        -flow_into => {
                        1 => ['otherfeatures_healthchecks'],
                      },
      },


      {
        -logic_name => 'otherfeatures_healthchecks',
        -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveHealthcheck',
        -parameters => {
          input_db         => $self->o('otherfeatures_db'),
          species          => $self->o('species_name'),
          group            => 'otherfeatures_handover',
        },
        -max_retry_count => 0,

        -rc_name    => '4GB',
        -flow_into  => {
          1 => ['otherfeatures_assembly_name_update'],
        },
      },

      {
        -logic_name => 'otherfeatures_assembly_name_update',
        -module => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
        -parameters => {
                       cmd => 'perl '.$self->o('assembly_name_script').
                                ' -user '.$self->o('user').
                                ' -pass '.$self->o('password').
                                ' -host '.$self->o('otherfeatures_db','-host').
                                ' -port '.$self->o('otherfeatures_db','-port').
                                ' -dbname '.$self->o('otherfeatures_db','-dbname').
                                ' -driver '.$self->o('hive_driver').
                                ' -assembly_accession '.$self->o('assembly_accession').
                                ' -assembly_name '.$self->o('assembly_name').
                                ' -registry_host '.$self->o('registry_host').
                                ' -registry_port '.$self->o('registry_port').
                                ' -registry_db '.$self->o('registry_db'),
                       },

        -rc_name => 'default',
       },


    ];
}


sub resource_classes {
  my $self = shift;

  return {
    '2GB' => { LSF => $self->lsf_resource_builder('production-rh74', 2000, [$self->default_options->{'pipe_db_server'}, $self->default_options->{'dna_db_server'}], [$self->default_options->{'num_tokens'}])},
    '4GB' => { LSF => $self->lsf_resource_builder('production-rh74', 4000, [$self->default_options->{'pipe_db_server'}, $self->default_options->{'dna_db_server'}], [$self->default_options->{'num_tokens'}])},
    'default' => { LSF => $self->lsf_resource_builder('production-rh74', 900, [$self->default_options->{'pipe_db_server'}, $self->default_options->{'dna_db_server'}], [$self->default_options->{'num_tokens'}])},
  }
}


sub check_file_in_ensembl {
  my ($self, $file_path) = @_;
  push @{$self->{'_ensembl_file_paths'}}, $file_path;
  return $self->o('enscode_root_dir').'/'.$file_path;
}

1;
