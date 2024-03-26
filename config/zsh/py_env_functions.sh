activate_python() {
  . bin/activate-hermit
  source .venv/bin/activate
}

alias pyact='activate_python'

pyinit() {
  hermit init . 
  python -m venv .venv
  pyact
}
