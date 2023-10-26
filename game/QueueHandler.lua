-- // Vars // --
local Network=require(game:GetService('ServerScriptService'):WaitForChild('Network'))
local Queue=require(game:GetService('ReplicatedStorage'):WaitForChild('Shared'):WaitForChild('Queue'))

local ChangeCourse=Instance.new('BindableEvent')

local Players=game:GetService('Players')

local TestQueue=Queue.new(game.Workspace.Queue_Points.Ride1)

local LEFT = {}

local function MovePlayer(player,position)
	--repeat task.wait() until not MOVING[player]
	local Character = player.Character
	local Humanoid = Character.Humanoid

	Network.Send('Controls',player,false)

	--warn('moving')
	--MOVING[player] = true
	Humanoid:MoveTo(position)
	Humanoid.MoveToFinished:Wait()
	--MOVING[player] = false
	--warn('move complete')

	--Network.Send('Controls',player,true)
end

function findPart(n)
	local max = TestQueue.MaxRiders
	if n == 1 then
		return TestQueue.Points.KeyPoints.Point_1
	else
		return TestQueue.Points.SubPoints:FindFirstChild('Point_'..max-n)
	end
end




-- // Events // --
TestQueue.Events.PlayerJoined.Event:Connect(function(player)
	player = player.Player
	Network.Send('ActivateGui',player,'LeaveQueue',true)

	local max = TestQueue.MaxRiders
	local open = #TestQueue:GetQueuedPlayers()
	local point = findPart(open)

	local c = ChangeCourse.Event:Connect(function(p,new)
		if p == player then
			warn(p,'course was changed')
			point = new;
		end
	end)

	local List = TestQueue.Points.NumPoints
	local Index = max
	local i = 1
	--warn(List)
	for n = #TestQueue.Points.KeyPoints:GetChildren(),2,-1 do
		if not TestQueue:GetPlayer(player) then -- Left queue
			return
		end

		if open < Index then
			--warn('key point',n,'is open')
			local point = TestQueue.Points.KeyPoints[n]
			Index -= List[i+1] or 0
			MovePlayer(player,point.Position)
		end

		i += 1
	end
	warn(player,'is moving to latest updated position')
	MovePlayer(player,point.Position) -- Do not fire this if person in front left

	c:Disconnect() -- Ensure no memory leak
end)


local PerQueue = 2; -- Number of riders able to enter ride
TestQueue.Events.PlayersMoved.Event:Connect(function(players)
	--print(TestQueue:GetQueuedPlayers())
	spawn(function()
		for _,player in ipairs(players) do
			local player = player.Player
			--warn('moving:',player)
			spawn(function()
				local HRP = player.Character.HumanoidRootPart.CFrame
				MovePlayer(player,(HRP + HRP.LookVector*15).Position)
			end)
			wait(0.5) -- Delay for more realistic line movement
		end
	end)
	spawn(function()
		for _,player in ipairs(TestQueue:GetQueuedPlayers()) do
			--warn('aligning:',player)
			spawn(function()
				MovePlayer(player.Player, findPart(player.Place).Position)
			end)
			wait(0.5) -- Delay for more realistic line movement
		end
	end)
end)

TestQueue.Events.PlayerLeft.Event:Connect(function(player,died)	
	--warn('QUEUE POSITION:',player)

	local position = player.Place
	local player = player.Player

	spawn(function() -- User exit queue
		if not died then
			local HRP = player.Character.HumanoidRootPart
			local KP = TestQueue.Points.KeyPoints
			local H = player.Character.Humanoid
			local n = #KP:GetChildren()

			HRP.CFrame = KP:FindFirstChild(n).CFrame
			H:MoveTo(HRP.Position)
		end
		if table.find(Players:GetPlayers(),player) then
			Network.Send('ActivateGui',player,'LeaveQueue',false)
			Network.Send('Controls',player,true)
		end
	end)
	local queue = TestQueue:GetQueuedPlayers()
	--warn('NEW QUEUE:',queue)
	for i = position,#queue do
		--warn('Should move:',queue[i])
		ChangeCourse:Fire(queue[i].Player,findPart(queue[i].Place))
	end
end)

Players.PlayerAdded:Connect(function(Player)
	local Character=Player.Character or Player.CharacterAdded:Wait()
	if Character then
		local Humanoid=Character:WaitForChild('Humanoid')
		if Humanoid then
			Humanoid.Died:Connect(function()
				if TestQueue:GetPlayer(Player) then
					print('died')
					TestQueue:LeaveQueue(Player,true)
				end
			end)
		end
	end
end)

Players.PlayerRemoving:Connect(function(Player)
	if TestQueue:GetPlayer(Player) then
		print('leave')
		TestQueue:LeaveQueue(Player,true)
	end
end)


-- // Listeners // --
Network.Listen('JoinQueue',function(Player)
	--print('Join')
	TestQueue:JoinQueue(Player)
	--print(TestQueue.QueueOrder,TestQueue.Players)
end)

Network.Listen('LeaveQueue',function(Player)
	--print('Leave')
	TestQueue:LeaveQueue(Player)
	--print(TestQueue.QueueOrder,TestQueue.Players)
end)

Network.Listen('MovePlayers',function(Player)
	--print('Move')
	TestQueue:MoveAll(PerQueue)
	--print(TestQueue.QueueOrder,TestQueue.Players)
end)