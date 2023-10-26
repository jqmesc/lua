local Network = require(game.ServerScriptService.Network)

local Connect4 = game.Workspace:FindFirstChild('Connect4',true)
local Pieces = Connect4:WaitForChild('Pieces')
local Board = {turn=1;Enabled=false}

local MAX_ROWS = 7
local MAX_COLS = 6

local _red = Color3.fromRGB(255,0,0)
local _yellow = Color3.fromRGB(255,255,0)
local _white = Color3.fromRGB(248,248,248)
function Board:Initialize()
	for _,_piece in next,Pieces:GetChildren() do
		local _,_,row,col = string.find(_piece.Name,'(%d)_(%d)')
		local p = Instance.new('ClickDetector',_piece)
		p.MouseClick:Connect(function()
			Board:Place(tonumber(row),tonumber(col))
		end)
		p.MouseHoverEnter:Connect(function()
			local _turn = Board.turn % 2
			local _color = _turn == 1 and _red or _yellow
			local _example = Connect4:FindFirstChild('Example_'..row)
			_example.Transparency = 0.5
			_example.Color = _color
		end)
		p.MouseHoverLeave:Connect(function()
			local _turn = Board.turn % 2
			local _color = _turn == 1 and _red or _yellow
			local _example = Connect4:FindFirstChild('Example_'..row)
			_example.Transparency = 1
			_example.Color = _white
		end)
	end
	
	Board:Reset()
	warn('[Server]: Connect 4 Initialized')
end

function Board:Reset()
	for _,_piece in next,Pieces:GetChildren() do
		_piece.Transparency = 1
		_piece.Color = _white
	end
	for i = 0,MAX_ROWS-1 do -- Create 7x6 array to store pieces
		Board[i] = {}
		for j = 0,MAX_COLS-1 do
			Board[i][j] = ''
		end
	end
	Board.turn = 1
	Board.Enabled = true
end

function Board:Place(row,col)
	if not Board.Enabled then
		return
	end
	local _turn = Board.turn % 2
	local _color = _turn == 1 and _red or _yellow
	
	for i = MAX_COLS-1,0,-1 do
		--print('Board['..tostring(row)..']['..tostring(i)..']',Board[row][i])
		if Board[row][i] == '' then
			local _piece = Pieces:FindFirstChild('Piece'..row..'_'..i)
			Board[row][i] = _turn
			_piece.Transparency = 0
			_piece.Color = _color 
			if Board:CheckWin() then
				Board.Enabled = false
			else
				Board.turn += 1
			end
			for i,v in next,Connect4:GetChildren() do
				if string.find(v.Name,'%d') then
					v.Color = v.Color == _red and _yellow or _red
				end
			end
			return
		end
	end
	--print('Invalid placement')
end

function Board:CheckWin()
	local _turn = Board.turn % 2
	local _color = _turn == 1 and _red or _yellow
	-- Horizontal
	for row = 0,MAX_ROWS-4,1 do
		for col = 0,MAX_COLS-1,1 do
			local _test = ''
			for i = row,row+3 do
				_test = _test..Board[i][col]
			end
			if _test == '0000' or _test == '1111' then
				for _,_piece in next,Pieces:GetChildren() do
					if _piece.Transparency == 0 then
						_piece.Transparency = 0.6
					end
				end
				for i = row,row+3 do
					local _piece = Pieces:FindFirstChild('Piece'..i..'_'..col)
					_piece.Color = _color
					_piece.Transparency = 0
				end
				return true
			end
		end
	end
	-- Vertical
	for col = 0,MAX_COLS-4,1 do
		for row = 0,MAX_ROWS-1,1 do
			local _test = ''
			for i = col,col+3 do
				_test = _test..Board[row][i]
			end
			if _test == '0000' or _test == '1111' then
				for _,_piece in next,Pieces:GetChildren() do
					if _piece.Transparency == 0 then
						_piece.Transparency = 0.6
					end
				end
				for i = col,col+3 do
					local _piece = Pieces:FindFirstChild('Piece'..row..'_'..i)
					_piece.Color = _color
					_piece.Transparency = 0
				end
				return true
			end
		end
	end
	-- Diagonal Right
	for row = 0,MAX_ROWS-4,1 do
		for col = 0,MAX_COLS-4,1 do
			local _test = ''
			local _index = 0
			for i = row,row+3 do
				_test = _test..Board[i][col+_index]
				_index += 1
			end
			if _test == '0000' or _test == '1111' then
				for _,_piece in next,Pieces:GetChildren() do
					if _piece.Transparency == 0 then
						_piece.Transparency = 0.6
					end
				end
				local _index = 0
				for i = row,row+3 do
					local _piece = Pieces:FindFirstChild('Piece'..i..'_'..col+_index)
					_piece.Color = _color
					_piece.Transparency = 0
					_index += 1
				end
				return true
			end
		end
	end
	-- Diagonal Left
	for row = MAX_ROWS-1,3,-1 do
		for col = 0,MAX_COLS-4,1 do
			local _test = ''
			local _index = 0
			for i = row,row-3,-1 do
				_test = _test..Board[i][col+_index]
				_index += 1
			end
			if _test == '0000' or _test == '1111' then
				for _,_piece in next,Pieces:GetChildren() do
					if _piece.Transparency == 0 then
						_piece.Transparency = 0.6
					end
				end
				local _index = 0
				for i = row,row-3,-1 do
					local _piece = Pieces:FindFirstChild('Piece'..i..'_'..col+_index)
					_piece.Color = _color
					_piece.Transparency = 0
					_index += 1
				end
				return true
			end
		end
	end
end

Network.Receive('Connect4',function(f,...)
	Board[f](Board,...)
end)

return Board
