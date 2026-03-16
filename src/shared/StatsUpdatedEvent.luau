-- StatsUpdatedEvent RemoteEvent setup
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local event = ReplicatedStorage:FindFirstChild("StatsUpdatedEvent")
if not event then
    event = Instance.new("RemoteEvent")
    event.Name = "StatsUpdatedEvent"
    event.Parent = ReplicatedStorage
end
return event
