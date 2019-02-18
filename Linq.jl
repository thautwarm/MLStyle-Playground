using MLStyle

module Linq
    map(arr, f) = Base.map(f, arr)

    filter(arr, f) = Base.filter(f, arr)

    collect(arr) = Base.collect(arr)

    collect(arr, ::Type{T}) where T = Base.collect(T, arr)

    flat_map(arr, f) = Base.vcat(Base.map(f, arr)...)

    skip(arr) = Base.view(arr, 2:Base.length(arr))

    skip(arr, n) = Base.view(arr, n:Base.length(arr))

    len(arr) = Base.length(arr)

    drop(arr, n) = Base.view(arr, 1:(Base.length(arr) - n))

    sum(arr, f) = Base.sum(Base.map(f, arr))

    group_by(arr, f) = begin
        result = OrderedDict()
        for elt in arr
            push!(get!(result, f(elt)) do
                    []
                  end,
                  elt)

        end
        result
    end

    group_by(arr) = begin
        result = OrderedDict()
        for elt in arr
            push!(get!(result, elt) do
                    []
                  end,
                  elt)

        end
        result
    end

    any(arr, f) = Base.any(f, arr)
    any(arr) = Base.any(arr)

    all(arr, f) = Base.all(f, arr)
    all(arr) = Base.all(arr)

    enum(arr) = enumerate(arr)

    foldl(arr, f) = Base.foldl(f, arr)
    foldl(arr, f, init) = Base.foldl(f, arr, init=init)
    foldr(arr, f) = Base.foldr(f, arr)
    foldr(arr, f, init) = Base.foldr(f, arr, init=init)
    sort(arr) = Base.sort(arr)
    sort(arr, f) = Base.sort(arr, by=f)

    export dispatch
    """
    You can implement your own extension methods with this.
    
    e.g.
    import Linq: dispatch

    function dispatch(Val{:expected}, subject::Vector{T}) where T
        view(subject, 1:2:length(subject))
    end
    
    @assert [1, 3] == @linq [1, 2, 3, 4].expected
    """
    function dispatch
    end

end

function linq(expr)
    @match expr begin
        :($subject.$method($(args...))) =>
            let subject = linq(subject)
                if isdefined(Linq, method)
                    let method = getfield(Linq, method)
                        :($method($subject, $(args...)))
                    end
                else
                    let method = Val(method)
                        :($(Linq.dispatch)($method, $subject, $(args...)))
                    end
                end
            end
        :($subject.$method) =>
            let subject = linq(subject)
                if isdefined(Linq, method)
                    let method = getfield(Linq, method)
                        :($method($subject))
                    end
                else
                    let method = Val(method)
                        :($(Linq.dispatch)($method, $subject))
                    end
                end
            end
        _ => expr
    end
end

macro linq(expr)
    esc(linq(expr))
end

import .Linq: dispatch

dispatch(::Val{:str}, arr :: Vector{T}) where T = string(arr)

dispatch(::Val{:println}, s :: String) where T = println(s)

@linq [1, 2, 3].map(x -> 2x).str.println

