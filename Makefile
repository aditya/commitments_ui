
serve: refresh
	python -m SimpleHTTPServer 4444

refresh:
	git submodule init
	git submodule update

