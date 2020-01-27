module Util

"""
create annotations for any struct
"""
macro namedargs(StructDec)
  sstruct = string(StructDec)
  typename = sstruct[findfirst(r"(?<=struct).*(?=\n)", sstruct)]
  typename = strip(typename)
  parametric = findfirst(r"{.*}", typename)
  if parametric == nothing
    parametric = ""
  else
    parametric = "where $(typename[parametric])"
  end
  typename = typename[findfirst(r"\w+", typename)]

  function fieldNameAndType(expr)
    return split(string(expr), "::")
  end

  args = StructDec.args[3].args[2:2:end]
  args = filter(a -> !occursin(r"new\(+", string(a)), args)
  args = map(a -> fieldNameAndType(a), args)
  fnames = [a[1] for a in args]
  ftypes = [a[2] for a in args]

  callArgs = join(["$(a[1])" for a in args], ", ")
  oldConstructorCall = "$typename($callArgs)"

  fn_args = join(["$(a[1])::$(a[2])" for a in args], ", ")
  namedArgsConstructor = "$typename(; $fn_args) $parametric"

  return quote
    $(esc(StructDec))
    $(esc(Meta.parse("$namedArgsConstructor = $oldConstructorCall")))
  end
end

end # module Util
