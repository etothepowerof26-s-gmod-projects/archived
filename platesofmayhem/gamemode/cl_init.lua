net.Receive("addText_POM", function()
	local tab = net.ReadTable()
	chat.AddText(unpack(tab)) 
end)