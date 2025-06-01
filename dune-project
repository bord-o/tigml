(lang dune 3.19)

(name tigml)

(generate_opam_files true)

(source
 (github bord-o/tigml))

(authors "Brody Little")

(license LICENSE)

(using menhir 2.1)

(package
 (name tigml)
 (synopsis "Implementation of Appel's compiler in OCaml")
 (depends ocaml dune))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/dune-files.html#dune-project
