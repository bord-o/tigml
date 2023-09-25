# tigml
An implementation of Modern Compiler Implementation in ML's Tiger language in ocaml

I tried to stick with SML, as I think it is a fine language, but the tooling and interoperability between Mlton and SML/NJ, and the book's dependence on SML/NJ compiler extensions made me very angry.

Still trying to decide what I should target for the backend...

## Building

- Run:
  - opam install --deps-only .
  - make

- Tests:
  - make runtest

