--// made by @baum1000000

local error = function(messgae: string)
	error("[Script Templates]: " .. messgae)
end

local warn = function(message: string)
	warn("[Script Templates]: " .. message)
end

local print = function(message: string)
	print("[Script Templates]: " .. message)
end

local ScriptEditorService = game:GetService("ScriptEditorService")
local ServerStorage = game.ServerStorage
local HttpService = game:GetService("HttpService")

local Toolbar = plugin:CreateToolbar("baum's Plugins")
local PluginButton = Toolbar:CreateButton("Script Templates", "Open Script Templates", "rbxassetid://10831181930")

local WidgetInfo = DockWidgetPluginGuiInfo.new(Enum.InitialDockState.Float, false, false, 250, 250, 150, 150)
local Widget = plugin:CreateDockWidgetPluginGui("Script_Templates", WidgetInfo)

local PluginFolder = script.Parent
local Modules = PluginFolder.Modules
local Ui = PluginFolder.Ui

local Background = Ui.Background:Clone()
local MainFrame = Background.MainFrame
local CreateTemplateFrame = Background.CreateTemplateFrame

local matcher = require(Modules.matcher)

local DefaultSource = {
	module = [[
	local module = {}

	return module

	]],
	
	serverscript = [[
	print("Hello world!")
	
	]],
	
	localscript = [[
	print("Hello world!")
	
	]],
}

local SelectedSource = {
	module = [[]],
	serverscript = [[]],
	localscript = [[]],
}

local DataTable = {
	SearchStringArray = {},
	Templates = {},
	UiTemplates = {},
	matcher = nil
}

local Images = {
	ModuleScript = "rbxassetid://5016313061",
	Script = "rbxassetid://46342657",
	LocalScript = "rbxassetid://1782834632",
	Selected = "rbxassetid://7733715400"
}

local Data = ServerStorage:FindFirstChild("script_templates_plugin_data")

local pluginVersion = script.Version.Value
local VersionChecker = require(10831327449)

local StudioStyleGuideColor = Enum.StudioStyleGuideColor

local CanWidgetOpen = true

local CurrenSelectedServerTemplate = nil
local CurrenSelectedLocalTemplate = nil
local CurrenSelectedModuleTemplate = nil

local function GetColor(Style)
	return settings().Studio.Theme:GetColor(Style)
end

local function SetColors(Elements)
	for i, v in pairs(Elements) do
		if v then
			v.BackgroundColor3 = GetColor(StudioStyleGuideColor.MainBackground)
			v.BorderColor3 = GetColor(StudioStyleGuideColor.Border)

			if v:IsA("TextLabel") or v:IsA("TextButton") or v:IsA("TextBox") then
				v.TextColor3 = GetColor(StudioStyleGuideColor.MainText)
			elseif v:IsA("ScrollingFrame") then
				v.ScrollBarImageColor3 = GetColor(StudioStyleGuideColor.Mid)
			elseif v:IsA("ImageButton") or v:IsA("ImageLabel") then
				v.ImageColor3 = GetColor(StudioStyleGuideColor.MainText)
			end
		end
	end
end

local function SetStudioColorsForUiElements(Elements)
	settings().Studio.ThemeChanged:Connect(function()
		SetColors(Elements)
	end)
	
	SetColors(Elements)
end

local function ReloadSearchStringArray()
	DataTable.SearchStringArray = {}
	
	for i, v in pairs(DataTable.Templates) do
		table.insert(DataTable.SearchStringArray, i)
	end
	
	DataTable.matcher = matcher.new(DataTable.SearchStringArray, true, true)
end

local function CreateNewUiTemplate(Template)
	local UiTemplate = Ui.Template:Clone()
	
	UiTemplate.Name = "Ui_" .. Template.Name
	UiTemplate.TemplateName.Text = Template.CustomName.Value
	UiTemplate.TypeImage.Image = Images[Template.ClassName]
	UiTemplate.Parent = MainFrame.Templates
	
	UiTemplate.DeleteButton.Activated:Connect(function()
		local index = 0
		
		for i, v in pairs(DataTable.UiTemplates) do
			index += 1
			
			if v == UiTemplate then
				table.remove(DataTable.UiTemplates, index)
				
				break
			end
		end
		
		for i, v in pairs(DataTable.Templates) do
			index += 1

			if v == Template then
				table.remove(DataTable.Templates, index)

				break
			end
		end
		
		ReloadSearchStringArray()
		
		Template:Destroy()
		UiTemplate:Destroy()
	end)
	
	UiTemplate.SelectButton.Activated:Connect(function()
		if Template.ClassName == "Script" then
			if CurrenSelectedServerTemplate == Template then
				UiTemplate.SelectButton.Image = ""

				CurrenSelectedServerTemplate = nil

				SelectedSource.serverscript = DefaultSource.serverscript

				return
			end
			
			if CurrenSelectedServerTemplate ~= nil then
				DataTable.UiTemplates[CurrenSelectedServerTemplate].SelectButton.Image = ""
				
				CurrenSelectedServerTemplate = Template
				
				SelectedSource.serverscript = Template.Source
				
				UiTemplate.SelectButton.Image = Images.Selected
			else
				CurrenSelectedServerTemplate = Template

				SelectedSource.serverscript = Template.Source
				
				UiTemplate.SelectButton.Image = Images.Selected
			end
		elseif Template.ClassName == "LocalScript" then
			if CurrenSelectedLocalTemplate == Template then
				UiTemplate.SelectButton.Image = ""
				
				CurrenSelectedLocalTemplate = nil
				
				SelectedSource.localscript = DefaultSource.localscript
				
				return
			end
			
			if CurrenSelectedLocalTemplate ~= nil then
				DataTable.UiTemplates[CurrenSelectedLocalTemplate].SelectButton.Image = ""

				CurrenSelectedLocalTemplate = Template

				SelectedSource.localscript = Template.Source

				UiTemplate.SelectButton.Image = Images.Selected
			else
				CurrenSelectedLocalTemplate = Template

				SelectedSource.localscript = Template.Source

				UiTemplate.SelectButton.Image = Images.Selected
			end
		elseif Template.ClassName == "ModuleScript" then
			if CurrenSelectedModuleTemplate == Template then
				UiTemplate.SelectButton.Image = ""

				CurrenSelectedModuleTemplate = nil

				SelectedSource.module = DefaultSource.module

				return
			end
			
			if CurrenSelectedModuleTemplate ~= nil then
				DataTable.UiTemplates[CurrenSelectedModuleTemplate].SelectButton.Image = ""

				CurrenSelectedModuleTemplate = Template

				SelectedSource.module = Template.Source

				UiTemplate.SelectButton.Image = Images.Selected
			else
				CurrenSelectedModuleTemplate = Template

				SelectedSource.module = Template.Source

				UiTemplate.SelectButton.Image = Images.Selected
			end
		end
	end)
	
	SetStudioColorsForUiElements({UiTemplate, UiTemplate.SelectButton, UiTemplate.DeleteButton, UiTemplate.TemplateName})
	
	DataTable.UiTemplates[Template] = UiTemplate
	
	return UiTemplate
end

function AddScriptToData(Template)
	if Template.ClassName == "Script" then
		Template.Parent = Data.serverscript_templates
		
		DataTable.Templates[Template.CustomName.Value] = Template
		
		CreateNewUiTemplate(Template)
		ReloadSearchStringArray()
	elseif Template.ClassName == "LocalScript" then
		Template.Parent = Data.localscript_templates

		DataTable.Templates[Template.CustomName.Value] = Template

		CreateNewUiTemplate(Template)
		ReloadSearchStringArray()
	elseif Template.ClassName == "ModuleScript" then
		Template.Parent = Data.modulescript_templates

		DataTable.Templates[Template.CustomName.Value] = Template

		CreateNewUiTemplate(Template)
		ReloadSearchStringArray()
	end
end

local function NewTemplateScript(Script)
	CanWidgetOpen = false
	Widget.Enabled = false
	
	plugin:OpenScript(Script)

	local c = nil

	c = ScriptEditorService.TextDocumentDidClose:Connect(function(doc)
		if doc.Name == Script.Name then
			AddScriptToData(Script)

			c:Disconnect()
			
			CanWidgetOpen = true
			
			Widget.Enabled = true
			
			CreateTemplateFrame.Visible = false
			MainFrame.Visible = true
		end
	end)
end

local function CreateNewTemplate(ScriptType, Name)
	if ScriptType == "ServerScript" then
		local newTemplateScript = Instance.new("Script", game)
		newTemplateScript.Name = "NewTemplate" .. #Data.serverscript_templates:GetChildren() + 1 .. "_" .. HttpService:GenerateGUID(false)

		local CustomName = Instance.new("StringValue", newTemplateScript)
		CustomName.Name = "CustomName"
		CustomName.Value = string.split(newTemplateScript.Name, "_")[1]

		if Name then
			CustomName.Value = Name
		end

		NewTemplateScript(newTemplateScript)
	elseif ScriptType == "LocalScript" then
		local newTemplateScript = Instance.new("LocalScript", game)
		newTemplateScript.Name = "NewTemplate" .. #Data.localscript_templates:GetChildren() + 1 .. "_" .. HttpService:GenerateGUID(false)

		local CustomName = Instance.new("StringValue", newTemplateScript)
		CustomName.Name = "CustomName"
		CustomName.Value = string.split(newTemplateScript.Name, "_")[1]

		if Name then
			CustomName.Value = Name
		end

		NewTemplateScript(newTemplateScript)
	elseif ScriptType == "ModuleScript" then
		local newTemplateScript = Instance.new("ModuleScript", game)
		newTemplateScript.Name = "NewTemplate" .. #Data.modulescript_templates:GetChildren() + 1 .. "_" .. HttpService:GenerateGUID(false)

		local CustomName = Instance.new("StringValue", newTemplateScript)
		CustomName.Name = "CustomName"
		CustomName.Value = string.split(newTemplateScript.Name, "_")[1]

		if Name then
			CustomName.Value = Name
		end

		NewTemplateScript(newTemplateScript)
	end
end

Widget.Title = "Script Templates"

Background.Size = UDim2.new(1, 0, 1, 0)
Background.Position = UDim2.new(0, 0, 0, 0)
Background.Parent = Widget

local SelectedScriptType = "ServerScript"

MainFrame.AddButton.Activated:Connect(function()
	MainFrame.Visible = false
	CreateTemplateFrame.Visible = true
end)

CreateTemplateFrame.Cancel.Activated:Connect(function()
	CreateTemplateFrame.Visible = false
	MainFrame.Visible = true
end)

CreateTemplateFrame.Create.Activated:Connect(function()
	if string.len(CreateTemplateFrame.TemplateNameBox.Text) > 0 then
		CreateNewTemplate(SelectedScriptType, CreateTemplateFrame.TemplateNameBox.Text)
	else
		task.spawn(function()
			CreateTemplateFrame.Create.Text = "Template name muster be longer than 0 letters."
			
			task.wait(2)
			
			CreateTemplateFrame.Create.Text = "Create"
		end)
	end
end)

CreateTemplateFrame.ServerScript.Activated:Connect(function()
	SelectedScriptType = "ServerScript"
	CreateTemplateFrame.TypeLabel.Text = "Type: " .. SelectedScriptType
end)

CreateTemplateFrame.LocalScript.Activated:Connect(function()
	SelectedScriptType = "LocalScript"
	CreateTemplateFrame.TypeLabel.Text = "Type: " .. SelectedScriptType
end)

CreateTemplateFrame.ModuleScript.Activated:Connect(function()
	SelectedScriptType = "ModuleScript"
	CreateTemplateFrame.TypeLabel.Text = "Type: " .. SelectedScriptType
end)

if pluginVersion ~= VersionChecker then
	warn("New Version of this plugin is out: v." .. VersionChecker .. "!")
end

PluginButton.Click:connect(function()
	if not script.Inited.Value then
		script.Inited.Value = true
		
		if Data == nil then
			Data = Instance.new("Folder", ServerStorage)
			
			Data.Name = "script_templates_plugin_data"
		end

		if not Data:FindFirstChild("serverscript_templates") then
			local Folder = Instance.new("Folder", Data)

			Folder.Name = "serverscript_templates"
		end
		
		if not Data:FindFirstChild("localscript_templates") then
			local Folder = Instance.new("Folder", Data)

			Folder.Name = "localscript_templates"
		end
		
		if not Data:FindFirstChild("modulescript_templates") then
			local Folder = Instance.new("Folder", Data)

			Folder.Name = "modulescript_templates"
		end

		for i, v in pairs(Data.serverscript_templates:GetChildren()) do
			AddScriptToData(v)
		end
		
		for i, v in pairs(Data.localscript_templates:GetChildren()) do
			AddScriptToData(v)
		end
		
		for i, v in pairs(Data.modulescript_templates:GetChildren()) do
			AddScriptToData(v)
		end
	end
	
	if CanWidgetOpen then
		Widget.Enabled = not Widget.Enabled
	end
end)

Widget:GetPropertyChangedSignal("Enabled"):Connect(function()
	PluginButton:SetActive(Widget.Enabled)
end)

MainFrame.Searchbox:GetPropertyChangedSignal("Text"):Connect(function()
	if DataTable.matcher ~= nil and string.len(MainFrame.Searchbox.Text) > 0 then
		local result = DataTable.matcher:match(MainFrame.Searchbox.Text)
		
		for i, v in pairs(DataTable.UiTemplates) do
			v.Visible = false
		end
		
		for i, v in pairs(result) do	
			local Template = DataTable.Templates[v]
			local UiTemplate = DataTable.UiTemplates[Template]
			
			UiTemplate.Visible = true
		end
	end
end)

game.DescendantAdded:Connect(function(Child)
	if not Child:IsDescendantOf(Data) then
		if Child.ClassName == "Script" and CurrenSelectedServerTemplate ~= nil then
			Child.Source = SelectedSource.serverscript
		elseif Child.ClassName == "LocalScript" and CurrenSelectedLocalTemplate ~= nil then
			Child.Source = SelectedSource.localscript
		elseif Child.ClassName == "ModuleScript" and CurrenSelectedModuleTemplate ~= nil then
			Child.Source = SelectedSource.module
		end
	end
end)

SetStudioColorsForUiElements({MainFrame, MainFrame.Searchbox, MainFrame.TextLabel, MainFrame.Templates, CreateTemplateFrame, CreateTemplateFrame.Create, CreateTemplateFrame.TemplateNameBox, CreateTemplateFrame.Create, CreateTemplateFrame.Cancel, CreateTemplateFrame.TypeLabel})
