TVAE = {}
TVAE.ModPath = ...
TVAE.ServerLang = "English"
TVAE.LoadedSounds = {}

dofile(TVAE.ModPath .. "/Lua/Voice_Acted_Baro/voiceLines.lua") -- English voice lines list
-- TODO: Get from the server the Language 

if CLIENT then

	--- Fires when a chatMessage is send. Plays the right voice line.
	---@param instance Barotrauma.ChatBox
	---@param ptable Table
	Hook.patch("TestChatMessage", "Barotrauma.ChatBox", "AddMessage",{"Barotrauma.Networking.ChatMessage"}, function (instance, ptable)
		local chatMessage = ptable["message"] ---@type Barotrauma.Networking.ChatMessage


		-- exit when still in the lobby.
		if not Game.RoundStarted then 
			return
		end

		-- If the host is on a random language, exit!
		if TVAE[TVAE.ServerLang] == nil then
			print("NO active language!")
			return
		end
		
		-- We don't want the player to speak. (Config)
		if chatMessage.Sender.IsPlayer then
			print(chatMessage.Sender.IsPlayer)
			return
		end
		
		
		
		-- Get the Voice ID. If none is found go back to the fallback (1)
		local voiceID = 1
		if chatMessage.sender.CharacterHealth.GetAffliction("tva_voice",false) ~= nil then
			voiceID = chatMessage.sender.CharacterHealth.GetAffliction("tva_voice",false).Strength
		end
		
		local voiceActor = TVAE[TVAE.ServerLang].VoiceActors[voiceID]
		local voiceFileName = "" 
		
		-- Go throug all saved voice lines to find the right one
		for textIdentifier, VoiceLineID in pairs(TVAE[TVAE.ServerLang].VoiceLines) do
			if string.find(chatMessage.text,textIdentifier) ~= nil then
				voiceFileName = TVAE.VoiceLineFileNames[VoiceLineID]
			end
		end

		-- Is the file even laodet/saved?
		if TVAE.LoadedSounds[voiceActor] == nil then return end
		if TVAE.LoadedSounds[voiceActor][voiceFileName] == nil then return end

		local sound = TVAE.LoadedSounds[voiceActor][voiceFileName]
		
		PlaySound(sound,chatMessage.SenderCharacter.WorldPosition)
	end)



	--- Plays sounds TODO: test if it should be muffeld or per Radio
	---@param sound Barotrauma.Sounds.OggSound
	---@param speakerPos Vector2 --WorldPos
	function PlaySound(sound,speakerPos)

		sound.Play(100,100,speakerPos,true)
	end


	---Loads all sound from the voice acting mod TODO: Test if a sound is already loadet dont load it again use the already loadet file
	function LoadAllSounds()
		for _, voiceActor in pairs(TVAE[TVAE.ServerLang].VoiceActors) do
			TVAE.LoadedSounds[voiceActor] = {}

			for _, voiceFileName in ipairs(TVAE.VoiceLineFileNames) do

				local fullVoicePath = TVAE.ModPath .. "/VoiceActing/" .. TVAE.ServerLang .. "/" .. voiceActor .. "/" .. voiceFileName..".ogg"
				if File.Exists(fullVoicePath) then
					local sound = Game.SoundManager.LoadSound(fullVoicePath,false)
					TVAE.LoadedSounds[voiceActor][voiceFileName] = sound
				end
			end

		end
	end

	LoadAllSounds()

end




if SERVER and Game.IsMultiplayer or Game.IsSingleplayer then
	TVAE.ServerLang = GameSettings.CurrentConfig.Language.ToString()

	--- Manages the voice affliction of all characters
	--- @param character Barotrauma.Character
	Hook.add("character.created", "VA_character.created",function (character)
		if AfflictionPrefab.Prefabs["tva_voice"] == nil then
			return
		end
		if character.CharacterHealth.GetAffliction("tva_voice",false) == nil then
			local voicePrefab = AfflictionPrefab.Prefabs["tva_voice"]
			local limb = character.AnimController.MainLimb
			
			local maxVoices = #TVAE[TVAE.ServerLang].VoiceActors
			local rdmVoice = math.random(maxVoices)
			character.CharacterHealth.ApplyAffliction(limb,voicePrefab.Instantiate(rdmVoice))
		end
	end)
end





