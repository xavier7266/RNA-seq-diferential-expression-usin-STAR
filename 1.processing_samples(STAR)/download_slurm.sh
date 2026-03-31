#!/bin/bash

#SBATCH -J download
#SBATCH -o download_%j.out
#SBATCH -e download_%j.err
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH -t 12:00:00

set -uo pipefail

wget
wget
wget
wget
wget
wget
wget
wget
wget


