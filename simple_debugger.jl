module simple_debugger
using MLStyle
using Crayons
using PrettyPrinting
using ReplMaker
using REPL

export @debug!, @nodebug!, @watch!, @report, @watch_locals!, @inject

DebugScope = Dict{String, Tuple{LineNumberNode, Any}}

mutable struct MetaData
    current_line :: LineNumberNode
    to_watch     :: DebugScope
    committed    :: Vector{DebugScope}
    debug        :: Bool
end

const line = LineNumberNode(32, :fake_line)
const empty_dbg_scope = DebugScope()
const meta = MetaData(line, empty_dbg_scope, [], false)

Base.show(io::IO, ::MetaData) = print(io, "meta")


macro debug!()
    meta.debug = true
end

macro nodebug!()
    meta.debug = false
end

function commit!(meta)
    push!(meta.committed, meta.to_watch)
end

function rollback!(meta)
    meta.to_watch = pop!(meta.committed)
end

function watch!(meta, name, var, line)
    meta.to_watch[name] = (line, var)
    var
end

const fake_exps    = Expr[]
const dbg_scoperef = Ref{Vector{Expr}}(fake_exps)

function parse_expr(s)
    ex = Meta.parse(s)
    let_bindings = dbg_scoperef.x
    :(let $(let_bindings...); $ex end)
end

const dbg_repl = Base.active_repl

dbg_mode = initrepl(
    parse_expr,
    prompt_text="dbg> ",
    prompt_color = :green,
    start_key="|",
    repl = dbg_repl,
    mode_name="debug_mode"
)

function report(meta, msg)
    bold = Crayon(bold=true)
    style_title = Crayon(foreground=:light_magenta)
    style_line = Crayon(foreground=:green, italics=true, underline=true)
    style_var = Crayon(foreground=:light_blue, bold=true)
    println(args...) = begin
        Base.print(args...)
        Base.print(Crayon(reset=true), "\n")
    end
    println(style_title, "Debugging ", bold, msg)
    println(style_line, "[where] ", meta.current_line)

    for (k, (line, v)) in meta.to_watch
        print(style_var, "  ", k, " ", style_line, bold, "[", line, "]:", Crayon(reset=true))
        pprint(v)
        println()
    end
    print(style_title, "Open a REPL here and check manually?[Y/N]")
    option = stdin |> readline |> strip |> lowercase |> Symbol
    @match option begin
        :n => ()
        :y =>
            begin
                dbg_scoperef.x = map(meta.to_watch |> collect) do (k, (line, v))
                    sym = Symbol(k)
                    :($sym = $v)
                end
                println(
                    style_var,
                    "Press | and switch to dbg-mode, enter Ctrl+D to leave sub-REPL."
                )
                REPL.run_repl(dbg_repl)
            end
        _ => throw(error("invalid option $option"))
    end
    nothing
end

function inject_func(msg, expr, meta)
    quote
        $commit!($meta)
        $meta.to_watch = $DebugScope()
        try
            $(inject(expr, meta))
        finally
            if $meta.debug && $(!isempty)($meta.to_watch)
                $report($meta, $msg)
            end
            $rollback!($meta)
        end
    end
end

is_call(ex) =
    @match ex begin
        Expr(:call, _...) => true
        :($a :: $_)       => is_call(a)
        :($a where $_)    => is_call(a)
        _                 => false
    end

function inject(expr, meta)
    rec(ex) = inject(ex, meta)

    @match expr begin
        Expr(:(=), func_head, body) && if is_call(func_head) end ||
        Expr(:function || :(->), func_head, body) =>
            let body = inject_func(string(func_head), body, meta)
                Expr(:function, func_head, body)
            end

        line::LineNumberNode =>
            Expr(:block, line, :($meta.current_line = $(QuoteNode(line))))

        :(@report $line) =>
            quote
                if $meta.debug && $(!isempty)($meta.to_watch)
                    $report($meta, $msg)
                end
            end

        :(@watch_locals! $(_...)) =>
            quote
                for (k, v) in $Base.@locals
                    $watch!($meta, $string(k), v, $(QuoteNode(line)))
                end
            end

        :(@watch! $line $var) || :(@watch $var) =>
            let name = string(var)
                :($watch!($meta, $name, $var, $(QuoteNode(line))))
            end

        Expr(hd, tl...) =>
            Expr(hd, map(rec, tl)...)

        a => a
    end
end

macro watch!()
    throw(error("only used as tokens of @inject"))
end

macro report!()
    throw(error("only used as tokens of @inject"))
end

macro watch_locals!()
    throw(error("only used as tokens of @inject"))
end

macro inject(ex)
    inject(ex, meta) |> esc
end

end
