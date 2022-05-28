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

function vector2.randomPointInCircle(pos, radius)
	local r = (radius or 1) * math.sqrt(math.random())
	local theta = math.random() * 2 * math.pi
	return {
		pos[1] + r * math.cos(theta),
		pos[2] + r * math.sin(theta)
	}
end

function vector2.randomPointInEllipse(pos, size)
	local r = math.sqrt(math.random())
	local theta = math.random() * 2 * math.pi
	return {
		pos[1] + size[1] * r * math.cos(theta),
		pos[2] + size[2] * r * math.sin(theta)
	}
end

function vector2.randomPointInBox(pos, size)
	return vector2.add(pos, vector2.mul(size, {math.random(), math.random()}))
end

return vector2
