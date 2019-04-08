# MLStyle Playground

## Simple Debugger

```julia
include("simple_debugger.jl")
module DbgNamespace end
@debug module A
    function f(x)
        !x
    end
end DbgNamespace

A.f(1)
```

Above codes allow you to start a simple debugger shell when
an unexpected exception occurred.

```
┌ Info: error
│   __dbg_err__ =
│    MethodError: no method matching !(::Int64)
│    Closest candidates are:
│      !(!Matched::Missing) at missing.jl:83
│      !(!Matched::Bool) at bool.jl:35
└      !(!Matched::Function) at operators.jl:853

locs: traceback locations; scope: current local scope
> 1
  1
> scope
  Dict{Symbol,Any}(:__dbg_curline__=>:(#= /MLStyle-Playground/run_debugger.jl:4 =#),:__dbg_cursource__=>"function f(x)\nend",:x=>1)
> locs
  Any[(:(#= /MLStyle-Playground/run_debugger.jl:5 =#), "!x"), (:(#= /MLStyle-Playground/run_debugger.jl:5 =#), "x")]
> locs[end]
  (:(#= /MLStyle-Playground/run_debugger.jl:5 =#), "x")
> x = 1
  1
> x = scope
  Dict{Symbol,Any}(:__dbg_curline__=>:(#= /MLStyle-Playground/run_debugger.jl:4 =#),:__dbg_cursource__=>"function f(x)\nend",:x=>1)
> q
ERROR: LoadError: MethodError: no method matching !(::Int64)
Closest candidates are:
  !(!Matched::Missing) at missing.jl:83
  !(!Matched::Bool) at bool.jl:35
  !(!Matched::Function) at operators.jl:853
Stacktrace:
 [1] f(::Int64) at /MLStyle-Playground/simple_debugger.jl:7
 [2] top-level scope at none:0
 [3] include at ./boot.jl:326 [inlined]
 [4] include_relative(::Module, ::String) at ./loading.jl:1038
 [5] include(::Module, ::String) at ./sysimg.jl:29
 [6] exec_options(::Base.JLOptions) at ./client.jl:267
 [7] _start() at ./client.jl:436
in expression starting at /MLStyle-Playground/run_debugger.jl:9
```

## Julia Is A Lisp Idiom

```julia
include("lisp.jl")
@info @lisp [
   :block
   [:function [f x] [(+) x 1]]
   [f 2]
]
```
produces
```julia
[ Info: 3
```

Also,
```julia
julia> @lisp [:(=) [f a b] [(+) 2a b]]
f (generic function with 1 method)

julia> @lisp [f 1 2]
4
```

## Syntax Extension Prototype

```julia
include("allow_patterns.jl")
    @allow_patterns module SyntaxExtended
        case(1) do
            2        => error(1)
            5:10     => error(2)
            1:4 && a =>
            case(a + 1) do
                a => 5a
            end
        end |> println
    end
```
produces
```julia
10
Main.SyntaxExtended
```

## Statically Capturing

This is similar to `@capture` in MacroTools.jl but much more powerful and efficient.

```julia

@info @capture f($x) :(f(1))
# Dict(:x=>1)

destruct_fn = @capture function $(fname :: Symbol)(a, $(args...)) $(body...) end

@info destruct_fn(:(
    function f(a, x, y, z)
        x + y + z
    end
))

# Dict{Symbol,Any}(
#     :args => Any[:x, :y, :z],
#     :body=> Any[:(#= StaticallyCapturing.jl:93 =#), :(x + y + z)],
#    :fname=>:f
# )

```

## MQuery

The codes of [Write You A Query Language](https://github.com/thautwarm/MLStyle.jl/blob/tutorial-MQuery/docs/src/tutorials/query-lang.md).

Not like other similar implementations, `MQuery.jl` just depends on fewer packages like `DataStructures.jl` and `MLStyle.jl`.

```julia
include("MQuery/MQuery.jl")
using Base.Enums
@enum TypeChecking Dynamic Static
df = DataFrame(
        Symbol("Type checking") => [
            Dynamic, Static, Static, Dynamic, Static, Dynamic, Dynamic, Static
        ],
        :name => [
            "Julia", "C#", "F#", "Ruby", "Java", "JavaScript", "Python", "Haskell"
        ],
        :year => [
            2012, 2000, 2005, 1995, 1995, 1995, 1990, 1990
        ]
)

df |>
@where !startswith(_.name, "Java"),
@groupby _."Type checking" => TC, endswith(_.name, "#") => is_sharp,
@having TC === Dynamic || is_sharp,
@select join(_.name, " and ") => result, _.TC => TC

# 2×2 DataFrame
# │ Row │ result                    │ TC        │
# │     │ String                    │ TypeChec… │
# ├─────┼───────────────────────────┼───────────┤
# │ 1   │ Julia and Ruby and Python │ Dynamic   │
# │ 2   │ C# and F#                 │ Static    │
```

## Linq

Check [Linq.jl](./Linq.jl).

```julia

import .Linq: dispatch

dispatch(::Val{:str}, arr :: Vector{T}) where T = string(arr)

dispatch(::Val{:println}, s :: String) where T = println(s)

@linq [1, 2, 3].map(x -> 2x).str.println

# [2, 4, 6]
```

## Cond

Check [Cond.jl](./Cond.jl)

```julia
@cond begin
    x == 1         => :case1
    x < 2 && x > 3 => :case2
    _              => :case3
end
```

## ActivePatterns

Active Patterns can help you with making custom patterns.

```julia

red = RGB(220, 20, 60)
@match red begin
    Green(which_green) => throw("red is taken as $which_green")
    Red(which_red) => which_red
    _ => throw("red is not recognized!")
end

```
