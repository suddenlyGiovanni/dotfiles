# Defined in - @ line 1
function l --wraps='exa -lahF' --description 'alias l=exa -lahF'
  exa -lahF $argv;
end
