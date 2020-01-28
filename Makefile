SHELL = /bin/bash

.PHONY: all reproduce getcbdata

### Make variables
cb_transformed_data_url = https://raw.githubusercontent.com/luiarthur/cytof-data/master/data/cb/cb_transformed.csv

path_to_cb_data = runs/data/cb_transformed.csv

### Make commands ###
all: reproduce

# Reproduce results (figures, files, etc.)
reproduce: getcbdata
	@echo 'TODO'

# Download transformed CB data.
# For data info, see: https://github.com/luiarthur/cytof-data
getcbdata: $(path_to_cb_data)

$(path_to_cb_data):
	wget $(cb_transformed_data_url) -O $(path_to_cb_data)
