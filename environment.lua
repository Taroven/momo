local util = util require "util"
local fs = fs or require"filesystem"

local environment = {}

-- pulled from MOAIEnvironment.h
local variables = {
	'appDisplayName',
	'appID',
	'appVersion',
	'cacheDirectory',
	'carrierISOCountryCode',
	'carrierMobileCountryCode',
	'carrierMobileNetworkCode',
	'carrierName',
	'connectionType',
	'countryCode',
	'cpuabi',
	'devBrand',
	'devName',
	'devManufacturer',
	'devModel',
	'devPlatform',
	'devProduct',
	'documentDirectory',
	'iosRetinaDisplay',
	'languageCode',
	'numProcessors',
	'osBrand',
	'osVersion',
	'resourceDirectory',
	'screenDpi',
	'verticalResolution',
	'horizontalResolution',
	'udid',
	'openUdid',
}

-- Figure out if we have an active net connection
environment.ConnectionStatus = function (self)
	local brand = MOAIEnvironment.osBrand
	local c = MOAIEnvironment.connectionType
	if brand == "Android" then -- if we get nil here (which should be rare), we'll assume connected
		return (type(t.connectionType)=='number' and t.connectionType > 0 or (t.connectionType == nil) and true)
	end -- assume anyone else is connected, less painful that way until able to test
	return true
end

-- A step beyond active connection: Do we have enough connectivity to download a file?
-- Probably a good idea to check this before any complex web ops.
environment.ConnectionValid = function (self)
	local connected = self:ConnectionStatus()
	local valid
	if connected then
		-- FIXME: Use web module to download a tiny file from a static source and check response code
	end
	return connected, valid
end

-- Populates self.environment with some useful information and returns the environment table.
-- Checking MOAIEnvironment directly is still quite fine, this just sets some defaults in case some info can't be obtained.
environment.GetEnvironment = function (self)
	--print(1,'GetEnvironment')
	local t = self.environment or {}
	for _,v in ipairs(variables) do
		t[v] = MOAIEnvironment[v]
	end
	
	t.connected = self:ConnectionStatus()

	if type(t.verticalResolution)~='number' then
		t.verticalResolution = t.osBrand == "Android" and 540 or 240
	end

	if type(t.horizontalResolution)~='number' then
		t.horizontalResolution = t.osBrand == "Android" and 960 or 320
	end
	
	self.environment = t
	return self.environment
end

return environment