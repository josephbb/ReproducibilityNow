# Run from the project root after: nix develop && renv::restore()

library(tidyverse)
library(here)
library(yaml)

config <- read_yaml(here("analysis", "analysis_config.yaml"))
set.seed(config$seed)

dataset_one <- read_csv(here(config$paths$dataset_one), show_col_types = FALSE)

dataset_one
