run:
	dune exec tigml --profile=release
all:	
	dune build . --profile=release
clean:
	dune clean
fmt:
	dune fmt