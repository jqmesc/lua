-- Class Definition
do

local Connect4={};
local SizeX=8;
local SizeY=8;

function Connect4:Initialize()
	local self={};
	self.Board={};
	self.Turn='O';
	for x=0,SizeX-1 do
		self.Board[x]={};
		for y=0,SizeY-1 do
			self.Board[x][y]=' ';
		end
	end
	setmetatable(self,{__index=Connect4});
	return self;
end

function Connect4:Display()
	for x=0,SizeX-1 do
		local z='|';
		for y=0,SizeY-1 do
			z=z..self.Board[x][y]..'|';
		end
		print(z);
	end
	print('-----------------');
end

function Connect4:Place(col)
	for x=SizeX-1,0,-1 do
		if self.Board[x][col-1]==' ' then
			self.Board[x][col-1]=self.Turn;
			return true;
		end
	end
	return false;
end

function Connect4:CheckWin()
	-- Horizontal
	for y=0,SizeY-4 do
		for x=0,SizeX-1 do
			local _test='';
			for i = y,y+3 do
				_test = _test..self.Board[x][i];
			end
			if _test=='OOOO' or _test=='XXXX' then
				return true;
			end
		end
	end
	-- Vertical
	for x=0,SizeX-4 do
		for y=0,SizeY-1 do
			local _test = '';
			for i=x,x+3 do
				_test=_test..self.Board[i][y];
			end
			if _test=='OOOO' or _test=='XXXX' then
				return true;
			end
		end
	end
	-- Diagonal Right
	for x=0,SizeX-4,1 do
		for y=0,SizeY-4,1 do
			local _test=''
			local _index=0
			for i=x,x+3 do
				_test=_test..self.Board[i][y+_index]
				_index=_index+1
			end
			if _test=='OOOO' or _test=='XXXX' then
				return true
			end
		end
	end
	-- Diagonal Left
	for x=SizeX-1,3,-1 do
		for y=0,SizeY-4,1 do
			local _test=''
			local _index=0
			for i = x,x-3,-1 do
				_test=_test..self.Board[i][y+_index]
				_index=_index+1
			end
			if _test=='OOOO' or _test=='XXXX' then
				return true
			end
		end
	end
	for x=0,SizeX-1 do
		for y=0,SizeY-1 do
			if self.Board[x][y]==' ' then
				return false
			end
		end
		return -- Tie
	end
end

-- Main Function
local game=Connect4:Initialize();
game:Display()

while game:CheckWin()==false do
	if game.Turn=='O' then
		game.Turn='X'
	else
		game.Turn='O'
	end
	-- Ask for input
	repeat
		io.write('Player '..game.Turn..', Enter col number (1-8): ');
		io.flush();
		answer=tonumber(io.read());
	until answer>=1 and answer<=SizeY and game:Place(answer)
	game:Display();
end
if game:CheckWin()==true then
	print('Player '..game.Turn..' wins!');
else
	print('The game was a tie!');
end

end