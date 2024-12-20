#!/bin/bash

# Usage: ./run_admixture.sh path/to/file.vcf.gz
# This script processes a VCF file and runs admixture for K=2,3,4,5.

# Input Validation
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <path_to_vcf_file>"
    exit 1
fi

# Input VCF file
VCF_FILE=$1

# Extract file name without path and extension
FILE_PREFIX=$(basename "$VCF_FILE" .vcf.gz)

# Ensure the VCF file exists
if [ ! -f "$VCF_FILE" ]; then
    echo "Error: File $VCF_FILE does not exist."
    exit 1
fi

# Source conda for the script
source $(conda info --base)/etc/profile.d/conda.sh

# Step 1: Activate plink environment
echo "Activating plink environment..."
conda activate /home/snaumenko/UAgenomes/plink

# Step 2: Convert VCF to PLINK binary format
echo "Running PLINK: converting VCF to binary format..."
plink --vcf "$VCF_FILE" --make-bed --out "$FILE_PREFIX" --allow-extra-chr

# Step 3: Filter SNPs with missing genotype rate > 10%
echo "Filtering SNPs with >10% missing genotypes..."
plink --bfile "$FILE_PREFIX" --geno 0.1 --make-bed --out "${FILE_PREFIX}_filtered"

# Step 4: Filter individuals with >10% missing data
echo "Filtering individuals with >10% missing data..."
plink --bfile "${FILE_PREFIX}_filtered" --mind 0.1 --make-bed --out "${FILE_PREFIX}_filtered2"

# Step 5: Fix chromosome IDs in the .bim file
echo "Fixing chromosome IDs in .bim file..."
awk '{$1="0"; print $0}' "${FILE_PREFIX}_filtered2.bim" > "${FILE_PREFIX}_filtered2.bim.tmp"
mv "${FILE_PREFIX}_filtered2.bim.tmp" "${FILE_PREFIX}_filtered2.bim"

# Step 6: Activate admixture environment
echo "Activating admixture environment..."
conda activate admixture-env

# Step 7: Run admixture for K=2,3,4,5
echo "Running admixture..."
for K in 5; do
    echo "Running admixture for K=$K..."
    admixture --cv "${FILE_PREFIX}_filtered2.bed" $K > "log${K}.out"
    echo "Admixture for K=$K completed. Check log${K}.out for details."
done

echo "All steps completed successfully!"
