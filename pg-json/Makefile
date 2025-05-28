
gen-sample:
	@cat sample.json | sed \
		-e "s/\"/'/g" -e 's/: /, /g' \
		-e 's/{/jsonb_build_object(/g' \
		-e 's/}/\)/g' \
		-e 's/\[/jsonb_build_array(/g' \
		-e 's/\]/)/g'
