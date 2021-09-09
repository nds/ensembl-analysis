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

=head1 CONTACT

Please email comments or questions to the public Ensembl
developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

Questions may also be sent to the Ensembl help desk at
<http://www.ensembl.org/Help/Contact>.

=head1 NAME

Bio::EnsEMBL::Analysis::Hive::Config::GenebuilderStatic

=head1 SYNOPSIS

use Bio::EnsEMBL::Analysis::Tools::Utilities qw(get_analysis_settings);
use parent ('Bio::EnsEMBL::Analysis::Hive::Config::HiveBaseConfig_conf');

sub pipeline_analyses {
    my ($self) = @_;

    return [
      {
        -logic_name => 'run_uniprot_blast',
        -module     => 'Bio::EnsEMBL::Analysis::Hive::RunnableDB::HiveAssemblyLoading::HiveBlastGenscanPep',
        -parameters => {
                         blast_db_path => $self->o('uniprot_blast_db_path'),
                         blast_exe_path => $self->o('uniprot_blast_exe_path'),
                         commandline_params => '-cpus 3 -hitdist 40',
                         repeat_masking_logic_names => ['repeatmasker_'.$self->o('repeatmasker_library')],
                         prediction_transcript_logic_names => ['genscan'],
                         iid_type => 'feature_id',
                         logic_name => 'uniprot',
                         module => 'HiveBlastGenscanPep',
                         get_analysis_settings('Bio::EnsEMBL::Analysis::Hive::Config::GenebuilderStatic',$self->o('uniprot_set'),
                      },
        -flow_into => {
                        -1 => ['run_uniprot_blast_himem'],
                        -2 => ['run_uniprot_blast_long'],
                      },
        -rc_name    => 'blast',
      },
  ];
}

=head1 DESCRIPTION

This is the config file for all genebuilder analysis. You should use it in your Hive configuration file to
specify the parameters of an analysis. You can either choose an existing config or you can create
a new one based on the default hash.

=head1 METHODS

  _master_config_settings: contains all possible parameters

=cut

package Bio::EnsEMBL::Analysis::Hive::Config::GenebuilderStatic;

use strict;
use warnings;

use parent ('Bio::EnsEMBL::Analysis::Hive::Config::BaseStatic');

sub _master_config {
  my ($self, $key) = @_;

  my %config = (
    default => [],
    primates_basic => [
                              'IG_C_gene',
                              'IG_J_gene',
                              'IG_V_gene',
                              'IG_D_gene',
                              'TR_C_gene',
                              'TR_J_gene',
                              'TR_V_gene',
                              'TR_D_gene',
                              'seleno_self',
                             'cdna2genome',
                             'edited',
                             'gw_gtag',
                             'gw_nogtag',
                             'gw_exo',
                             'projection_1',
                             'projection_2',
                             'rnaseq_merged_1',
                             'rnaseq_merged_2',
                             'rnaseq_tissue_1',
                             'rnaseq_tissue_2',
                             'self_pe12_sp_1',
                             'self_pe12_tr_1',
                             'self_pe12_sp_2',
                             'self_pe12_tr_2',
                             'human_pe12_sp_1',
                             'human_pe12_tr_1',
                             'primates_pe12_sp_1',
                             'primates_pe12_tr_1',
                             'genblast_select_1',
                             'genblast_select_2',
                             'mammals_pe12_sp_1',
                             'mammals_pe12_tr_1',
                             'human_pe12_sp_2',
                             'human_pe12_tr_2',
                             'primates_pe12_sp_2',
                             'primates_pe12_tr_2',
                             'mammals_pe12_sp_2',
                             'mammals_pe12_tr_2',
                             'projection_3',
                             'projection_4',
                             'genblast_select_3',
                             'genblast_select_4',
                             'projection_5',
                             'projection_6',
                             'genblast_select_5',
                             'genblast_select_6',
                             'human_pe12_sp_6',
                             'human_pe12_tr_6',
    ],


    mammals_basic => [
                             'IG_C_gene',
                             'IG_J_gene',
                             'IG_V_gene',
                             'IG_D_gene',
                             'TR_C_gene',
                             'TR_J_gene',
                             'TR_V_gene',
                             'TR_D_gene',
                             'seleno_self',
                             'cdna2genome',
                             'edited',
                             'gw_gtag',
                             'gw_nogtag',
                             'gw_exo',
                             'realign_1',
                             'realign_2',
                             'realign_3',
                             'realign_4',
                             'realign_5',
                             'realign_6',
                             'rnaseq_merged_1',
                             'rnaseq_merged_2',
                             'rnaseq_merged_3',
                             'self_pe12_sp_1',
                             'self_pe12_tr_1',
                             'self_pe12_sp_2',
                             'self_pe12_tr_2',
                             'human_pe12_sp_1',
                             'human_pe12_tr_1',
                             'human_pe12_tr_2',
                             'human_pe12_sp_2',
                             'mouse_pe12_sp_1',
                             'mouse_pe12_tr_1',
                             'mouse_pe12_sp_2',
                             'mouse_pe12_tr_2',
                             'mammals_pe12_sp_1',
                             'mammals_pe12_tr_1',
                             'mammals_pe12_sp_2',
                             'mammals_pe12_tr_2',
                             'rnaseq_tissue_1',
                             'rnaseq_tissue_2',
                             'rnaseq_tissue_3',
                             'human_pe12_sp_3',
                             'human_pe12_tr_3',
                             'mouse_pe12_sp_3',
                             'mouse_pe12_tr_3',
                             'self_pe3_sp_1',
                             'self_pe3_tr_1',
                             'mammals_pe12_sp_3',
                             'mammals_pe12_tr_3',
                             'vert_pe12_sp_1',
                             'vert_pe12_tr_1',
                             'rnaseq_merged_4',
                             'human_pe12_sp_4',
                             'human_pe12_tr_4',
                             'mouse_pe12_sp_4',
                             'mouse_pe12_tr_4',
                             'mammals_pe12_sp_4',
                             'mammals_pe12_tr_4',
                             'vert_pe12_sp_3',
                             'vert_pe12_tr_3',
                             'rnaseq_merged_5',
                             'rnaseq_tissue_5',
                             'human_pe12_sp_5',
                             'human_pe12_tr_5',
                             'mouse_pe12_sp_5',
                             'mouse_pe12_tr_5',
                             'vert_pe12_sp_4',
                             'vert_pe12_tr_4',
    ],

    reptiles_basic => [
    ],

    fish_basic => [
                             'IG_C_gene',
                             'IG_J_gene',
                             'IG_V_gene',
                             'IG_D_gene',
                             'TR_C_gene',
                             'TR_J_gene',
                             'TR_V_gene',
                             'TR_D_gene',
                             'seleno_self',
                             'cdna2genome',
                             'edited',
                             'gw_gtag',
                             'gw_nogtag',
                             'gw_exo',
                             'projection_1',
                             'projection_2',
		             'genblast_rnaseq_top',
		             'genblast_rnaseq_high',
		             'genblast_rnaseq_medium',
		             'genblast_rnaseq_low',
		             'genblast_rnaseq_weak',
                             'rnaseq_merged_1',
                             'rnaseq_merged_2',
                             'rnaseq_merged_3',
                             'rnaseq_merged_4',
                             'rnaseq_merged_5',
                             'rnaseq_tissue_1',
                             'rnaseq_tissue_2',
                             'rnaseq_tissue_3',
                             'rnaseq_tissue_4',
                             'rnaseq_tissue_5',
                             'self_pe12_sp_1',
                             'self_pe12_tr_1',
                             'self_pe12_sp_2',
                             'self_pe12_tr_2',
                             'genblast_select_1',
                             'genblast_select_2',
                             'projection_3',
                             'projection_4',
                             'fish_pe12_sp_1',
                             'fish_pe12_tr_1',
                             'fish_pe12_sp_2',
                             'fish_pe12_tr_2',
                             'genblast_select_3',
                             'genblast_select_4',
                             'rnaseq_merged_6',
                             'rnaseq_tissue_6',
                             'projection_5',
                             'projection_6',
                             'fish_pe12_sp_3',
                             'fish_pe12_tr_3',
                             'fish_pe12_sp_4',
                             'fish_pe12_tr_4',
                             'human_pe12_sp_1',
                             'human_pe12_tr_1',
                             'mammals_pe12_sp_1',
                             'mammals_pe12_tr_1',
                             'vert_pe12_sp_1',
                             'vert_pe12_tr_1',
                             'genblast_select_5',
                             'genblast_select_6',
                             'human_pe12_sp_2',
                             'human_pe12_tr_2',
                             'vert_pe12_sp_2',
                             'vert_pe12_tr_2',
                             'mammals_pe12_sp_2',
                             'mammals_pe12_tr_2',
                             'human_pe12_sp_3',
                             'human_pe12_tr_3',
                             'vert_pe12_sp_3',
                             'vert_pe12_tr_3',
                             'mammals_pe12_sp_3',
                             'mammals_pe12_tr_3',
                             'fish_pe12_sp_5',
                             'fish_pe12_tr_5',
                             'fish_pe12_sp_6',
                             'fish_pe12_tr_6',
                             'projection_7',
                             'human_pe12_sp_4',
                             'human_pe12_tr_4',
                             'vert_pe12_sp_4',
                             'vert_pe12_tr_4',
                             'mammals_pe12_sp_4',
                             'mammals_pe12_tr_4',
                             'mammals_pe12_sp_5',
                             'mammals_pe12_tr_5',
                             'vert_pe12_sp_5',
                             'vert_pe12_tr_5',
                             'human_pe12_sp_5',
                             'human_pe12_tr_5',
                             'mammals_pe12_sp_6',
                             'mammals_pe12_tr_6',
                             'vert_pe12_sp_6',
                             'vert_pe12_tr_6',
                             'human_pe12_sp_6',
                             'human_pe12_tr_6',
                             'fish_pe12_sp_int_1',
                             'fish_pe12_tr_int_1',
                             'mammals_pe12_sp_int_1',
                             'mammals_pe12_tr_int_1',
                             'vert_pe12_sp_int_1',
                             'vert_pe12_tr_int_1',
                             'human_pe12_sp_int_1',
                             'human_pe12_tr_int_1',
                             'fish_pe12_sp_int_2',
                             'fish_pe12_tr_int_2',
                             'mammals_pe12_sp_int_2',
                             'mammals_pe12_tr_int_2',
                             'vert_pe12_sp_int_2',
                             'vert_pe12_tr_int_2',
                             'human_pe12_sp_int_2',
                             'human_pe12_tr_int_2',
                             'fish_pe12_sp_int_3',
                             'fish_pe12_tr_int_3',
                             'mammals_pe12_sp_int_3',
                             'mammals_pe12_tr_int_3',
                             'vert_pe12_sp_int_3',
                             'vert_pe12_tr_int_3',
                             'human_pe12_sp_int_3',
                             'human_pe12_tr_int_3',
                             'fish_pe12_sp_int_4',
                             'fish_pe12_tr_int_4',
                             'mammals_pe12_sp_int_4',
                             'mammals_pe12_tr_int_4',
                             'vert_pe12_sp_int_4',
                             'vert_pe12_tr_int_4',
                             'human_pe12_sp_int_4',
                             'human_pe12_tr_int_4',
                             'fish_pe12_sp_int_5',
                             'fish_pe12_tr_int_5',
                             'mammals_pe12_sp_int_5',
                             'mammals_pe12_tr_int_5',
                             'vert_pe12_sp_int_5',
                             'vert_pe12_tr_int_5',
                             'human_pe12_sp_int_5',
                             'human_pe12_tr_int_5',
                             'fish_pe12_sp_int_6',
                             'fish_pe12_tr_int_6',
                             'mammals_pe12_sp_int_6',
                             'mammals_pe12_tr_int_6',
                             'vert_pe12_sp_int_6',
                             'vert_pe12_tr_int_6',
                             'human_pe12_sp_int_6',
                             'human_pe12_tr_int_6',
		             'rnaseq_merged',
		             'rnaseq_tissue',
    ],

    fish_complete => [
                'IG_C_gene',
                'IG_J_gene',
                'IG_V_gene',
                'IG_D_gene',
                'TR_C_gene',
                'TR_J_gene',
                'TR_V_gene',
                'TR_D_gene',
                'seleno_self',
                'cdna2genome',
                'edited',
                'gw_gtag',
                'gw_nogtag',
                'gw_exo',
                'realign_80',
                'realign_95',
                'realign_50',
                'self_pe12_sp_95',
                'self_pe12_sp_80',
                'self_pe12_tr_95',
                'self_pe12_tr_80',
                'self_pe3_tr_95',
                'self_pe3_tr_80',
                'rnaseq_95',
                'rnaseq_80',
                'fish_pe12_sp_80',
                'fish_pe12_sp_95',
                'fish_pe12_tr_80',
                'fish_pe12_tr_95',
                'human_pe12_sp_80',
                'human_pe12_sp_95',
                'human_pe12_tr_80',
                'human_pe12_tr_95',
                'mouse_pe12_sp_95',
                'mouse_pe12_sp_80',
                'mouse_pe12_tr_80',
                'mouse_pe12_tr_95',
                'mammals_pe12_sp_80',
                'mammals_pe12_sp_95',
                'mammals_pe12_tr_95',
                'mammals_pe12_tr_80',
                'vert_pe12_sp_95',
                'vert_pe12_sp_80',
                'vert_pe12_tr_80',
                'vert_pe12_tr_95',
    ],

    distant_vertebrate => [
                             'IG_C_gene',
                             'IG_J_gene',
                             'IG_V_gene',
                             'IG_D_gene',
                             'TR_C_gene',
                             'TR_J_gene',
                             'TR_V_gene',
                             'TR_D_gene',
                             'seleno_self',
                             'cdna2genome',
                             'edited',
                             'gw_gtag',
                             'gw_nogtag',
                             'gw_exo',
                             'rnaseq_merged_1',
                             'rnaseq_merged_2',
                             'rnaseq_merged_3',
                             'rnaseq_tissue_1',
                             'rnaseq_tissue_2',
                             'rnaseq_tissue_3',
                             'genblast_select_1',
                             'genblast_select_2',
                             'vert_pe12_sp_1',
                             'vert_pe12_sp_2',
                             'realign_1',
                             'realign_2',
                             'self_pe12_sp_1',
                             'self_pe12_sp_2',
                             'self_pe12_tr_1',
                             'self_pe12_tr_2',
                             'rnaseq_merged_4',
                             'rnaseq_tissue_4',
                             'genblast_select_3',
                             'vert_pe12_sp_3',
                             'vert_pe12_tr_1',
                             'vert_pe12_tr_2',
                             'realign_3',
                             'rnaseq_merged_5',
                             'rnaseq_tissue_5',
                             'genblast_select_4',
                             'vert_pe12_sp_4',
                             'vert_pe12_tr_3',
                             'realign_4',
                             'rnaseq_merged_6',
                             'rnaseq_tissue_6',
                             'genblast_select_5',
                             'vert_pe12_sp_5',
                             'vert_pe12_tr_4',
                             'realign_5',
                             'genblast_select_6',
                             'vert_pe12_sp_6',
                             'realign_6',
                             'vert_pe12_tr_6',
                             'rnaseq_merged_7',
                             'rnaseq_tissue_7',
                             'genblast_select_7',
                             'vert_pe12_sp_7',
                             'realign_7',
                             'vert_pe12_tr_7',
    ],

    birds_basic => [
    ],

    hemiptera_basic => [
                               'IG_C_gene',
                               'IG_J_gene',
                               'IG_V_gene',
                               'IG_D_gene',
                               'TR_C_gene',
                               'TR_J_gene',
                               'TR_V_gene',
                               'TR_D_gene',
                               'seleno_self',
                             'cdna2genome',
                             'edited',
                             'gw_gtag',
                             'gw_nogtag',
                             'gw_exo',
                             'rnaseq_merged_1',
                             'rnaseq_merged_2',
                             'rnaseq_merged_3',
                             'rnaseq_merged_4',
                             'rnaseq_merged_5',
                             'rnaseq_merged_6',
                             'rnaseq_merged_7',
                             'rnaseq_tissue_1',
                             'rnaseq_tissue_2',
                             'rnaseq_tissue_3',
                             'rnaseq_tissue_4',
                             'rnaseq_tissue_5',
                             'rnaseq_tissue_6',
                             'rnaseq_tissue_7',
                             'self_pe12_sp_1',
                             'self_pe12_tr_1',
                             'self_pe12_sp_2',
                             'self_pe12_tr_2',
                             'self_pe12_sp_3',
                             'self_pe12_tr_3',
                             'self_pe12_sp_4',
                             'self_pe12_tr_4',
                             'hemiptera_pe12_sp_1',
                             'pisum_pe12_sp_1',
                             'drosophila_sp_1',
                             'flies_sp_1',
                             'hemiptera_pe12_sp_2',
                             'pisum_pe12_sp_2',
                             'drosophila_sp_2',
                             'flies_sp_2',
                             'hemiptera_pe12_sp_3',
                             'pisum_pe12_sp_3',
                             'drosophila_sp_3',
                             'flies_sp_3',
                             'hemiptera_pe12_sp_4',
                             'pisum_pe12_sp_4',
                             'drosophila_sp_4',
                             'flies_sp_4',
                             'hemiptera_pe12_tr_1',
                             'pisum_pe12_tr_1',
                             'drosophila_tr_1',
                             'flies_tr_1',
                             'hemiptera_pe12_tr_2',
                             'pisum_pe12_tr_2',
                             'drosophila_tr_2',
                             'flies_tr_2',
                             'hemiptera_pe12_tr_3',
                             'pisum_pe12_tr_3',
                             'drosophila_tr_3',
                             'flies_tr_3',
                             'hemiptera_pe12_tr_4',
                             'pisum_pe12_tr_4',
                             'drosophila_tr_4',
                             'flies_tr_4',
                             'rnaseq_merged',
                             'rnaseq_tissue',
    ],

    lepidoptera_basic => [
			  'IG_C_gene',
			  'IG_J_gene',
			  'IG_V_gene',
			  'IG_D_gene',
			  'TR_C_gene',
			  'TR_J_gene',
			  'TR_V_gene',
			  'TR_D_gene',
			  'seleno_self',
			  'pcp_protein_coding',
			  'cdna2genome',
			  'edited',
			  'gw_gtag',
			  'gw_exo',
			  'rnaseq_merged_1',
			  'rnaseq_merged_2',
			  'rnaseq_merged_3',
			  'rnaseq_tissue_1',
			  'rnaseq_tissue_2',
			  'rnaseq_tissue_3',
			  'self_pe12_sp_1',
			  'self_pe12_tr_1',
			  'self_pe12_sp_2',
			  'self_pe12_tr_2',
			  'projection_1',
			  'projection_2',
			  'projection_3',
			  'rnaseq_merged_4',
			  'rnaseq_tissue_4',
			  'human_pe12_sp_1',
			  'human_pe12_tr_1',
			  'lepidoptera_pe12_sp_1',
			  'lepidoptera_pe12_tr_1',
			  'human_pe12_tr_2',
			  'human_pe12_sp_2',
			  'lepidoptera_pe12_sp_2',
			  'lepidoptera_pe12_tr_2',
			  'genblast_rnaseq_top',
			  'projection_4',
			  'rnaseq_merged_5',
			  'rnaseq_tissue_5',
			  'dicondylia_pe12_sp_1',
			  'dicondylia_pe12_tr_1',
			  'dicondylia_pe12_sp_2',
			  'dicondylia_pe12_tr_2',
			  'self_pe3_sp_1',
			  'self_pe3_tr_1',
			  'self_pe3_sp_2',
			  'self_pe3_tr_2',
			  'genblast_rnaseq_high',
			  'human_pe12_sp_3',
			  'human_pe12_tr_3',
			  'lepidoptera_pe12_sp_3',
			  'lepidoptera_pe12_tr_3',
			  'human_pe12_sp_4',
			  'human_pe12_tr_4',
			  'lepidoptera_pe12_sp_4',
			  'lepidoptera_pe12_tr_4',
			  'genblast_rnaseq_medium',
			  'dicondylia_pe12_sp_3',
			  'dicondylia_pe12_tr_3',
			  'dicondylia_pe12_sp_4',
			  'dicondylia_pe12_tr_4',
			  'self_pe3_sp_3',
			  'self_pe3_tr_3',
			  'self_pe3_sp_4',
			  'self_pe3_tr_4',
			  'rnaseq_merged_6',
			  'rnaseq_tissue_6',
			  'human_pe12_sp_int_1',
			  'human_pe12_tr_int_1',
			  'human_pe12_sp_int_2',
			  'human_pe12_tr_int_2',
			  'human_pe12_sp_int_3',
			  'human_pe12_tr_int_3',
			  'human_pe12_sp_int_4',
			  'human_pe12_tr_int_4',
			  'lepidoptera_pe12_sp_int_1',
			  'lepidoptera_pe12_tr_int_1',
			  'lepidoptera_pe12_sp_int_2',
			  'lepidoptera_pe12_tr_int_2',
			  'lepidoptera_pe12_sp_int_3',
			  'lepidoptera_pe12_tr_int_3',
			  'lepidoptera_pe12_sp_int_4',
			  'lepidoptera_pe12_tr_int_4',
			  'dicondylia_pe12_sp_int_1',
			  'dicondylia_pe12_tr_int_1',
			  'dicondylia_pe12_sp_int_2',
			  'dicondylia_pe12_tr_int_2',
			  'dicondylia_pe12_sp_int_3',
			  'dicondylia_pe12_tr_int_3',
			  'dicondylia_pe12_sp_int_4',
			  'dicondylia_pe12_tr_int_4',
			  'self_pe3_sp_int_1',
			  'self_pe3_tr_int_1',
			  'self_pe3_sp_int_2',
			  'self_pe3_tr_int_2',
			  'self_pe3_sp_int_3',
			  'self_pe3_tr_int_3',
			  'self_pe3_sp_int_4',
			  'self_pe3_tr_int_4',
    ],

    atroparvus_basic => [
              'atroparvus_pe12_sp_1',
              'atroparvus_pe12_sp_2',
              'atroparvus_pe12_sp_3',
              'atroparvus_pe12_sp_4',
              'atroparvus_pe12_sp_int_1',
              'atroparvus_pe12_sp_int_2',
              'atroparvus_pe12_sp_int_3',
              'atroparvus_pe12_sp_int_4',
              'atroparvus_pe12_tr_1',
              'atroparvus_pe12_tr_2',
              'atroparvus_pe12_tr_3',
              'atroparvus_pe12_tr_4',
              'atroparvus_pe12_tr_int_1',
              'atroparvus_pe12_tr_int_2',
              'atroparvus_pe12_tr_int_3',
              'atroparvus_pe12_tr_int_4',
              'cdna2genome',
              'culicidae_pe12_sp_1',
              'culicidae_pe12_sp_2',
              'culicidae_pe12_sp_3',
              'culicidae_pe12_sp_4',
              'culicidae_pe12_sp_int_1',
              'culicidae_pe12_sp_int_2',
              'culicidae_pe12_sp_int_3',
              'culicidae_pe12_sp_int_4',
              'culicidae_pe12_tr_1',
              'culicidae_pe12_tr_2',
              'culicidae_pe12_tr_3',
              'culicidae_pe12_tr_4',
              'culicidae_pe12_tr_int_1',
              'culicidae_pe12_tr_int_2',
              'culicidae_pe12_tr_int_3',
              'culicidae_pe12_tr_int_4',
              'dicondylia_pe12_sp_1',
              'dicondylia_pe12_sp_2',
              'dicondylia_pe12_sp_3',
              'dicondylia_pe12_sp_4',
              'dicondylia_pe12_sp_int_1',
              'dicondylia_pe12_sp_int_2',
              'dicondylia_pe12_sp_int_3',
              'dicondylia_pe12_sp_int_4',
              'dicondylia_pe12_tr_1',
              'dicondylia_pe12_tr_2',
              'dicondylia_pe12_tr_3',
              'dicondylia_pe12_tr_4',
              'dicondylia_pe12_tr_int_1',
              'dicondylia_pe12_tr_int_2',
              'dicondylia_pe12_tr_int_3',
              'dicondylia_pe12_tr_int_4',
              'edited',
              'genblast_rnaseq_high',
              'genblast_rnaseq_medium',
              'genblast_rnaseq_top',
              'gw_exo',
              'gw_gtag',
              'human_pe12_sp_1',
              'human_pe12_sp_2',
              'human_pe12_sp_3',
              'human_pe12_sp_4',
              'human_pe12_sp_int_1',
              'human_pe12_sp_int_2',
              'human_pe12_sp_int_3',
              'human_pe12_sp_int_4',
              'human_pe12_tr_1',
              'human_pe12_tr_2',
              'human_pe12_tr_3',
              'human_pe12_tr_4',
              'human_pe12_tr_int_1',
              'human_pe12_tr_int_2',
              'human_pe12_tr_int_3',
              'human_pe12_tr_int_4',
              'IG_C_gene',
              'IG_D_gene',
              'IG_J_gene',
              'IG_V_gene',
              'pcp_protein_coding',
              'projection_1_noncanon',
              'projection_1_pseudo',
              'projection_1',
              'projection_2_noncanon',
              'projection_2_pseudo',
              'projection_2',
              'projection_3_noncanon',
              'projection_3_pseudo',
              'projection_3',
              'projection_4_noncanon',
              'projection_4_pseudo',
              'projection_4',
              'rnaseq_merged_1',
              'rnaseq_merged_2',
              'rnaseq_merged_3',
              'rnaseq_merged_4',
              'rnaseq_merged_5',
              'rnaseq_merged_6',
              'rnaseq_merged_7',
              'rnaseq_merged',
              'rnaseq_tissue_1',
              'rnaseq_tissue_2',
              'rnaseq_tissue_3',
              'rnaseq_tissue_4',
              'rnaseq_tissue_5',
              'rnaseq_tissue_6',
              'rnaseq_tissue_7',
              'rnaseq_tissue',
              'seleno_self',
              'self_pe12_sp_1',
              'self_pe12_sp_2',
              'self_pe12_tr_1',
              'self_pe12_tr_2',
              'self_pe3_sp_1',
              'self_pe3_sp_2',
              'self_pe3_sp_3',
              'self_pe3_sp_4',
              'self_pe3_sp_int_1',
              'self_pe3_sp_int_2',
              'self_pe3_sp_int_3',
              'self_pe3_sp_int_4',
              'self_pe3_tr_1',
              'self_pe3_tr_2',
              'self_pe3_tr_3',
              'self_pe3_tr_4',
              'self_pe3_tr_int_1',
              'self_pe3_tr_int_2',
              'self_pe3_tr_int_3',
              'self_pe3_tr_int_4',
              'TR_C_gene',
              'TR_D_gene',
              'TR_J_gene',
              'TR_V_gene',
    ],

    perniciosus_basic => [
        'perniciosus_pe12_sp_1',
        'perniciosus_pe12_sp_2',
        'perniciosus_pe12_sp_3',
        'perniciosus_pe12_sp_4',
        'perniciosus_pe12_sp_int_1',
        'perniciosus_pe12_sp_int_2',
        'perniciosus_pe12_sp_int_3',
        'perniciosus_pe12_sp_int_4',
        'perniciosus_pe12_tr_1',
        'perniciosus_pe12_tr_2',
        'perniciosus_pe12_tr_3',
        'perniciosus_pe12_tr_4',
        'perniciosus_pe12_tr_int_1',
        'perniciosus_pe12_tr_int_2',
        'perniciosus_pe12_tr_int_3',
        'perniciosus_pe12_tr_int_4',
        'cdna2genome',
        'psychodidae_pe12_sp_1',
        'psychodidae_pe12_sp_2',
        'psychodidae_pe12_sp_3',
        'psychodidae_pe12_sp_4',
        'psychodidae_pe12_sp_int_1',
        'psychodidae_pe12_sp_int_2',
        'psychodidae_pe12_sp_int_3',
        'psychodidae_pe12_sp_int_4',
        'psychodidae_pe12_tr_1',
        'psychodidae_pe12_tr_2',
        'psychodidae_pe12_tr_3',
        'psychodidae_pe12_tr_4',
        'psychodidae_pe12_tr_int_1',
        'psychodidae_pe12_tr_int_2',
        'psychodidae_pe12_tr_int_3',
        'psychodidae_pe12_tr_int_4',
        'dicondylia_pe12_sp_1',
        'dicondylia_pe12_sp_2',
        'dicondylia_pe12_sp_3',
        'dicondylia_pe12_sp_4',
        'dicondylia_pe12_sp_int_1',
        'dicondylia_pe12_sp_int_2',
        'dicondylia_pe12_sp_int_3',
        'dicondylia_pe12_sp_int_4',
        'dicondylia_pe12_tr_1',
        'dicondylia_pe12_tr_2',
        'dicondylia_pe12_tr_3',
        'dicondylia_pe12_tr_4',
        'dicondylia_pe12_tr_int_1',
        'dicondylia_pe12_tr_int_2',
        'dicondylia_pe12_tr_int_3',
        'dicondylia_pe12_tr_int_4',
        'edited',
        'genblast_rnaseq_high',
        'genblast_rnaseq_medium',
        'genblast_rnaseq_top',
        'gw_exo',
        'gw_gtag',
        'human_pe12_sp_1',
        'human_pe12_sp_2',
        'human_pe12_sp_3',
        'human_pe12_sp_4',
        'human_pe12_sp_int_1',
        'human_pe12_sp_int_2',
        'human_pe12_sp_int_3',
        'human_pe12_sp_int_4',
        'human_pe12_tr_1',
        'human_pe12_tr_2',
        'human_pe12_tr_3',
        'human_pe12_tr_4',
        'human_pe12_tr_int_1',
        'human_pe12_tr_int_2',
        'human_pe12_tr_int_3',
        'human_pe12_tr_int_4',
        'IG_C_gene',
        'IG_D_gene',
        'IG_J_gene',
        'IG_V_gene',
        'pcp_protein_coding',
        'projection_1_noncanon',
        'projection_1_pseudo',
        'projection_1',
        'projection_2_noncanon',
        'projection_2_pseudo',
        'projection_2',
        'projection_3_noncanon',
        'projection_3_pseudo',
        'projection_3',
        'projection_4_noncanon',
        'projection_4_pseudo',
        'projection_4',
        'rnaseq_merged_1',
        'rnaseq_merged_2',
        'rnaseq_merged_3',
        'rnaseq_merged_4',
        'rnaseq_merged_5',
        'rnaseq_merged_6',
        'rnaseq_merged_7',
        'rnaseq_merged',
        'rnaseq_tissue_1',
        'rnaseq_tissue_2',
        'rnaseq_tissue_3',
        'rnaseq_tissue_4',
        'rnaseq_tissue_5',
        'rnaseq_tissue_6',
        'rnaseq_tissue_7',
        'rnaseq_tissue',
        'seleno_self',
        'self_pe12_sp_1',
        'self_pe12_sp_2',
        'self_pe12_tr_1',
        'self_pe12_tr_2',
        'self_pe3_sp_1',
        'self_pe3_sp_2',
        'self_pe3_sp_3',
        'self_pe3_sp_4',
        'self_pe3_sp_int_1',
        'self_pe3_sp_int_2',
        'self_pe3_sp_int_3',
        'self_pe3_sp_int_4',
        'self_pe3_tr_1',
        'self_pe3_tr_2',
        'self_pe3_tr_3',
        'self_pe3_tr_4',
        'self_pe3_tr_int_1',
        'self_pe3_tr_int_2',
        'self_pe3_tr_int_3',
        'self_pe3_tr_int_4',
        'TR_C_gene',
        'TR_D_gene',
        'TR_J_gene',
        'TR_V_gene',
    ],

    insects_basic => [],

    non_vertebrates_basic => [],

    metazoa_basic => [],

    plants_basic => [],

    fungi_basic => [],

    protists_basic => [],

    self_patch => [
                'self_pe12_sp_95',
                'self_pe12_sp_80',
                'self_pe12_tr_95',
                'self_pe12_tr_80',
                'self_frag_pe12_sp_95',
                'self_frag_pe12_tr_95',
                'self_frag_pe12_sp_80',
                'self_frag_pe12_tr_80',
    ],
  );
  return $config{$key};
}

1;
