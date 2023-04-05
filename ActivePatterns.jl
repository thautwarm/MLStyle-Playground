using MLStyle


@active Re{r :: Regex}(x) begin
    let temp = match(r, x); ifelse(temp === nothing, temp, Some(temp)) end
end


match_numbers = @λ begin
    Re{r"\G\d+"}(_) -> true
    _ -> false
end

@assert match_numbers("12345  ")
@assert !match_numbers("   12345")

struct RGB
    R :: Int
    G :: Int
    B :: Int
end

red = RGB(220, 20, 60)

green = RGB(0, 150, 50)


@active Red(x) begin
    @match (x.R, x.G, x.B) begin
	(118:138, 0:10, 0:10) => Some(:maroon)
	(129:149, 0:10, 0:10) => Some(:dark_red)
	(210:230, 10:30, 50:70) => Some(:crimson)
	(155:175, 32:52, 32:52) => Some(:brown)
	(100:255, 0:110, 0:110) => Some(:unknown)
        _ => nothing
    end
end

@active Green(x) begin
    @match (x.R, x.G, x.B) begin
	(0:10, 90:110, 0:10) => Some(:dark_green)
	(0:10, 118:138, 0:10) => Some(:green)
	(24:44, 129:149, 24:44) => Some(:forest_green)
	(0:100, 100:255, 0:100) => Some(:unknown)
        _ => nothing
    end
end

macro f(x) println(macroexpand(Main, x)) end
@assert @match red begin
        Red(x) => (println(x); true)
        x => (show(x); false)
end

@assert @match green begin
    Green(x) => (println(x); true)
    _ => false
end

