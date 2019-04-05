using MLStyle

function setup_dbg(expr, line)
    quote
        __dbg_curline__ = $(QuoteNode(line))
        __dbg_cursource__ = $(string(expr))
        $expr
    end
end

function debug(expr, line, debug_mod)
    @match expr begin
        Expr(:function, others..., Expr(:block, elts...)) => begin
            lastline = line
            new_elts = map(elts) do each
                @match each begin
                    l :: LineNumberNode =>
                        begin
                            lastline = l
                            l
                        end
                    a => begin
                        debug(a, lastline, debug_mod)
                    end
                end
            end

            body = quote
                __dbg_curline__ = $(QuoteNode(line))
                __dbg_cursource__ = $(string(Expr(:function, others..., Expr(:block, ))))
                __dbg_local__ = $Base.@locals
                try
                    $(new_elts...)
                catch __dbg_err__
                    $debug_mod.eval(quote
                        scope = $__dbg_local__
                    end)
                    $push!($debug_mod.locs, (__dbg_curline__, __dbg_cursource__))
                    println()
                    @info :error __dbg_err__
                    println()
                    println("locs: traceback locations; scope: current local scope")
                    try
                        while (print("> "); __dbg_sh_input__ = $readline(); $lowercase($strip(__dbg_sh_input__)) != "q")
                            try
                                __dbg_ans__ = $debug_mod.eval($Meta.parse(__dbg_sh_input__))
                                $debug_mod.eval(:(ans = $__dbg_ans__))
                                __dbg_ans_str__ = "  " * string(__dbg_ans__)
                                println(__dbg_ans_str__)
                            catch __dbg_sh_err__
                                @info :error __dbg_sh_err__
                            end
                        end
                    finally
                        $pop!($debug_mod.locs)
                    end
                    $rethrow(__dbg_err__)
                end
            end

            Expr(:function, others..., body)
        end
        Expr(:module && head, a, b, elts...) =>
        let lastline = line,
            elts = map(elts) do each
                if each isa LineNumberNode
                    lastline = each
                end
                debug(each, lastline, debug_mod)
            end
            Expr(head, a, b, elts...)
        end
        Expr(head, elts...) =>
            let lastline = line,
                ex = map(elts) do each
                    if each isa LineNumberNode
                        lastline = each
                    end
                debug(each, lastline, debug_mod)
                end |> elts -> Expr(head, elts...)

                head == :call ?
                let var = gensym()
                    quote
                        $push!($debug_mod.locs, ($(QuoteNode(line)), $(string(expr))))
                        $var = $ex
                        $pop!($debug_mod.locs)
                        $var
                    end
                end : ex
            end
        a => setup_dbg(a, line)
    end
end


macro debug(expr, debug_mod)
    debug_mod = eval(debug_mod)
    if !isdefined(debug_mod, :locs)
        debug_mod.eval(:(locs = []))
    end
    ex = debug(expr, __source__, debug_mod)
    esc(ex)
end

# module Debugger
# end

# @debug function f(z)
#         !z
# end Debugger

# f(1)
