local seat = game.Workspace.Train.TrainControls.ConductorSeat.VehicleSeat
local hrp = game.Players.LocalPlayer.Character:WaitForChild("HumanoidRootPart")

if seat then
   hrp.CFrame = seat.CFrame + Vector3.new(0, 1, 0)
end
