

# Your elm project root must be a git repository.  This is just an example.
ELM_PROJECT_ROOT=/home/laing/my/github/debois/elm-mdl

compilerUi:
	python build-graph.py $(ELM_PROJECT_ROOT)
	cat CompilerPreamble.elm .ReducedDigraph.elm > CompilerUI.elm
	elm-make CompilerUI.elm


sim:
	python build-graph.py $(ELM_PROJECT_ROOT)
	cat SimulatorPreamble.elm .ReducedDigraph.elm > Simulator.elm
	elm-make Simulator.elm
