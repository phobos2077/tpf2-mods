local math_ex = {}

function math_ex.clamp(value, min, max)
    return math.max(math.min(value, max), min)
end

return math_ex