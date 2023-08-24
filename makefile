run:
	dune exec tigml --profile=release
build:	
	dune build . --profile=release
clean:
	dune clean
fmt:
	dune fmt