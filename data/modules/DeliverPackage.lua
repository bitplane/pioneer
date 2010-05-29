
local delivery_flavours = {
	{
		adtext = "GOING TO the %1 system? Money paid for delivery of a small package.",
		introtext = "Hi, I'm %1. I'll pay you %2 if you will deliver a small package to %3 in the %4 system.",
		whysomuchdoshtext = "When a friend visited me she left behind some clothes and antique paper books. I'd like to have them returned to her.",
		successmsg = "Thank you for the delivery. You have been paid in full.",
		failuremsg = "Jesus wept, you took forever over that delivery. I'm not willing to pay you.",
		danger = 0,
		time = 3,
		money = .5,
	}, {
		adtext = "WANTED. Delivery of a package to the %1 system.",
		introtext = "Hello. I'm %1. I'm willing to pay %2 for a ship to carry a package to %3 in the %4 system.",
		whysomuchdoshtext = "It is nothing special.",
		successmsg = "The package has been received and you have been paid in full.",
		failuremsg = "I'm frustrated by the late delivery of my package, and I refuse to pay you.",
		danger = 0,
		time = 1,
		money = 1,
	}, {
		adtext = "URGENT. Fast ship needed to deliver a package to the %1 system.",
		introtext = "Hello. I'm %1. I'm willing to pay %2 for a ship to carry a package to %3 in the %4 system.",
		whysomuchdoshtext = "It is a research proposal and must be delivered by the deadline or we may not get funding.",
		successmsg = "You have been paid in full for the delivery. Thank you.",
		failuremsg = "I was quite clear about the deadline and am very disappointed by the late delivery. You will not be paid.",
		danger = 0,
		time = .75,
		money = 1.1,
	}, {
		adtext = "DELIVERY. Documents to the %1 system. %2 to an experienced pilot.",
		introtext = "Hello. I'm %1. I'm willing to pay %2 for a ship to carry a package to %3 in the %4 system.",
		whysomuchdoshtext = "Some extremely sensitive documents have fallen into my hands, and I have reason to believe that the leak has been traced to me.",
		successmsg = "Your timely and discrete service is much appreciated. You have been paid in full.",
		failuremsg = "Useless! I will never depend on you again! Needless to say, you will not be paid for this.",
		danger = 1.5,
		time = 0.75,
		money = 2.5,
	}
}

for i = 0,10 do
	local sys = StarSystem:new(i,2,0)
	print('Looking near ' .. sys:GetSectorX() .. '/' .. sys:GetSectorY() .. '/' .. sys:GetSystemNum())
	print(sys:GetSystemName())
	print(sys:GetSystemShortDescription())
	local sport = sys:GetRandomStarportNearButNotIn()
	if sport then
		print(sport:GetBodyName() .. ' in the ' .. sport:GetSystemName() .. ' system')
	else
		print("No suitable nearby space station found.")
	end
end

Module:new {
	__name = 'DeliverPackage',

	Init = function(self)
		self:EventListen("onCreateBB")
		self:EventListen("onUpdateBB")
		self:EventListen("onEnterSystem")
		self.ads = {}
		self.missions = {}
	end,

	GetPlayerMissions = function(self)
		return self.missions
	end,

	_TryAddAdvert = function(self, station)
		local gender = Rand.Int(0,1) == 1
		local flavour = Rand.Int(1, #delivery_flavours)
		ad = {
			flavour = flavour,
			personGender = gender,
			client = Rand.PersonName(gender),
			reward = Rand.Real(200, 1000) * delivery_flavours[flavour].money,
			due = Pi.GetGameTime() + Rand.Real(0, delivery_flavours[flavour].time * 60*60*24*31),
			bb = station,
			dest = Pi.GetCurrentSystem():GetRandomStarportNearButNotIn(),
			id = #self.ads+1
		}
		-- if we found a destination
		if ad.dest ~= nil then
			table.insert(self.ads, ad)
			local addescription = _(delivery_flavours[ad.flavour].adtext, {
					ad.dest:GetSystemName(),
					format_money(ad.reward) } )
			station:SpaceStationAddAdvert(self.__name, #self.ads, addescription)
		end
	end,

	onCreateBB = function(self, args)
		local station = args[1]
		for i = 1,10 do --Rand.Int(0, 5) do
			self:_TryAddAdvert(station)
		end
	end,

	onEnterSystem = function(self)
		print("This module recons you just entered the " ..
		Pi.GetCurrentSystem():GetSystemName() .. " system.")
		ship, e = Pi.SpawnShip("Ladybird Starfighter", Pi.GetGameTime()+60*60)
		print(ship:GetLabel())
		print(ship)
		print(e)
	end,
	
	onUpdateBB = function(self, args)
		local station = args[1]
		for k,ad in pairs(self.ads) do
			if (ad.bb == station) and (ad.due < Pi.GetGameTime() + 60*60*24*1) then
				self.ads[k] = nil
				ad.bb:SpaceStationRemoveAdvert(self.__name, ad.id)
			end	
		end
		if Rand.Int(0,12*60*60) < 60*60 then -- roughly once every twelve hours
			self:_TryAddAdvert(station)
		end
	end,
	
	DialogHandler = function(self, dialog, optionClicked)
		local ad = self.ads[dialog:GetAdRef()]
		dialog:Clear()
		if optionClicked == -1 then
			dialog:Close()
			return
		elseif optionClicked == 0 then
			dialog:SetMessage(_(delivery_flavours[ad.flavour].introtext, {
				ad.client, format_money(ad.reward), ad.dest:GetBodyName(), ad.dest:GetSystemName() }))
		elseif optionClicked == 1 then
			dialog:SetMessage(delivery_flavours[ad.flavour].whysomuchdoshtext)
		elseif optionClicked == 2 then
			dialog:SetMessage(_('It must be delivered by %1', { Date.Format(ad.due) }))
		elseif optionClicked == 3 then
			dialog:RemoveAdvertOnClose()
			self.ads[ad.id] = nil
			ad.description = "hell yeah"
			ad.status = "active"
			table.insert(self.missions, ad)
			dialog:SetMessage("Sweet")
			dialog:AddOption("Hang up.", -1)
			return
		end
		dialog:AddOption("Why so much money?", 1);
		dialog:AddOption("Could you repeat the original request?", 0);
		dialog:AddOption("How soon must it be delivered?", 2);
		dialog:AddOption("Ok, agreed.", 3);
		dialog:AddOption("Hang up.", -1);
	end,
}