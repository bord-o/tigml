run:
	dune exec tigml --profile=release
build:	
	dune build . --profile=release
clean:
	dune clean
runtest:
	dune test --force --profile=release
fmt:
	dune fmt