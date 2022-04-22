local vector = {}

---@class pos3d
---@field x number
---@field y number
---@field z number

--- Square length of  pos3d.
---@param vec pos3d
function vector.sqrLen3d(vec)
    return vec.x * vec.x + vec.y * vec.y + vec.z * vec.z
end

--- Length of pos3d.
---@param vec pos3d
function vector.len3d(vec)
    return math.sqrt(vector.sqrLen3d(vec))
end

return vector