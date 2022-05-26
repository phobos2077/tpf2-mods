local vector2 = { }

function vector2.add(a, b)
	return { a[1] + b[1], a[2] + b[2] }
end

function vector2.sub(a, b)
	return { a[1] - b[1], a[2] - b[2] }
end

function vector2.mul(a, b)
	if type(b) == "number" then
		return { a[1] * b, a[2] * b }
	else
		return { a[1] * b[1], a[2] * b[2]}
	end
end

function vector2.len(v)
	return math.sqrt(v[1] * v[1] + v[2] * v[2])
end

function vector2.distance(a, b)
	return vector2.len(vector2.sub(a, b))
end

function vector2.dot(a, b)
	return a[1] * b[1] + a[2] * b[2]
end

return vector2
