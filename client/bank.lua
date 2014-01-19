class 'Bank'

function Bank:__init()
	Events:Subscribe( "Render", self, self.Render )
	Events:Subscribe( "LocalPlayerMoneyChange", self, self.LocalPlayerMoneyChange )
    Events:Subscribe( "LocalPlayerChat", self, self.LocalPlayerChat )
    Events:Subscribe( "LocalPlayerInput", self, self.LocalPlayerInput )
    Events:Subscribe( "ModulesLoad", self, self.ModulesLoad )
    Events:Subscribe( "ModuleUnload", self, self.ModuleUnload )

	self.bank_colour 		= Color( 251, 184, 41 )
	-- Rule out any initial updates from serverside bank
	self.timer 				= Timer()
	self.message_size 		= TextSize.Huge
	self.submessage_size 	= TextSize.Large
	self.money_visible		= true

    self:CreateSettings()
end

function Bank:CreateSettings()
    self.window_open = false

    self.window = Window.Create()
    self.window:SetSize( Vector2( 300, 50 ) )
    self.window:SetPosition( (Render.Size - self.window:GetSize())/2 )

    self.window:SetTitle( "Bank Settings" )
    self.window:SetVisible( self.window_open )
    self.window:Subscribe( "WindowClosed", self, self.WindowClosed )

    self.widgets = {}

    local enabled_checkbox = LabeledCheckBox.Create( self.window )
    enabled_checkbox:SetSize( Vector2( 300, 20 ) )
    enabled_checkbox:SetDock( GwenPosition.Top )
    enabled_checkbox:GetLabel():SetText( "Money Visible" )
    enabled_checkbox:GetCheckBox():SetChecked( self.money_visible )
    enabled_checkbox:GetCheckBox():Subscribe( "CheckChanged", 
        function() self.money_visible = enabled_checkbox:GetCheckBox():GetChecked() end )
end

function Bank:GetWindowOpen()
    return self.window_open
end

function Bank:SetWindowOpen( state )
    self.window_open = state
    self.window:SetVisible( self.window_open )
    Mouse:SetVisible( self.window_open )
end

function Bank:LocalPlayerChat( args )
    local msg = args.text

    if msg == "/bank" then
        self:SetWindowOpen( not self:GetWindowOpen() )
    end
end

function Bank:LocalPlayerInput( args )
    if self:GetWindowOpen() and Game:GetState() == GUIState.Game then
        return false
    end
end

function Bank:WindowClosed( args )
    self:SetWindowOpen( false )
end

function Bank:ModulesLoad()
    Events:Fire( "HelpAddItem",
        {
            name = "Bank",
            text = 
                "The Bank stores your money automatically and lets you send "..
                "money to others using /sendmoney playername amount - " ..
                "you can also turn off the money at the top-right using /bank"
        } )
end

function Bank:ModuleUnload()
    Events:Fire( "HelpRemoveItem",
        {
            name = "Bank"
        } )
end

function Bank:Render()
	if Game:GetState() ~= GUIState.Game then return end

	if self.money_visible then
		local pos_2d = Vector2( Render.Width - 5, (Render:GetTextHeight("FPS") + 1) * 2 )
		local text = "$" .. tostring(LocalPlayer:GetMoney())

		pos_2d = pos_2d - Vector2( Render:GetTextWidth(text), 0 )
		Render:DrawText( pos_2d + Vector2( 1, 1 ), text, Color( 0, 0, 0, 80 ) )
		Render:DrawText( pos_2d, text, self.bank_colour )
	end

	if self.message_timer and self.message then
		local alpha = 1

		if self.message_timer:GetSeconds() > 1 and self.message_timer:GetSeconds() < 2 then
			alpha = 1 - (self.message_timer:GetSeconds() - 1)
		elseif self.message_timer:GetSeconds() >= 2 then
			self.message_timer = nil
			self.message = nil
			self.submessage = nil
			return
		end

		local width = Render:GetTextWidth( self.message, self.message_size )
		local height = Render:GetTextHeight( self.message, self.message_size )

		local pos_2d = Vector2( (Render.Width - width)/2, Render.Height/3 - height/2 )
		local col = Copy( self.bank_colour )
		col.a = col.a * alpha

		Render:DrawText( pos_2d + Vector2( 1, 1 ), self.message, Color( 0, 0, 0, 80 ), self.message_size )
		Render:DrawText( pos_2d, self.message, col, self.message_size )

		local submessage_width = Render:GetTextWidth( self.submessage, self.submessage_size )

		pos_2d = Vector2( (Render.Width - submessage_width)/2, Render.Height/3 + height/2 )
		Render:DrawText( pos_2d + Vector2( 1, 1 ), self.submessage, Color( 0, 0, 0, 80 ), self.submessage_size )
		Render:DrawText( pos_2d, self.submessage, col, self.submessage_size )
	end
end

function Bank:LocalPlayerMoneyChange( args )
	local diff = args.new_money - args.old_money

	-- Very unlikely you'll be able to get any money in the first 2 seconds!
	if diff > 0 and self.timer:GetSeconds() > 2 then
		self.message_timer = Timer()
		self.message = "+$" .. tostring(diff)
		self.submessage = "$" .. tostring(args.new_money)
	end
end

bank = Bank()