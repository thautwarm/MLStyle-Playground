using MLStyle

function refblock(expr, refs::Dict{Symbol, Symbol})
    rec(x) = refblock(x, refs)
    @match expr begin
        a && (
                # 函数定义，开启新的scope
                Expr(:function, _...) ||
                Expr(:->, _...)       ||
                Expr(:(=), Expr(:call, _...), _...)
        ) => refblock(a, Dict{Symbol, Symbol}())
        :($a = &$b) =>
            begin
                refs[a] = b
                nothing
            end

        a::Symbol && if haskey(refs, a) end => refs[a]
        Expr(hd, tl...) => Expr(hd, map(rec, tl)...)

        a => a
    end
end
macro refblock(expr)
    refblock(expr, Dict{Symbol, Symbol}()) |> esc
end


function myf(x)
    @refblock begin
        a = &x
        a = a + 1
        println(x)
    end
end
myf(1)