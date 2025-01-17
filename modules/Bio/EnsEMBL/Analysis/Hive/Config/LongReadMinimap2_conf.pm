package LongReadMinimap2_conf;

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

'production_name'        => '', # The production name, including any modifiers
'faidx_genome_file'      => '', # UNMASKED genome.fa file, should also have a .fai file in sam dir
'long_read_summary_file' => '', # The csv file should have sample_name\tfile_name
'long_read_fastq_dir'    => '', # Dir where the fastq files are (or where they will get downloaded to if they don't already exist)

'dbowner'                => '' || $ENV{USER},
'release_number'         => '' || $ENV{ENSEMBL_RELEASE},
'dna_db_server'          => '',
'dna_db_port'            => '',
'pipe_db_server'         => '',
'pipe_db_port'           => '',
'databases_server'       => '',
'databases_port'         => '',

'user_r'                 => 'ensro',
'user'                   => '',
'password'               => '',


# Shouldn't need to set these
'minimap2_genome_index'  => $self->o('faidx_genome_file').'.mmi',
'use_genome_flatfile'    => 1,
'minimap2_path'          => '/hps/nobackup2/production/ensembl/fergal/coding/long_read_aligners/new_mm2/minimap2/minimap2',
'paftools_path'          => '/hps/nobackup2/production/ensembl/fergal/coding/long_read_aligners/new_mm2/minimap2/misc/paftools.js',
'minimap2_batch_size'    => '5000',
'rnaseq_ftp_base'        => 'https://ftp.sra.ebi.ac.uk/vol1/fastq/',
'long_read_columns'      => ['sample','filename'],
'skip_long_read'         => 0,

'base_blast_db_path'     => $ENV{BLASTDB_DIR},
'uniprot_version'        => 'uniprot_2018_07',
'protein_blast_db'       => '' || catfile($self->o('base_blast_db_path'), 'uniprot', $self->o('uniprot_version'), 'PE12_vertebrata'),
'protein_blast_index'    => '' || catdir($self->o('base_blast_db_path'), 'uniprot', $self->o('uniprot_version'), 'PE12_vertebrata_index'),

'blast_type' => 'ncbi', # It can be 'ncbi', 'wu', or 'legacy_ncbi'
'uniprot_blast_exe_path' => catfile($self->o('binary_base'), 'blastp'),
'samtools_path'         => '/nfs/software/ensembl/RHEL7-JUL2017-core2/linuxbrew/bin/samtools',
'use_threads'           => 1,

'enscode_root_dir'      => '' || $ENV{ENSCODE_DIR}, # git repo checkouts

'pipeline_name'         => '' || $self->o('production_name').'_'.$self->o('release_number').'_lrminimap2',

'binary_base'           => '/nfs/software/ensembl/RHEL7-JUL2017-core2/linuxbrew/bin',
'clone_db_script_path'  => catfile($self->o('enscode_root_dir'), 'ensembl-analysis', 'scripts', 'clone_database.ksh'),
'default_mem'           => '1900',

     'dna_db' => {
       -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_core_'.$self->o('release_number'),
       -host   => $self->o('dna_db_server'),
       -port   => $self->o('dna_db_port'),
       -user   => $self->o('user_r'),
       -driver => $self->o('hive_driver'),
     },

    'refine_db' => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_refine_'.$self->o('release_number'),
      -host   => $self->o('databases_server'),
      -port   => $self->o('databases_port'),
      -user   => $self->o('user_r'),
      -driver => $self->o('hive_driver'),
    },

    'long_read_initial_db' => {
     -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_lrgenes_'.$self->o('release_number'),
     -host   => $self->o('databases_server'),
     -port   => $self->o('databases_port'),
     -user   => $self->o('user'),
     -pass   => $self->o('password'),
     -driver => $self->o('hive_driver'),
     },


    long_read_collapse_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_lrcollapse_'.$self->o('release_number'),
      -host => $self->o('databases_server'),
      -port => $self->o('databases_port'),
      -user => $self->o('user'),
      -pass => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    long_read_blast_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_lrblast_'.$self->o('release_number'),
      -host => $self->o('databases_server'),
      -port => $self->o('databases_port'),
      -user => $self->o('user'),
      -pass => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

    long_read_final_db => {
      -dbname => $self->o('dbowner').'_'.$self->o('production_name').'_lrfinal_'.$self->o('release_number'),
      -host => $self->o('databases_server'),
      -port => $self->o('databases_port'),
      -user => $self->o('user'),
      -pass => $self->o('password'),
      -driver => $self->o('hive_driver'),
    },

 } # end return
} # end default_options


sub pipeline_create_commands {
    my ($self) = @_;
    return [
    # inheriting database and hive tables' creation
	    @{$self->SUPER::pipeline_create_commands},
    ];
} # end pipeline_create_commands


sub pipeline_wide_parameters {
  my ($self) = @_;

  return {
	  %{$self->SUPER::pipeline_wide_parameters},
    use_genome_flatfile  => $self->o('use_genome_flatfile'),
    genome_file          => $self->o('faidx_genome_file'),
    skip_long_read       => $self->o('skip_long_read'),
  }
}


sub pipeline_analyses {
  my ($self) = @_;
  return [

      {
        -logic_name => 'fan_long_read',
        -module => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
        -parameters => {
                         cmd => 'if [ "#skip_long_read#" -ne "0" ]; then exit 42; else exit 0;fi',
                         return_codes_2_branches => {'42' => 2},
                       },
        -flow_into  => {
          1 => ['create_long_read_initial_db'],
        },
        -rc_name => 'default',
        -input_ids => [{}],
      },


      {
        -logic_name => 'create_long_read_initial_db',
        -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveCreateDatabase',
        -parameters => {
                         source_db => $self->o('dna_db'),
                         target_db => $self->o('long_read_initial_db'),
                         create_type => 'clone',
                       },
        -rc_name    => '1GB',
        -flow_into => {
                        '1' => ['create_minimap2_index'],
                      },
      },




      {
        -logic_name => 'create_minimap2_index',
        -module     => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
        -parameters => {
          cmd => 'if [ ! -e "'.$self->o('minimap2_genome_index').'" ]; then '.$self->o('minimap2_path').
                 ' -d '.$self->o('minimap2_genome_index').' '.$self->o('faidx_genome_file').';fi',
        },
        -flow_into  => {
          1 => ['check_index_not_empty'],
        },
        -rc_name => '20GB',
      },


      {
        -logic_name => 'check_index_not_empty',
        -module => 'Bio::EnsEMBL::Hive::RunnableDB::SystemCmd',
        -parameters => {
                         cmd => 'if [ -s "'.$self->o('minimap2_genome_index').'" ]; then exit 0; else exit 42;fi',
                         return_codes_2_branches => {'42' => 2},
        },
        -flow_into  => {
         '1->A' => ['create_lr_fastq_download_jobs'],
         'A->1' => ['create_collapse_db'],
        },
        -rc_name => 'default',
      },


      {
        -logic_name => 'create_lr_fastq_download_jobs',
        -module     => 'Bio::EnsEMBL::Hive::RunnableDB::JobFactory',
        -parameters => {
          inputfile    => $self->o('long_read_summary_file'),
          column_names => $self->o('long_read_columns'),
          delimiter => '\t',
        },
        -flow_into => {
          2 => {'download_long_read_fastq' => {'iid' => '#filename#'}},
        },
      },


      {
        -logic_name => 'download_long_read_fastq',
        -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveDownloadRNASeqFastqs',
        -parameters =>{
          ftp_base_url => $self->o('rnaseq_ftp_base'),
          input_dir => $self->o('long_read_fastq_dir'),
          samtools_path => $self->o('samtools_path'),
          decompress => 1,
          create_faidx => 1,
        },
        -rc_name => '1GB',
        -analysis_capacity => 50,
        -flow_into => {
          1 => {'generate_minimap2_jobs' => {'fastq_file' => $self->o('long_read_fastq_dir').'/'.'#fastq_file#'}},
        },

      },


      {
        -logic_name => 'generate_minimap2_jobs',
        -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveSubmitAnalysis',
        -parameters => {
                         iid_type => 'fastq_range',
                         batch_size => $self->o('minimap2_batch_size'),
                       },
        -rc_name      => '2GB',
        -flow_into => {
                        2 => {'minimap2' => {'input_file' => '#fastq_file#','iid' => '#iid#'}},
                      },
      },


      {
        -logic_name => 'minimap2',
        -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::Minimap2',
        -parameters => {
                         genome_file => $self->o('faidx_genome_file'),
                         minimap2_genome_index => $self->o('minimap2_genome_index'),
                         minimap2_path => $self->o('minimap2_path'),
                         paftools_path => $self->o('paftools_path'),
                         target_db => $self->o('long_read_initial_db'),
                         logic_name => 'minimap2',
                         module     => 'Minimap2',
                       },
        -rc_name => '15GB',
        -flow_into => {
                        -1 => {'minimap2_himem' => {'input_file' => '#input_file#','iid' => '#iid#'}},
                      },
     },


     {
        -logic_name => 'minimap2_himem',
        -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::Minimap2',
        -parameters => {
                         genome_file => $self->o('faidx_genome_file'),
                         minimap2_genome_index => $self->o('minimap2_genome_index'),
                         minimap2_path => $self->o('minimap2_path'),
                         paftools_path => $self->o('paftools_path'),
                         target_db => $self->o('long_read_initial_db'),
                         logic_name => 'minimap2',
                         module     => 'Minimap2',
                       },
        -rc_name => '25GB',
     },


     {
       -logic_name => 'create_collapse_db',
       -module => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveCreateDatabase',
       -parameters => {
          source_db => $self->o('dna_db'),
          target_db => $self->o('long_read_collapse_db'),
          create_type => 'clone',
       },
       -rc_name => 'default',
       -max_retry_count => 0,
       -flow_into => {
         1 => ['create_long_read_blast_db'],
       }
     },

	  {
      -logic_name => 'create_long_read_blast_db',
      -module => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveCreateDatabase',
      -parameters => {
        source_db => $self->o('dna_db'),
        target_db => $self->o('long_read_blast_db'),
        create_type => 'clone',
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        1 => ['create_check_db'],
      }
    },

	  {
      -logic_name => 'create_check_db',
      -module => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveCreateDatabase',
      -parameters => {
        source_db => $self->o('dna_db'),
        target_db => $self->o('long_read_final_db'),
        create_type => 'clone',
      },
      -rc_name => 'default',
      -max_retry_count => 0,
      -flow_into => {
        1 => ['generate_collapse_jobs'],
      }
    },

   {
      -logic_name => 'generate_collapse_jobs',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveSubmitAnalysis',
      -parameters => {
        target_db        => $self->o('long_read_collapse_db'),
        feature_dbs => [$self->o('long_read_initial_db')],
        coord_system_name => 'toplevel',
        iid_type => 'stranded_slice',
        feature_constraint => 1,
        feature_type => 'gene',
        top_level => 1,
      },
      -rc_name      => 'default',
      -max_retry_count => 1,
      -flow_into => {
        '2->A' => ['split_lr_slices_on_intergenic'],
        'A->1' => ['classify_long_read_models'],
      },
    },

	  {
      -logic_name => 'split_lr_slices_on_intergenic',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveFindIntergenicRegions',
      -parameters => {
        dna_db => $self->o('dna_db'),
        input_gene_dbs => [$self->o('long_read_initial_db')],
        iid_type => 'slice',
        use_strand => 1,
      },
      -batch_size => 100,
      -rc_name    => '5GB',
      -flow_into => {
        2 => {'collapse_transcripts' => {'slice_strand' => '#slice_strand#','iid' => '#iid#'}},
      },
    },


    {
      -logic_name => 'collapse_transcripts',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveTranscriptCoalescer',
      -parameters => {
		       target_db        => $self->o('long_read_collapse_db'),
	               dna_db        => $self->o('dna_db'),
                       source_dbs        => [$self->o('long_read_initial_db')],
		       biotypes => ["isoseq","cdna"],
		       reduce_large_clusters => 1,
      },
      -rc_name      => '5GB',
      -flow_into => {
         1 => ['blast_long_read'],
        -1 => {'collapse_transcripts_20GB' => {'slice_strand' => '#slice_strand#','iid' => '#iid#'}},
      },
      -batch_size => 100,
      -analysis_capacity => 1000,
    },


    {
      -logic_name => 'collapse_transcripts_20GB',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveTranscriptCoalescer',
      -parameters => {
        target_db        => $self->o('long_read_collapse_db'),
        dna_db        => $self->o('dna_db'),
        source_dbs        => [$self->o('long_read_initial_db')],
        biotypes => ["isoseq","cdna"],
        reduce_large_clusters => 1,
      },
      -rc_name      => '20GB',
      -flow_into => {
        1 => {'blast_long_read' => {'slice_strand' => '#slice_strand#','iid' => '#iid#'}},
       -1 => {'failed_collapse' => {'slice_strand' => '#slice_strand#','iid' => '#iid#'}},
      },
      -batch_size => 10,
      -analysis_capacity => 1000,
    },


    {
      -logic_name => 'failed_collapse',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveTranscriptCoalescer',
      -parameters => {
        target_db         => $self->o('long_read_collapse_db'),
        dna_db            => $self->o('dna_db'),
        source_dbs        => [$self->o('long_read_initial_db')],
        biotypes => ["isoseq","cdna"],
        copy_only => 1,
      },
      -rc_name      => '10GB',
      -flow_into => {
        1 => ['blast_long_read'],
      },
    },


    {
      -logic_name => 'blast_long_read',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveBlastRNASeqPep',
      -parameters => {
        input_db => $self->o('long_read_collapse_db'),
        output_db => $self->o('long_read_blast_db'),
        source_db => $self->o('long_read_collapse_db'),
        target_db => $self->o('long_read_blast_db'),
        dna_db => $self->o('dna_db'),
        indicate_index => $self->o('protein_blast_index'),
        uniprot_index => [$self->o('protein_blast_db')],
        blast_program => $self->o('uniprot_blast_exe_path'),
        %{get_analysis_settings('Bio::EnsEMBL::Analysis::Hive::Config::BlastStatic','BlastGenscanPep', {BLAST_PARAMS => {-type => $self->o('blast_type')}})},
        commandline_params => $self->o('blast_type') eq 'wu' ? '-cpus='.$self->o('use_threads').' -hitdist=40' : '-num_threads '.$self->o('use_threads').' -window_size 40 -seg no',
      },
      -rc_name => 'blast',
      -flow_into => {
        -1 => ['blast_long_read_10G'],
        1 => ['intron_check'],
      },
    },

    {
      -logic_name => 'blast_long_read_10G',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveBlastRNASeqPep',
      -parameters => {
        input_db => $self->o('long_read_collapse_db'),
        output_db => $self->o('long_read_blast_db'),
        dna_db => $self->o('dna_db'),
        source_db => $self->o('long_read_collapse_db'),
        target_db => $self->o('long_read_blast_db'),
        indicate_index => $self->o('protein_blast_index'),
        uniprot_index => [$self->o('protein_blast_db')],
        blast_program => $self->o('uniprot_blast_exe_path'),
        %{get_analysis_settings('Bio::EnsEMBL::Analysis::Hive::Config::BlastStatic','BlastGenscanPep', {BLAST_PARAMS => {-type => $self->o('blast_type')}})},
        commandline_params => $self->o('blast_type') eq 'wu' ? '-cpus='.$self->o('use_threads').' -hitdist=40' : '-num_threads '.$self->o('use_threads').' -window_size 40 -seg no',
      },
      -rc_name => 'blast10GB',
      -flow_into => {
        1 => ['intron_check'],
      },
    },


    {
      -logic_name => 'intron_check',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveHomologyRNASeqIntronsCheck',
      -parameters => {
        source_db => $self->o('long_read_blast_db'),
        target_db => $self->o('long_read_final_db'),
        intron_db => $self->o('refine_db'),
        dna_db => $self->o('dna_db'),
      },
      -rc_name    => '2GB',
      -flow_into => {
        1 => ['intron_check_10GB'],
      },
    },


    {
      -logic_name => 'intron_check_10GB',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveHomologyRNASeqIntronsCheck',
      -parameters => {
        source_db => $self->o('long_read_blast_db'),
        target_db => $self->o('long_read_final_db'),
        intron_db => $self->o('refine_db'),
        dna_db => $self->o('dna_db'),
      },
      -rc_name    => '10GB',
    },


    {
      -logic_name => 'classify_long_read_models',
      -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveClassifyTranscriptSupport',
      -parameters => {
        classification_type => 'standard',
        update_gene_biotype => 1,
        target_db => $self->o('long_read_final_db'),
      },
      -rc_name    => 'default',
    },

  ]
} # end pipeline analyses


sub resource_classes {
  my $self = shift;

  return {
    'default' => { 'LSF' => $self->lsf_resource_builder('production-rh74',500) },
    '1GB' => { 'LSF' => $self->lsf_resource_builder('production-rh74',1000) },
    '2GB' => { 'LSF' => $self->lsf_resource_builder('production-rh74',2000) },
    '5GB' => { 'LSF' => $self->lsf_resource_builder('production-rh74',5000) },
    '10GB' => { 'LSF' => $self->lsf_resource_builder('production-rh74',10000) },
    '15GB' => { 'LSF' => $self->lsf_resource_builder('production-rh74',15000) },
    '20GB' => { 'LSF' => $self->lsf_resource_builder('production-rh74',20000) },
    '25GB' => { 'LSF' => $self->lsf_resource_builder('production-rh74',25000) },
    '30GB' => { 'LSF' => $self->lsf_resource_builder('production-rh74',30000) },
    'blast' => { LSF => $self->lsf_resource_builder('production-rh74', 2000, undef, undef, ($self->default_options->{'use_threads'}+1))},
    'blast10GB' => { LSF => $self->lsf_resource_builder('production-rh74', 10000, undef, undef, ($self->default_options->{'use_threads'}+1))},
  }
} # end resource_classes

1;
