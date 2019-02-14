FROM ocaml/opam2:ubuntu
RUN opam remote remove default --all
RUN opam remote add default https://opam.ocaml.org --all
RUN opam update
RUN sudo apt-get update
RUN sudo apt-get install -y m4 cmake ninja-build stow
