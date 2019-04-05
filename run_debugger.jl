include("simple_debugger.jl")
module DbgNamespace end
@debug module A
    function f(x)
        !x
    end
end DbgNamespace

A.f(1)
