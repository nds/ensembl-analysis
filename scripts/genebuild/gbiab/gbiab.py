# Copyright [2019-2021] EMBL-European Bioinformatics Institute
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import os
import shutil
import subprocess
import glob
import re
import multiprocessing
import random

def create_dir(main_output_dir,dir_name):

  target_dir = os.path.join(main_output_dir,dir_name)

  if os.path.exists(target_dir):
    print ("Directory already exists, will not create again")
    return target_dir

  print ("Attempting to create target dir: %s" % target_dir)

  try:
    os.mkdir(target_dir)

  except OSError:
    print ("Creation of the dir failed, path used: %s" % target_dir)
  else:
    print ("Successfully created the dir on the following path: %s" % target_dir)

  return target_dir


def run_red(red_path,main_output_dir,genome_file):

  if not red_path:
    red_path = 'Red'

  check_exe(red_path)
  red_dir = create_dir(main_output_dir,'red_output')
  red_mask_dir = create_dir(red_dir,'mask_output')
  red_repeat_dir = create_dir(red_dir,'repeat_output')
  red_genome_dir = create_dir(red_dir,'genome_dir')

  sym_link_genome_cmd = 'ln -s ' + genome_file + ' ' + red_genome_dir

  genome_file_name = os.path.basename(genome_file)
  red_genome_file = os.path.join(red_genome_dir,genome_file_name)
  masked_genome_file = os.path.join(red_mask_dir,os.path.splitext(genome_file_name)[0] + ".msk")

  if os.path.exists(masked_genome_file):
    print ('Masked Genome file already found on the path to the Red mask output dir. Will not create a new file')
    return masked_genome_file

  if os.path.exists(red_genome_file):
    print ('Unmasked genome file already found on the path to the Red genome dir, will not create a sym link')

  else:
    print ('Preparing to sym link the genome file to the Red genome dir. Cmd\n%s' % sym_link_genome_cmd)
    subprocess.run(['ln','-s',genome_file,red_genome_dir])

  if not os.path.exists(os.path.join(red_genome_dir,genome_file_name)):
    print ('Could not find the genome file in the Red genome dir or sym link to the original file. Path expected:\n%s' % red_genome_file)

  print ('Running Red, this may take some time depending on the genome size')
  subprocess.run([red_path,'-gnm',red_genome_dir,'-msk',red_mask_dir,'-rpt',red_repeat_dir])

  print ('Completed running Red')

  return masked_genome_file


def run_genblast_align(genblast_path,convert2blastmask_path,makeblastdb_path,main_output_dir,protein_file,masked_genome_file,num_threads):

  if not genblast_path:
    genblast_path = 'genblast'

  check_exe(genblast_path)

  if not convert2blastmask_path:
    convert2blastmask_path = 'convert2blastmask'

  check_exe(convert2blastmask_path)

  if not makeblastdb_path:
    makeblastdb_path = 'makeblastdb'

  check_exe(makeblastdb_path)

  genblast_dir = create_dir(main_output_dir,'genblast_output')

  genblast_output_file = os.path.join(genblast_dir,'genblast')

  asnb_file = masked_genome_file + '.asnb'
  print ("ASNB file: %s" % asnb_file)

  if not os.path.exists('alignscore.txt'):
    subprocess.run(['cp','/homes/fergal/enscode/ensembl-analysis/scripts/genebuild/gbiab/support_files/alignscore.txt','./'])

  if not os.path.exists(masked_genome_file):
    raise IOError('Masked genome file does not exist: %s' % masked_genome_file)

  if not os.path.exists(protein_file):
    raise IOError('Protein file does not exist: %s' % protein_file)

  if not os.path.exists(asnb_file):
    run_convert2blastmask(convert2blastmask_path,masked_genome_file,asnb_file)
  else:
    print ('Found an existing asnb, so will skip convert2blastmask')

  if not os.path.exists(asnb_file):
    raise IOError('asnb file does not exist: %s' % asnb_file)

  run_makeblastdb(makeblastdb_path,masked_genome_file,asnb_file)

  batched_protein_files = split_protein_file(protein_file,genblast_dir)

  pool = multiprocessing.Pool(int(num_threads))
  for batched_protein_file in batched_protein_files:
    pool.apply_async(multiprocess_genblast, args=(batched_protein_file,masked_genome_file,genblast_path,))

  pool.close()
  pool.join()

  print ('Completed running GenBlast')
  print ('Combining output into single GTF')
  generate_genblast_gtf(genblast_dir)


def multiprocess_genblast(batched_protein_file,masked_genome_file,genblast_path):

  batch_num = os.path.splitext(batched_protein_file)[0]
  batch_dir = os.path.dirname(batched_protein_file)
  print("Running GenBlast on " + batched_protein_file + ":")
  
  genblast_cmd = [genblast_path,'-p','genblastg','-q',batched_protein_file,'-t',masked_genome_file,'-g','T','-pid','-r','1','-P','blast','-gff','-e','1e-1','-c','0.5','-W','3','-softmask','-scodon','50','-i','30','-x','10','-n','30','-d','100000','-o',batched_protein_file]

  print(" ".join(genblast_cmd))
  subprocess.run(genblast_cmd)


def generate_genblast_gtf(genblast_dir):
  file_out_name = os.path.join(genblast_dir,"annotation.gtf")
  file_out = open(file_out_name,'w+')
  genblast_extension = '_1.1c_2.3_s1_0_16_1'
  for root, dirs, files in os.walk(genblast_dir):
    for genblast_file in files:
      genblast_file = os.path.join(root,genblast_file)
      if genblast_file.endswith(".gff"):
        gtf_string = convert_gff_to_gtf(genblast_file)
        file_out.write(gtf_string)      
      elif genblast_file.endswith(".fa.blast") or genblast_file.endswith(".fa.blast.report") or genblast_file.endswith(genblast_extension):
        subprocess.run(['rm',genblast_file])
  file_out.close()


def convert_gff_to_gtf(genblast_file):
  gtf_string = ""
  file_in = open(genblast_file)
  line = file_in.readline()
  while line:
    match = re.search(r"genBlastG",line)
    if match:
      results = line.split()
      if results[2] == "coding_exon":
        results[2] = "exon"
      attributes = set_attributes(results[8],results[2])
      results[8] = attributes
      converted_line = "\t".join(results)
      gtf_string += converted_line + "\n"
    line = file_in.readline()
  file_in.close()  
  return gtf_string


def set_attributes(attributes,feature_type):

  converted_attributes = ""
  split_attributes = attributes.split(";")
  if feature_type == "transcript":
    match = re.search(r"Name\=(.+)$",split_attributes[1])
    name = match.group(1)
    converted_attributes = 'gene_id "' + name + '"; transcript_id "' + name + '";'
  elif feature_type == "exon":
    match = re.search(r"\-E(\d+);Parent\=(.+)\-R\d+\-\d+\-",attributes)
    exon_rank = match.group(1)
    name = match.group(2)
    converted_attributes = 'gene_id "' + name + '"; transcript_id "' + name + '"; exon_number "' + exon_rank + '";'

  return converted_attributes

# Example genBlast output
#1       genBlastG       transcript      131128674       131137049       252.729 -       .       ID=259447-R1-1-A1;Name=259447;PID=84.65;Coverage=94.22;Note=PID:84.65-Cover:94.22
#1       genBlastG       coding_exon     131137031       131137049       .       -       .       ID=259447-R1-1-A1-E1;Parent=259447-R1-1-A1
#1       genBlastG       coding_exon     131136260       131136333       .       -       .       ID=259447-R1-1-A1-E2;Parent=259447-R1-1-A1
#1       genBlastG       coding_exon     131128674       131130245       .       -       .       ID=259447-R1-1-A1-E3;Parent=259447-R1-1-A1
##sequence-region       1_group1        1       4534
#1       genBlastG       transcript      161503457       161503804       30.94   +       .       ID=259453-R1-1-A1;Name=259453;PID=39.46;Coverage=64.97;Note=PID:39.46-Cover:64.97
#1       genBlastG       coding_exon     161503457       161503804       .       +       .       ID=259453-R1-1-A1-E1;Parent=259453-R1-1-A1
##sequence-region       5_group1        1       4684
#5       genBlastG       transcript      69461063        69461741        86.16   +       .       ID=259454-R1-1-A1;Name=259454;PID=82.02;Coverage=91.67;Note=PID:82.02-Cover:91.67
#5       genBlastG       coding_exon     69461063        69461081        .       +       .       ID=259454-R1-1-A1-E1;Parent=259454-R1-1-A1
#5       genBlastG       coding_exon     69461131        69461741        .       +       .       ID=259454-R1-1-A1-E2;Parent=259454-R1-1-A1


def split_protein_file(protein_file,genblast_dir):
  batch_size = 20
  batched_protein_files = []

  for i in range(0,10):
    create_dir(genblast_dir,('bin_' + str(i)))

  file_in = open(protein_file)
  line = file_in.readline()
  seq_count = 0
  batch_count = 0
  current_record = ""
  initial_seq = 1
  while line:
    num_dir = random.randint(0,9)
    match = re.search(r'>(.+)$',line)
    if match and not initial_seq and seq_count % batch_size == 0:
      file_out_name = os.path.join(genblast_dir,('bin_' + str(random.randint(0,9))),(str(batch_count) + '.fa'))
      file_out = open(file_out_name,'w+')
      file_out.write(current_record)
      file_out.close()
      batch_count += 1
      seq_count += 1
      current_record = line
      batched_protein_files.append(file_out_name)
    elif match:
      current_record += line
      initial_seq = 0
      seq_count += 1
    else:
      current_record += line
    line = file_in.readline()
  file_in.close()

  if current_record:
    file_out_name = os.path.join(genblast_dir,('bin_' + str(random.randint(0,9))),(str(batch_count) + '.fa'))
    file_out = open(file_out_name,'w+')
    file_out.write(current_record)
    file_out.close()
    batched_protein_files.append(file_out_name)

  return batched_protein_files


def run_convert2blastmask(convert2blastmask_path,masked_genome_file,asnb_file):

  asnb_file = masked_genome_file + '.asnb'
  print ('Running convert2blastmask prior to GenBlast:')
  cmd = [convert2blastmask_path,'-in',masked_genome_file,'-parse_seqids','-masking_algorithm','other','-masking_options','"REpeatDetector, default"','-outfmt','maskinfo_asn1_bin','-out',asnb_file]
  print(' '.join(cmd))
  subprocess.run(cmd)
  print ('Completed running convert2blastmask')


def run_makeblastdb(makeblastdb_path,masked_genome_file,asnb_file):

  print ('Running makeblastdb prior to GenBlast')
  subprocess.run([makeblastdb_path,'-in',masked_genome_file,'-dbtype','nucl','-parse_seqids','-mask_data',asnb_file,'-max_file_sz','10000000000'])
  print ('Completed running makeblastdb')


def run_star_align(star_path,subsample_script_path,main_output_dir,short_read_fastq_dir,genome_file,max_reads_per_sample,max_total_reads,num_threads):
  # !!! Need to add in samtools path above instead of just using 'samtools' in command

  if not star_path:
    star_path = 'STAR'

  check_exe(star_path)

  if not os.path.exists(subsample_script_path):
    subsample_script_path = 'subsample_fastq.py'

  star_dir = create_dir(main_output_dir,'star_output')
  star_tmp_dir = os.path.join(star_dir,'tmp')
  if os.path.exists(star_tmp_dir):
    subprocess.run(['rm','-rf',star_tmp_dir])

  star_index_file = os.path.join(star_dir,'SAindex')

  fastq_file_list = []
  file_types = ('*.fastq','*.fq','*.fastq.gz','*.fq.gz')
  for file_type in file_types:
    fastq_file_list.extend(glob.glob(os.path.join(short_read_fastq_dir,file_type)))

  # This works out if the files are paired or not
  fastq_file_list = create_paired_paths(fastq_file_list)

  # Subsamples in parallel if there's a value set
  if max_reads_per_sample:
    pool = multiprocessing.Pool(int(num_threads))
    for fastq_files in fastq_file_list:
      fastq_file = fastq_files[0]
      fastq_file_pair = ''
      if(len(fastq_files) == 2):
        fastq_file_pair = fastq_files[1]

      if fastq_file_pair and os.path.exists(fastq_file + '.sub') and os.path.exists(fastq_file_pair + '.sub'):
        print("Found an existing .sub files on the fastq path for both members of the pair, will use those instead of subsampling again. Files:")
        print(fastq_file + '.sub')
        print(fastq_file_pair + '.sub')
      elif fastq_file_pair:
        pool.apply_async(run_subsample_script, args=(fastq_file,fastq_file_pair,subsample_script_path,))
      elif os.path.exists(fastq_file + '.sub'):
        print("Found an existing .sub file on the fastq path, will use that instead. File:")
        print(fastq_file + '.sub')
      else:
        pool.apply_async(run_subsample_script, args=(fastq_file,fastq_file_pair,subsample_script_path,))

    pool.close()
    pool.join()

  fastq_file_list = check_for_fastq_subsamples(fastq_file_list)

  if not fastq_file_list:
    raise IndexError('The list of fastq files is empty. Fastq dir:\n%s' % short_read_fastq_dir) 

  if not os.path.exists(star_index_file):
    print ('Did not find an index file for Star. Will create now')
    subprocess.run([star_path,'--runThreadN',str(num_threads),'--runMode','genomeGenerate','--outFileNamePrefix',(star_dir + '/'),'--genomeDir',star_dir,'--genomeFastaFiles',genome_file])

  if not star_index_file:
    raise IOError('The index file does not exist. Expected path:\n%s' % star_index_file)

  print ('Running Star on the files in the fastq dir')
  for fastq_file_path in fastq_file_list:
    print(fastq_file_path)
    fastq_file_name = os.path.basename(fastq_file_path)
    check_compression= re.search(r'.gz$',fastq_file_name)
    print ("Processing %s" % fastq_file_path)

    star_command = [star_path,'--outFilterIntronMotifs','RemoveNoncanonicalUnannotated','--outSAMstrandField','intronMotif','--runThreadN',str(num_threads),'--twopassMode','Basic','--runMode','alignReads','--genomeDir',star_dir,'--readFilesIn',fastq_file_path,'--outFileNamePrefix',(star_dir + '/'),'--outTmpDir',star_tmp_dir,'--outSAMtype','SAM','--alignIntronMax','100000','--outSJfilterIntronMaxVsReadN','5000','10000','25000','40000','50000','50000','50000','50000','50000','100000']

    if check_compression:
      star_command.append('--readFilesCommand')
      star_command.append('gunzip')
      star_command.append('-c')

    subprocess.run(star_command)
    subprocess.run(['mv',os.path.join(star_dir,'Aligned.out.sam'),os.path.join(star_dir,(fastq_file_name + '.sam'))])
    subprocess.run(['mv',os.path.join(star_dir,'SJ.out.tab'),os.path.join(star_dir,(fastq_file_name + '.sj.tab'))])

  print ('Completed running STAR')

  print ('Sorting sam files into bams')

  # Should move the sorting below into a method that takes a dir as an argument
  sam_files = []
  for sam_file in glob.glob(star_dir + "/*.sam"):
    sam_files.append(sam_file)

  if not sam_files:
    raise IndexError('The list of sam files is empty, expected them in Star output dir. Star dir:\n%s' % star_dir)

  sorted_bam_files = []
  for sam_file in sam_files:
    sam_file_name = os.path.basename(sam_file)
    sam_temp_file_path = os.path.join(star_dir,(sam_file_name + ".tmp"))
    bam_sort_file_path = os.path.join(star_dir,re.sub('.sam','.bam',sam_file_name))

    if os.path.exists(bam_sort_file_path):
      print("Found an existing bam file, will not sort sam file again. Bam file:")
      print(bam_sort_file_path)

    else:
      print("Converting samfile into sorted bam file. Bam file:")
      print(bam_sort_file_path)
      subprocess.run(['samtools','sort','-@',str(num_threads),'-T',sam_temp_file_path,'-o',bam_sort_file_path,sam_file])



def run_subsample_script(fastq_file,fastq_file_pair,subsample_script_path):

  if fastq_file_pair:
    subprocess.run(['python3',subsample_script_path,'--fastq_file',fastq_file,'--fastq_file_pair',fastq_file_pair])
  else:
    subprocess.run(['python3',subsample_script_path,'--fastq_file',fastq_file])


def check_for_fastq_subsamples(fastq_file_list):
  # This should probably removed at some point as it is needlessly complicated
  # Would be better to just build into the previous step
  # Mainly just about making sure that if you have subsamples they're used and if you have pairs they're paired
  for idx,fastq_files in enumerate(fastq_file_list):
    fastq_file = fastq_files[0]
    subsample_file = fastq_file + ".sub"

    fastq_file_pair = ''
    subsample_file_pair = '' 
    if(len(fastq_files) == 2):
      fastq_file_pair = fastq_files[1]
      subsample_file_pair = fastq_file_pair + ".sub"
 
    # This bit will replace the list entry with a string, don't need a list after this function for each pair/file
    if os.path.exists(subsample_file):
      print("Found a subsampled file extension, will use that instead of the original file. Path:")
      print(subsample_file)
      fastq_file_list[idx] = subsample_file
    else:
      fastq_file_list[idx] = fastq_file

    # This bit just concats the paired file (or subsampled paired file) if it exists
    if os.path.exists(subsample_file_pair):
      print("Found a subsampled paired file extension, will use that instead of the original file. Path:")
      print(subsample_file_pair)
      fastq_file_list[idx] = subsample_file + ',' + subsample_file_pair
    elif fastq_file_pair:
      fastq_file_list[idx] = fastq_file + ',' + fastq_file_pair

    print("Entry at current index:")
    print(fastq_file_list[idx])

  return(fastq_file_list)


def run_minimap2_align(minimap2_path,paftools_path,main_output_dir,long_read_fastq_dir,genome_file,num_threads):

  if not minimap2_path:
    minimap2_path = 'minimap2'

  check_exe(minimap2_path)

  if not paftools_path:
    paftools_path = '/hps/nobackup2/production/ensembl/fergal/coding/long_read_aligners/new_mm2/minimap2/misc/paftools.js'

  check_exe(paftools_path)

  minimap2_dir = create_dir(main_output_dir,'minimap2_output')

  genome_file_name = os.path.basename(genome_file)
  genome_file_index = (genome_file_name + '.mmi')
  minimap2_index_file = os.path.join(minimap2_dir,genome_file_index)
  minimap2_hints_file = os.path.join(minimap2_dir,'minimap2_hints.gff')

  fastq_file_list = []
  for fastq_file in glob.glob(long_read_fastq_dir + "/*.fastq"):
    fastq_file_list.append(fastq_file)

  for fastq_file in glob.glob(long_read_fastq_dir + "/*.fq"):
    fastq_file_list.append(fastq_file)

  if not fastq_file_list:
    raise IndexError('The list of fastq files is empty. Fastq dir:\n%s' % long_read_fastq_dir) 

  if not os.path.exists(minimap2_index_file):
    print ('Did not find an index file for minimap2. Will create now')
    subprocess.run([minimap2_path,'-t',num_threads,'-d',os.path.join(minimap2_index_file),genome_file])

  if not minimap2_index_file:
    raise IOError('The minimap2 index file does not exist. Expected path:\n%s' % minimap2_index_file)

  print ('Running minimap2 on the files in the long read fastq dir')
  for fastq_file_path in fastq_file_list:
    fastq_file_name = os.path.basename(fastq_file_path)
    sam_file = os.path.join(minimap2_dir,(fastq_file_name + '.sam'))
    bed_file = os.path.join(minimap2_dir,(fastq_file_name + '.bed'))
    bed_file_out = open(bed_file,'w+')
    print ("Processing %s" % fastq_file)
    subprocess.run([minimap2_path,'-t',num_threads,'--cs','-N','1','-ax','splice:hq','-u','b',minimap2_index_file,fastq_file_path,'-o',sam_file])
    print("Creating bed file from SAM")
    subprocess.run([paftools_path,'splice2bed',sam_file],stdout=bed_file_out)
    bed_file_out.close()

  bed_to_gff(minimap2_dir,minimap2_hints_file)

  print ('Completed running minimap2')

def bed_to_gff(input_dir,hints_file):

  gff_out = open(hints_file,"w+")
  exons_dict = {}
  for bed_file in glob.glob(input_dir + "/*.bed"):
    print("Processing file for hints:")
    print(bed_file)
    bed_in = open(bed_file)
    bed_lines = bed_in.readlines()
    for line in bed_lines:
      line = line.rstrip()
      elements = line.split('\t')
      seq_region_name = elements[0]
      offset = int(elements[1])
      hit_name = elements[3]
      strand = elements[5]
      block_sizes = elements[10].split(',')
      block_sizes = list(filter(None, block_sizes))
      block_starts = elements[11].split(',')
      block_starts = list(filter(None, block_starts))
      exons = bed_to_exons(block_sizes,block_starts,offset)
      for i,element in enumerate(exons):
        exon_coords = exons[i]
        exon_key = seq_region_name + ':' + exon_coords[0] + ':' + exon_coords[1] + ':' + strand
        if exon_key in exons_dict:
          exons_dict[exon_key][5] += 1
        else:
          gff_list = [seq_region_name,'CDNA','exon',exon_coords[0],exon_coords[1],1.0,strand,'.']
          exons_dict[exon_key] = gff_list

  for exon_key, gff_list in exons_dict.items():
    gff_list[5] = str(gff_list[5])
    gff_line = '\t'.join(gff_list) + '\tsrc=W;mul=' + gff_list[5] + ';\n'
    gff_out.write(gff_line)

  gff_out.close()

  sorted_hints_out = open((hints_file + '.srt'),'w+')
  subprocess.run(['sort','-k1,1','-k7,7','-k4,4','-k5,5',hints_file],stdout=sorted_hints_out)
  sorted_hints_out.close()

def bed_to_exons(block_sizes,block_starts,offset):
  exons = []
  for i,element in enumerate(block_sizes):
    block_start = offset + int(block_starts[i]) + 1
    block_end = block_start + int(block_sizes[i]) - 1

    if block_end < block_start:
      print('Warning: block end is less than block start, skipping exon')
      continue

    exon_coords = [str(block_start),str(block_end)]
    exons.append(exon_coords)

  return exons


def run_augustus_predict(augustus_path,main_output_dir,genome_file,num_threads):

  min_seq_length = 1000

  if not augustus_path:
    augustus_path = 'augustus'

  check_exe(augustus_path)

  augustus_dir = create_dir(main_output_dir,'augustus_output')
  augustus_genome_dir = create_dir(augustus_dir,'genome_dir')
  augustus_evidence_dir = create_dir(augustus_dir,'evidence')
  augustus_hints_file = os.path.join(augustus_evidence_dir,'augustus_hints.gff')
  star_dir = os.path.join(main_output_dir,'star_output')
  minimap2_dir = os.path.join(main_output_dir,'minimap2_output')
  
  if(os.path.exists(star_dir)):
    print("Found a Star output dir, generating hints from any .sj.tab files")
    splice_junction_to_gff(star_dir,augustus_hints_file)

  print("Splitting the genome into separate files for Augustus. Will ingore sequences of less than",min_seq_length,"in length")
  split_genome(genome_file,augustus_genome_dir,min_seq_length)

  generic_augustus_cmd = [augustus_path,'--species=human',('--hintsfile=' + augustus_hints_file),'--UTR=on','--alternatives-from-evidence=true','--allow_hinted_splicesites=atac',('--extrinsicCfgFile=' + '/homes/thibaut/src/Augustus/config/extrinsic/extrinsic.M.RM.E.W.P.cfg')]
  pool = multiprocessing.Pool(int(num_threads))
  tasks = []
  for seq_file in glob.glob(augustus_genome_dir + "/*.split.fa"):
    augustus_forward = generic_augustus_cmd.copy()
    augustus_forward.append('--strand=forward')
    augustus_forward.append(seq_file)

    augustus_backward = generic_augustus_cmd.copy()
    augustus_backward.append('--strand=backward')
    augustus_backward.append(seq_file)

    pool.apply_async(multiprocess_augustus, args=(augustus_forward,(seq_file + '.forward.gff'),))
    pool.apply_async(multiprocess_augustus, args=(augustus_backward,(seq_file + '.backward.gff'),))

  pool.close()
  pool.join()


def multiprocess_augustus(cmd,output_file):

  file_out = open(output_file,'w+')
  print('Running Augustus with the following command:')
  print(' '.join(cmd))
  print('Output will be directed to:')
  print(output_file)
  subprocess.run(cmd, stdout=file_out)
  file_out.close()


def run_cufflinks_assemble(cufflinks_path,cuffmerge_path,samtools_path,main_output_dir,genome_file,num_threads):

  max_cufflinks_threads = 6
  if num_threads > max_cufflinks_threads:
    print("Reducing threads to " + str(max_cufflinks_threads) + " for cufflinks to keep the memory footprint down")
    num_threads = max_cufflinks_threads

  if not cufflinks_path:
    cufflinks_path = shutil.which('cufflinks')
  check_exe(cufflinks_path)

  if not cuffmerge_path:
    cuffmerge_path = shutil.which('cuffmerge')
  check_exe(cuffmerge_path)

  if not samtools_path:
    samtools_path = shutil.which('samtools')
  check_exe(samtools_path)
  
  cufflinks_dir = create_dir(main_output_dir,'cufflinks_output')
  cuffmerge_dir = create_dir(cufflinks_dir,'merged_asm')
  cuffmerge_input_file = os.path.join(cufflinks_dir,'cufflinks_assemblies.txt')
  star_dir = os.path.join(main_output_dir,'star_output')

  if(os.path.exists(star_dir)):
    print("Found a Star output dir, will load sam file")

  sam_files = []
  for sam_file in glob.glob(star_dir + "/*.sam"):
    sam_files.append(sam_file)

  if not sam_files:
    raise IndexError('The list of sam files is empty, expected them in Star output dir. Star dir:\n%s' % star_dir)


  sorted_bam_files = []
  for sam_file in sam_files:
    sam_file_name = os.path.basename(sam_file)
    sam_temp_file_path = os.path.join(star_dir,(sam_file_name + ".tmp"))
    bam_sort_file_path = os.path.join(star_dir,re.sub('.sam','.bam',sam_file_name))

    if os.path.exists(bam_sort_file_path):
      print("Found an existing bam file, will not sort sam file again. Bam file:")
      print(bam_sort_file_path)

    else:
      print("Converting samfile into sorted bam file. Bam file:")
      print(bam_sort_file_path)
      subprocess.run(['samtools','sort','-@',str(num_threads),'-T',sam_temp_file_path,'-o',bam_sort_file_path,sam_file])

    sorted_bam_files.append(bam_sort_file_path)

  for sorted_bam_file in sorted_bam_files:
    sorted_bam_file_name = os.path.basename(sorted_bam_file)
    transcript_file_name = re.sub('.bam','.gtf',sorted_bam_file_name)
    skipped_file_name = re.sub('.bam','.skipped.gtf',sorted_bam_file_name)
    genes_fpkm_file_name = re.sub('.bam','.genes.fpkm',sorted_bam_file_name)
    isoforms_fpkm_file_name = re.sub('.bam','.isoforms.fpkm',sorted_bam_file_name)

    if os.path.exists(os.path.join(cufflinks_dir,transcript_file_name)):
      print("Found an existing cufflinks gtf file, will not overwrite. File found:")
      print(os.path.join(cufflinks_dir,transcript_file_name))
    else:
      print("Running cufflinks on: " + sorted_bam_file_name)
      print("Writing output to: " + os.path.join(cufflinks_dir,transcript_file_name))
      subprocess.run([cufflinks_path,'--output-dir',cufflinks_dir,'--num-threads',str(num_threads),sorted_bam_file])
      subprocess.run(['mv',os.path.join(cufflinks_dir,'transcripts.gtf'),os.path.join(cufflinks_dir,transcript_file_name)])
      subprocess.run(['mv',os.path.join(cufflinks_dir,'skipped.gtf'),os.path.join(cufflinks_dir,skipped_file_name)])
      subprocess.run(['mv',os.path.join(cufflinks_dir,'genes.fpkm_tracking'),os.path.join(cufflinks_dir,genes_fpkm_file_name)])
      subprocess.run(['mv',os.path.join(cufflinks_dir,'isoforms.fpkm_tracking'),os.path.join(cufflinks_dir,isoforms_fpkm_file_name)])

  # Now need to merge
  print("Creating cuffmerge input file: " + cuffmerge_input_file)

  # Note that I'm writing the subprocess this way because python seems to have issues with wildcards in subprocess.run and this
  # was the answer I found most often from googling
  gtf_list_cmd = 'ls ' + os.path.join(cufflinks_dir,'*.gtf') + ' | grep -v ".skipped." >' + cuffmerge_input_file
  gtf_list_cmd = subprocess.Popen(gtf_list_cmd,shell=True)
  gtf_list_cmd.wait()

  subprocess.run(['python2.7',cuffmerge_path,'-s',genome_file,'-p',str(num_threads),'-o',cuffmerge_dir,cuffmerge_input_file])


def run_stringtie_assemble(stringtie_path,samtools_path,main_output_dir,genome_file,num_threads):

  if not stringtie_path:
    stringtie_path = shutil.which('stringtie')
  check_exe(stringtie_path)

  if not samtools_path:
    samtools_path = shutil.which('samtools')
  check_exe(samtools_path)

  stringtie_dir = create_dir(main_output_dir,'stringtie_output')
  stringtie_merge_input_file = os.path.join(stringtie_dir,'stringtie_assemblies.txt')
  stringtie_merge_output_file = os.path.join(stringtie_dir,'annotation.gtf')
  star_dir = os.path.join(main_output_dir,'star_output')

  if(os.path.exists(star_dir)):
    print("Found a Star output dir, will load sam file")

  sorted_bam_files = []
  for bam_file in glob.glob(star_dir + "/*.bam"):
    sorted_bam_files.append(bam_file)

  if not sorted_bam_files:
    raise IndexError('The list of sorted bam files is empty, expected them in Star output dir. Star dir:\n%s' % star_dir)

  for sorted_bam_file in sorted_bam_files:
    sorted_bam_file_name = os.path.basename(sorted_bam_file)
    transcript_file_name = re.sub('.bam','.gtf',sorted_bam_file_name)
    transcript_file_path = os.path.join(stringtie_dir,transcript_file_name)

    if os.path.exists(transcript_file_path):
      print("Found an existing stringtie gtf file, will not overwrite. File found:")
      print(transcript_file_path)
    else:
      print("Running Stringtie on: " + sorted_bam_file_name)
      print("Writing output to: " + transcript_file_path)
      subprocess.run([stringtie_path,sorted_bam_file,'-o',transcript_file_path,'-p',str(num_threads),'-t','-a','15'])

  # Now need to merge
  print("Creating Stringtie merge input file: " + stringtie_merge_input_file)

  # Note that I'm writing the subprocess this way because python seems to have issues with wildcards in subprocess.run and this
  # was the answer I found most often from googling
  gtf_list_cmd = 'ls ' + os.path.join(stringtie_dir,'*.gtf') + ' | grep -v "annotation.gtf" >' + stringtie_merge_input_file
  gtf_list_cmd = subprocess.Popen(gtf_list_cmd,shell=True)
  gtf_list_cmd.wait()

  if os.path.exists(stringtie_merge_output_file):
    print("Found an existing stringtie merge file, will not overwrite. File found:")
    print(stringtie_merge_output_file)
  else:
    print("Merging Stringtie results. Writing to the following file:")
    print(stringtie_merge_output_file)
    # Note, I'm not sure stringtie merge actually uses threads, but it doesn't complain if -p is passed in
    subprocess.run([stringtie_path,'--merge','-p',str(num_threads),'-o',stringtie_merge_output_file,stringtie_merge_input_file,'-i'])


def run_scallop_assemble(scallop_path,stringtie_path,main_output_dir):

  if not scallop_path:
    scallop_path = shutil.which('scallop')
  check_exe(scallop_path)

  if not stringtie_path:
    stringtie_path = shutil.which('stringtie')
  check_exe(stringtie_path)

  scallop_dir = create_dir(main_output_dir,'scallop_output')
  stringtie_merge_input_file = os.path.join(scallop_dir,'scallop_assemblies.txt')
  stringtie_merge_output_file = os.path.join(scallop_dir,'annotation.gtf')
  star_dir = os.path.join(main_output_dir,'star_output')

  if(os.path.exists(star_dir)):
    print("Found a Star output dir, will load sam file")

  sorted_bam_files = []
  for bam_file in glob.glob(star_dir + "/*.bam"):
    sorted_bam_files.append(bam_file)

  if not sorted_bam_files:
    raise IndexError('The list of sorted bam files is empty, expected them in Star output dir. Star dir:\n%s' % star_dir)

  for sorted_bam_file in sorted_bam_files:
    sorted_bam_file_name = os.path.basename(sorted_bam_file)
    transcript_file_name = re.sub('.bam','.gtf',sorted_bam_file_name)
    transcript_file_path = os.path.join(scallop_dir,transcript_file_name)

    if os.path.exists(transcript_file_path):
      print("Found an existing scallop gtf file, will not overwrite. File found:")
      print(transcript_file_path)
    else:
      print("Running Scallop on: " + sorted_bam_file_name)
      print("Writing output to: " + transcript_file_path)
      subprocess.run([scallop_path,'-i',sorted_bam_file,'-o',transcript_file_path,'--min_flank_length','10'])


  # Now need to merge
  print("Creating Stringtie merge input file: " + stringtie_merge_input_file)

  # Note that I'm writing the subprocess this way because python seems to have issues with wildcards in subprocess.run and this
  # was the answer I found most often from googling
  gtf_list_cmd = 'ls ' + os.path.join(scallop_dir,'*.gtf') + ' | grep -v "annotation.gtf" >' + stringtie_merge_input_file
  gtf_list_cmd = subprocess.Popen(gtf_list_cmd,shell=True)
  gtf_list_cmd.wait()

  if os.path.exists(stringtie_merge_output_file):
    print("Found an existing stringtie merge file, will not overwrite. File found:")
    print(stringtie_merge_output_file)
  else:
    print("Merging Stringtie results. Writing to the following file:")
    print(stringtie_merge_output_file)
    # Note, I'm not sure stringtie merge actually uses threads and is very quick, so leaving out
    subprocess.run([stringtie_path,'--merge','-o',stringtie_merge_output_file,stringtie_merge_input_file])


def splice_junction_to_gff(input_dir,hints_file):
  
  sjf_out = open(hints_file,"w+")
  
  for sj_tab_file in glob.glob(input_dir + "/*.sj.tab"):
    sjf_in = open(sj_tab_file)
    sjf_lines = sjf_in.readlines()
    for line in sjf_lines:
      elements = line.split('\t')
      strand = '+'
      # If the strand is undefined then skip, Augustus expects a strand
      if elements[3] == '0':
        continue
      elif elements[3] == '2':
        strand = '-'

      junction_length = int(elements[2]) - int(elements[1]) + 1
      if junction_length < 100:
        continue

      if not elements[4] and elements[7] < 10:
        continue
       
      # For the moment treat multimapping and single mapping things as a combined score
      score = float(elements[6]) + float(elements[7])
      score = str(score)
      output_line = [elements[0],'RNASEQ','intron',elements[1],elements[2],score,strand,'.',('src=W;mul=' + score + ';')]
      sjf_out.write('\t'.join(output_line) + '\n')

  sjf_out.close()


def split_genome(genome_file,target_dir,min_seq_length):
  # This is the lazy initial way of just splitting into a dir of files based on the toplevel sequence with a min sequence length filter
  # There are a couple of obvious improvements:
  # 1) Instead of making files for all seqs, just process N seqs parallel, where N = num_threads. Then you could clean up the seq file
  #    after each seq finishes, thus avoiding potentially having thousands of file in a dir
  # 2) Split the seq into even slices and process these in parallel (which the same cleanup as in 1). For sequences smaller than the
  #    target slice size, bundle them up together into a single file. Vastly more complex, partially implemented in the splice_genome method
  #    Allows for more consistency with parallelisation (since there should be no large outliers). But require a mapping strategy for the
  #    coords and sequence names and all the hints will need to be adjusted
  current_header = ""
  current_seq = ""

  file_in = open(genome_file)
  line = file_in.readline()
  while line:
    match = re.search(r'>(.+)$',line)
    if match and current_header:
      if len(current_seq) > min_seq_length:
        file_out_name = os.path.join(target_dir,(current_header + '.split.fa'))
        if not os.path.exists(file_out_name):
          file_out = open(file_out_name,'w+')
          file_out.write(">" + current_header + "\n" + current_seq + "\n")
          file_out.close()

        else:
          print("Found an existing split file, so will not overwrite. File found:")
          print(file_out_name)
 
      current_seq = ""
      current_header = match.group(1)
    elif match:
      current_header = match.group(1)
    else:
      current_seq += line.rstrip()

    line = file_in.readline()

  if len(current_seq) > min_seq_length:
    file_out_name =os.path.join(target_dir,(current_header + '.split.fa'))
    if not os.path.exists(file_out_name):
      file_out = open(file_out_name,'w+')
      file_out.write(">" + current_header + "\n" + current_seq + "\n")
      file_out.close()

    else:
      print("Found an existing split file, so will not overwrite. File found:")
      print(file_out_name)

  file_in.close()


def run_finalise_geneset(work_dir,genome_file,seq_region_names,num_threads):
  merged_gtf = os.path.join(work_dir,'annotation_to_finalise.gtf')
  file_out = open(merged_gtf, 'w')  
  annotation_dirs = ['genblast_output','stringtie_output','scallop_output']
  for annotation_dir in annotation_dirs:
    gtf_file = os.path.join(work_dir,annotation_dir,'annotation.gtf')
    if not os.path.exists(gtf_file):
      print("No annotation.gtf file found in " + annotation_dir + ", skipping")
      continue

    file_in = open(gtf_file)
    line = file_in.readline()
    while line:
      print(line.rstrip(),file=file_out)
      line = file_in.readline()
    file_in.close()
  file_out.close()

  pool = multiprocessing.Pool(int(num_threads))
  for seq_region_name in seq_region_names:
    pool.apply_async(multiprocess_finalise_geneset, args=(seq_region_name,merged_gtf,))

  pool.close()
  pool.join()


def multiprocess_finalise_geneset(seq_region_name,merged_gtf):

  output_dbname = ""
  output_server = "" 
  output_port = ""
  output_user = ""
  output_pass = ""

  dna_dbname = ""
  dna_server = ""
  dna_port = ""
  dna_user = ""

  finalise_cmd = ['perl','/homes/fergal/enscode/ensembl-common/scripts/process_transcriptomic_gtf.pl','-dbname',output_dbname,'-host',output_server,'-user',output_user,'-port',output_port,'-pass',output_pass,'-dna_dbname',dna_dbname,'-dna_host',dna_server,'-dna_user',dna_user,'-dna_port',dna_port,'-gtf_file',merged_gtf,'-specify_seq_region_name',seq_region_name]

  print('Finalising ' + seq_region_name)
  print(' '.join(finalise_cmd))
  subprocess.run(finalise_cmd)


def seq_region_names(genome_file):
  region_list = []

  file_in = open(genome_file)
  line = file_in.readline()
  while line:
    match = re.search(r'>([^\s]+)',line)
    if match:
      region_name = match.group(1)
      if region_name == "MT":
        print ("Skipping region named MT")
        line = file_in.readline()
        continue
      else:
        region_list.append(match.group(1))
    line = file_in.readline()

  return region_list


def slice_genome(genome_file,target_dir,target_slice_size):
  # The below is sort of tested
  # Without the 
  target_seq_length = 50000000
  min_seq_length = 1000
  current_header = ""
  current_seq = ""
  seq_dict = {}
  for line in seq:
    match = re.search(r'>(.+)$',line)
    if match and current_header:
      seq_dict[current_header] = current_seq
      current_seq = ""
      current_header = match.group(1)
    elif match:
      current_header = match.group(1)
    else:
      current_seq += line.rstrip()

  seq_dict[current_header] = current_seq

  seq_buffer = 0
  file_number = 0
  file_name = 'genome_file_' + str(file_number)

  for header in seq_dict:
    seq_iterator = 0
    seq = seq_dict[header]

    while len(seq) > target_seq_length:
      file_out = open(os.path.join(target_dir,file_name),"w+")
      subseq = seq[0:target_seq_length]
      file_out.write(">" + header + "_sli" + str(seq_iterator) + "\n" + subseq + "\n")
      file_out.close()
      seq = seq[target_seq_length:]
      seq_iterator += 1
      file_number += 1
      file_name = 'genome_file_' + str(file_number)

    if len(seq) >= min_seq_length:
      file_name = 'genome_file_' + str(file_number)
      file_out = open(os.path.join(file_name),"w+")
      file_out.write(">" + header + "_sli" + str(seq_iterator) + "\n" + seq + "\n")
      file_out.close()
      file_number += 1
      file_name = 'genome_file_' + str(file_number)
  
  
def create_paired_paths(fastq_file_paths):
  path_dict = {}
  final_list = []

  for path in fastq_file_paths:
    match = re.search(r'(.+)_\d+\.(fastq|fq)',path)
    if not match:
      print("Could not find _1 or _2 at the end of the prefix for file. Assuming file is not paired:")
      print(path)
      final_list.append([path])
      continue

    prefix = match.group(1)
    if prefix in path_dict:
#      path_dict[prefix] = path_dict[prefix] + ',' + path
      path_dict[prefix].append(path)
    else:
      path_dict[prefix] = [path]

  for pair in path_dict:
    final_list.append(path_dict[pair])

  return(final_list)


def check_exe(exe_path):

  if not shutil.which(exe_path):
    raise OSError('Exe does not exist. Path checked: %s' % exe_path)

  

if __name__ == '__main__':

  parser = argparse.ArgumentParser()
  parser.add_argument('--output_dir', help='Path where the output and temp files will write to. Uses current dir by default', required=False)
  parser.add_argument('--genome_file', help='Path to the fasta genome file', required=True)
  parser.add_argument('--num_threads', type=int, help='Number of threads to use', required=False)
  parser.add_argument('--run_masking', help='Run Red to find repeats and softmask the genome. Otherwise provide a softmasked genome', required=False)
  parser.add_argument('--red_path', help='Path to Red executable. See http://toolsmith.ens.utulsa.edu', required=False)
  parser.add_argument('--genblast_path', help='Path to GenBlast executable. See http://genome.sfu.ca/genblast/download.html', required=False)
  parser.add_argument('--convert2blastmask_path', help='Path to convert2blastmask executable', required=False)
  parser.add_argument('--makeblastdb_path', help='Path to makeblastdb executable', required=False)
  parser.add_argument('--run_genblast', help='Run GenBlast to align protein sequences', required=False)
  parser.add_argument('--protein_file', help='Path to a fasta file with protein sequences', required=False)
  parser.add_argument('--run_star', help='Run Star for short read alignment', required=False)
  parser.add_argument('--star_path', help='Path to Star for short read alignment', required=False)
  parser.add_argument('--max_reads_per_sample', nargs='?', const=0, type=int, help='The maximum number of reads to use per sample. Default=0 (unlimited)', required=False)
  parser.add_argument('--max_total_reads', nargs='?', const=0, type=int, help='The maximum total number of reads. Default=0 (unlimited)', required=False)
  parser.add_argument('--short_read_fastq_dir', help='Path to short read fastq dir for running with Star', required=False)
  parser.add_argument('--run_minimap2', help='Run minimap2 for long read alignment', required=False)
  parser.add_argument('--minimap2_path', help='Path to minimap2 for long read alignment', required=False)
  parser.add_argument('--paftools_path', help='Path to paftools for SAM to BED conversion', required=False)
  parser.add_argument('--long_read_fastq_dir', help='Path to long read fastq dir for running with minimap2', required=False)
  parser.add_argument('--run_augustus', help='Run Augustus with hints for gene/transcript prediction', required=False)
  parser.add_argument('--augustus_path', help='Path to Augustus', required=False)
  parser.add_argument('--run_cufflinks', help='Run Cufflinks on the results from the STAR alignments', required=False)
  parser.add_argument('--cufflinks_path', help='Path to Cufflinks', required=False)
  parser.add_argument('--cuffmerge_path', help='Path to Cuffmerge', required=False)
  parser.add_argument('--run_stringtie', help='Run Stringtie on the results from the STAR alignments', required=False)
  parser.add_argument('--run_scallop', help='Run Scallop on the results from the STAR alignments', required=False)
  parser.add_argument('--stringtie_path', help='Path to Stringtie', required=False)
  parser.add_argument('--scallop_path', help='Path to Scallop', required=False)
  parser.add_argument('--subsample_script_path', help='Path to gbiab subsampling script', required=False)
  parser.add_argument('--samtools_path', help='Path to subsampling script', required=False)
  parser.add_argument('--finalise_geneset', help='Used to finalise the gene set from the various GTF files generated', required=False)

  args = parser.parse_args()

  work_dir = args.output_dir
  genome_file = args.genome_file
  num_threads = args.num_threads
  masked_genome_file = genome_file # This will be updated later if Red is run
  run_masking = args.run_masking
  red_path = args.red_path
  genblast_path = args.genblast_path
  convert2blastmask_path = args.convert2blastmask_path
  makeblastdb_path = args.makeblastdb_path
  run_genblast = args.run_genblast
  protein_file = args.protein_file
  run_star = args.run_star
  star_path = args.star_path
  short_read_fastq_dir = args.short_read_fastq_dir
  max_reads_per_sample = args.max_reads_per_sample
  max_total_reads = args.max_total_reads
  run_minimap2 = args.run_minimap2
  minimap2_path = args.minimap2_path
  paftools_path = args.paftools_path
  long_read_fastq_dir = args.long_read_fastq_dir
  run_augustus = args.run_augustus
  augustus_path = args.augustus_path
  run_cufflinks = args.run_cufflinks
  cufflinks_path = args.cufflinks_path
  cuffmerge_path = args.cuffmerge_path
  run_stringtie = args.run_stringtie
  run_scallop = args.run_scallop
  stringtie_path = args.stringtie_path
  scallop_path = args.scallop_path
  subsample_script_path = args.subsample_script_path
  samtools_path = args.samtools_path
  finalise_geneset = args.finalise_geneset

  if not os.path.exists(genome_file):
    raise IOError('File does not exist: %s' % genome_file)

  if not work_dir:
    work_dir = os.getcwd()
  
  print ('Work dir is: %s' % work_dir)

  if not os.path.exists(work_dir):
    print ("Work dir does not exist, will create")
    create_dir(work_dir)

  if not num_threads:
    print ("No thread count specified, so defaulting to 1. This might be slow")
    num_threads = 1

  # Collect a list of seq region names, most useful for multiprocessing regions
  seq_region_names = seq_region_names(genome_file)  
  for i in seq_region_names:
    print(i)

  # Run masking
  if run_masking:
    print ("Running masking via Red")
    masked_genome_file = run_red(red_path,work_dir,genome_file)
    print ("Masked genome file: " + masked_genome_file)

  else:
    print ("Not running masking a presuming the genome file is softmasked")

  # Run GenBlast
  if run_genblast:
    print ("Running GenBlast")
    run_genblast_align(genblast_path,convert2blastmask_path,makeblastdb_path,work_dir,protein_file,masked_genome_file,num_threads)

  # Run STAR
  if run_star:
     print ("Running Star")
     run_star_align(star_path,subsample_script_path,work_dir,short_read_fastq_dir,genome_file,max_reads_per_sample,max_total_reads,num_threads)

  # Run minimap2
  if run_minimap2:
     print ("Running minimap2")
     run_minimap2_align(minimap2_path,paftools_path,work_dir,long_read_fastq_dir,genome_file,num_threads)

  # Run Augustus
  if run_augustus:
     print ("Running Augustus")
     run_augustus_predict(augustus_path,work_dir,genome_file,num_threads)

  # Run Stringtie
  if run_stringtie:
     print ("Running Stringtie")
     run_stringtie_assemble(stringtie_path,samtools_path,work_dir,genome_file,num_threads)

  # Run Scallop
  if run_scallop:
     print ("Running Scallop")
     run_scallop_assemble(scallop_path,stringtie_path,work_dir)

  # Run Cufflinks
  if run_cufflinks:
     print ("Running Cufflinks")
     run_cufflinks_assemble(cufflinks_path,cuffmerge_path,samtools_path,work_dir,genome_file,num_threads)

  # Do some magic
  if finalise_geneset:
     print("Finalise geneset")
     run_finalise_geneset(work_dir,genome_file,seq_region_names,num_threads)