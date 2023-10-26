-- sinsane da best scripter

local Network = require(game.ServerScriptService.Network)
local Input = require(game.ReplicatedStorage.Shared.Input)
local Tween = require(game.ReplicatedStorage.Shared.Tween)
local FastLoop = require(game.ReplicatedStorage.Shared.FastLoop)
local ArcMotion = require(game.ReplicatedStorage.Shared.ArcMotion)
local Points = game.Workspace.Basketball_Points
local Hoop = game.Workspace.Random.BasketballHoop.Hoop
local Backboard = game.Workspace.Random.Backboard

local DIFFICULTY = 3; -- x times harder
local Basketball = {Active=nil;Skill=nil;Made=0;Time=0;}

local function MovePlayer(user,p)
	local Character=user.Character
	if not Character then return end
	local Humanoid=Character:WaitForChild('Humanoid',1)
	if not Humanoid then return end
	Humanoid:MoveTo(p)
	while wait() do
		if (Character.HumanoidRootPart.Position*Vector3.new(1,0,1)-p*Vector3.new(1,0,1)).Magnitude<=2 then
			break
		end
		if Humanoid.Health<=0 then
			break
		end
	end
end

local function Actions(user,b)
	if not game.Players:FindFirstChild(user.Name) then return end -- Ensure player did not leave
	Network.Send('Controls',user,b)
	Network.Send('ActivateGui',user,'BBallUI',not b)
end

function Basketball:Initialize(user)
	--assert(not self.Active,'User already playing!')
	if self.Active then
		return
	end
	self:Reset(user)
	self.Active = user
	local self = user.Character
	local function Face(x)
		spawn(function()
			local hrp = self.HumanoidRootPart
			Tween(hrp,.4,{CFrame=CFrame.new(hrp.Position,x*Vector3.new(1,0,1)+Vector3.new(0,hrp.Position.Y,0))})
		end)
	end

	self.Humanoid.Died:Once(function()
		if Basketball.Active == user then
			Basketball:Reset(user)
		end
	end)

	local c = coroutine.create(function()
		if Basketball.Active ~= user then
			Basketball:Reset(user)
			return
		end

		Actions(user,false)
		MovePlayer(user,Vector3.new(-395.587, 5.238, -516.035)) -- Gate position

		for i = 1,3 do
			if Basketball.Active ~= user then
				return
			end
			Backboard.display_c.SurfaceGui.TextLabel.Text = tostring(i)
			-- Move to position
			local point = Points:FindFirstChild(i)
			local pos = point.Position*Vector3.new(1,0,1)+Vector3.new(0,self.HumanoidRootPart.Position.Y,0)
			local face = Hoop.Position*Vector3.new(1,0,1)+Vector3.new(0,self.HumanoidRootPart.Position.Y,0)

			local x
			spawn(function()
				local z = tick()
				repeat task.wait()
					if Basketball.Active ~= user then
						return
					end
					if user.Character then
						Network.Send('Update',user,'Camera',CFrame.new(self.HumanoidRootPart.Position+Vector3.new(0,5,0),face))
					end
					for i,v in next,Input.Keys[user.Name] do
						if v and not x then
							self.Humanoid:MoveTo(pos)
						end
					end
				until x or tick() - z >= 4
			end)

			wait(.1)
			MovePlayer(user,pos)
			x = true
			if Basketball.Active ~= user then
				return
			end
			Face(face)
			Network.Send('Update',user,'Camera',CFrame.new(pos+Vector3.new(0,5,0),face))
			for _ = 1,5 do
				if Basketball.Active ~= user then
					return
				end
				-- Ready to shoot
				wait(.1)
				-- Shooting
				Network.Send('BBall_Check',user)
				repeat task.wait() until Basketball.Skill or Basketball.Active ~= user

				if Basketball.Active ~= user then
					Basketball:Reset(user)
					return
				end

				local p
				if Basketball.Skill >= 2 or Basketball.Skill <= 0 then
					p = 1;
				elseif Basketball.Skill > 1 then
					p = Basketball.Skill - 1
				elseif Basketball.Skill < 1 then
					p = 1 - Basketball.Skill 
				else
					p = 0
				end
				p*=DIFFICULTY 
				Basketball:Shoot(100-p*100)
				coroutine.yield();
			end
		end
	end)

	spawn(function()
		local plr=Basketball.Active
		repeat wait(1)
			if Basketball.Active==plr then
				Basketball.Time += 1;
				if Basketball.Time == 180 then
					Basketball:Reset(plr)
				end
			end
		until not Basketball.Active or Basketball.Active~=user
	end)

	spawn(function()
		repeat task.wait()
			if Basketball.Active ~= user then
				break
			end
			local x = tostring(Basketball.Made)
			local y = tostring(math.round(Basketball.Time/60))
			local z = tostring(Basketball.Time % 60)

			local a = string.match(x,'(%d?)%d')
			local b = string.match(x,'%d?(%d)')
			local c = string.match(y,'(%d?)%d')
			local d = string.match(y,'%d?(%d)')
			local e = string.match(z,'(%d?)%d')
			local f = string.match(z,'%d?(%d)')

			Backboard.display_1.L.SurfaceGui.TextLabel.Text = c ~= '' and c or '0'
			Backboard.display_1.R.SurfaceGui.TextLabel.Text = d ~= '' and d or '0'

			Backboard.display_2.L.SurfaceGui.TextLabel.Text = e ~= '' and e or '0'
			Backboard.display_2.R.SurfaceGui.TextLabel.Text = f ~= '' and f or '0'

			Backboard.display_3.L.SurfaceGui.TextLabel.Text = a ~= '' and a or '0'
			Backboard.display_3.R.SurfaceGui.TextLabel.Text = b ~= '' and b or '0'
		until Basketball.Active ~= user
	end)

	for i = 1,15 do
		if Basketball.Active ~= user then
			break
		end
		coroutine.resume(c)
		repeat wait() until Basketball.Skill or not Basketball.Active
		wait()
		repeat wait() until not Basketball.Skill or not Basketball.Active
	end
	
	if Basketball.Made==15 then
		Network.Pass('AwardEmblem',Basketball.Active,'Basketball')
	end
	
	if Basketball.Active then
		MovePlayer(user,Hoop.Parent.Exit.Position)
		wait(.2)
		Basketball.Active = nil;
	end
	Actions(user,true)
	--print('RESET')
end


function Basketball:Shoot(x)
	assert(self.Active,'No user shooting!')
	local rng = math.random(1,100)
	local make = rng <= math.clamp(math.round(x),0,100)
	local _cframe = self.Active.Character.Head.CFrame
	local ball = game.ReplicatedStorage.Ball:Clone()
	ball.Parent = game.Workspace
	ball.CFrame = CFrame.new((_cframe + _cframe.LookVector*2).Position,Hoop.Position)
	ball.Anchored = false

	--warn('Shooting percentage: %',math.clamp(math.round(x),0,100))
	--warn('Made shot',make)

	Network.Send('UpdatePercent',self.Active,math.clamp(math.round(x),0,100))

	if make then
		ArcMotion(ball,Hoop.Position,2,true) 
		--Tween(ball,.1,{Position=Vector3.new(Hoop.Position.X,ball.Position.Y,Hoop.Position.Z)})

		self.Made += 1;
		spawn(function()
			ball.Anchored = true
			ball.Anchored = false
			wait(.2)
			ball.CanCollide = true
			wait(5)
			ball:Destroy()
		end)
	else
		ball.CanCollide = true
		ArcMotion(ball,Hoop.Position+Vector3.new( math.random(-2,2),math.random(-3,0),math.random(-5,0) ),2,false)
		spawn(function()
			wait(5)
			ball:Destroy()
		end)
	end
	Basketball.Skill = nil
end

function Basketball:Reset(user)
	if user and game.Players:FindFirstChild(user.Name) then
		Network.Send('ActivateGui',user,'BBall_UI',false)
	end
	Basketball.Active = nil;
	Basketball.Skill = nil;
	Basketball.Made = 0;
	Basketball.Time = 0;

	Backboard.display_1.L.SurfaceGui.TextLabel.Text = '0'
	Backboard.display_1.R.SurfaceGui.TextLabel.Text = '0'
	Backboard.display_2.L.SurfaceGui.TextLabel.Text = '0'
	Backboard.display_2.R.SurfaceGui.TextLabel.Text = '0'
	Backboard.display_3.L.SurfaceGui.TextLabel.Text = '0'
	Backboard.display_3.R.SurfaceGui.TextLabel.Text = '0'
	Backboard.display_c.SurfaceGui.TextLabel.Text = '0'
end

Network.Listen('BBall_Check',function(u,n)
	Basketball.Skill = n;
end)

return Basketball