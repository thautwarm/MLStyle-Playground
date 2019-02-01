
# MLStyle Playground

Check the implementations of some popular constructs from other languages.

## Linq

Check [Linq.jl](./Linq.jl).

```julia

import .Linq: dispatch

dispatch(arr :: Vector{T}, ::Val{:str}) where T = string(arr)

dispatch(s :: String, ::Val{:println}) where T = println(s)

@linq [1, 2, 3].map(x -> 2x).str.println

# [2, 4, 6]
```

## Cond

Check [Cond.jl](./Cond.jl)

```julia

@cond begin
    <cond1> => <body1>
    ...
    _ => <default body> 
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