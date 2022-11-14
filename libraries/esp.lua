-- start
local isSynV3 = worldtoscreen ~= nil;

-- localization
local game, workspace, table, math, cframe, vector2, vector3, color3, instance, drawing, raycastParams = game, workspace, table, math, CFrame, Vector2, Vector3, Color3, Instance, Drawing, RaycastParams;
local getService, isA, findFirstChild, getChildren = game.GetService, game.IsA, game.FindFirstChild, game.GetChildren;
local raycast = workspace.Raycast;
local tableInsert = table.insert;
local mathFloor, mathSin, mathCos, mathRad, mathTan, mathAtan2 = math.floor, math.sin, math.cos, math.rad, math.tan, math.atan2;
local cframeNew, vector2New, vector3New = cframe.new, vector2.new, vector3.new;
local color3New = color3.new;
local instanceNew, drawingNew = instance.new, drawing.new;
local raycastParamsNew = raycastParams.new;

-- services
local players = getService(game, "Players");
local coreGui = getService(game, "CoreGui");
local runService = getService(game, "RunService");

-- cache
local localPlayer = players.LocalPlayer;
local currentCamera = workspace.CurrentCamera;
local filterType = Enum.RaycastFilterType.Blacklist;
local lastScale, lastFov;

-- function localization
local ccWorldToViewportPoint = currentCamera.WorldToViewportPoint;
local pointToObjectSpace = cframeNew().PointToObjectSpace;

-- support functions
local function worldToViewportPoint(position)
    if (isSynV3) then
        local screenPosition = worldtoscreen({ position })[1];
        local depth = screenPosition.Z;
        return vector2New(screenPosition.X, screenPosition.Y), depth > 0, depth;
    end

    local screenPosition, onScreen = ccWorldToViewportPoint(currentCamera, position);
    return vector2New(screenPosition.X, screenPosition.Y), onScreen, screenPosition.Z;
end

local function isDrawing(type)
    return type == "Line" or type == "Text" or type == "Image" or type == "Circle" or type == "Square" or type == "Quad" or type == "Triangle"
end

local function create(type, properties)
    local drawing = isDrawing(type);
    local object = drawing and drawingNew(type) or instanceNew(type);

    if (properties) then
        for property, value in next, properties do
            object[property] = value;
        end
    end

    return object;
end

local function rotateVector(vector, angle)
    local c = mathCos(mathRad(angle));
    local s = mathSin(mathRad(angle));
    return vector2New(c * vector.X - s * vector.Y, s * vector.X + c * vector.Y);
end

local function roundVector(vector)
    return vector2New(mathFloor(vector.X), mathFloor(vector.Y));
end

-- main module
local library = {
    _connections = {},
    _espCache = {},
    _chamsCache = {},
    _screenGui = create("ScreenGui", {
        Parent = coreGui,
    }),
    settings = {
        -- settings
        enabled = false,
        visibleOnly = false,
        teamCheck = true,
        boxStaticWidth = 4,
        boxStaticHeight = 5,

        -- options
        chams = false,
        chamsInlineColor = color3New(0.5, 0.7, 1),
        chamsInlineTransparency = 0.5,
        chamsOutlineColor = color3New(0.5, 0.7, 1),
        chamsOutlineTransparency = 0.7,
        names = false,
        nameColor = color3New(1, 1, 1),
        teams = false,
        teamColor = color3New(1, 1, 1),
        teamUseTeamColor = false,
        boxes = false,
        boxColor = color3New(1, 0, 0),
        boxType = "Static",
        boxFill = false,
        boxFillColor = color3New(1, 0, 0),
        boxFillTransparency = 0.5,
        healthbar = false,
        healthbarColor = color3New(0, 1, 0),
        healthbarSize = 1,
        healthtext = false,
        healthtextColor = color3New(1, 1, 1),
        distance = false,
        distanceColor = color3New(1, 1, 1),
        weapon = false,
        weaponColor = color3New(1, 1, 1),
        oofArrows = false,
        oofArrowsColor = color3New(0.8, 0.2, 0.2),
        oofArrowsAlpha = 1,
        oofArrowsSize = 30,
        oofArrowsRadius = 150,
    }
};
library.__index = library;

-- support functions
function library:AddConnection(signal, callback)
    local connection = signal:Connect(callback);
    tableInsert(self._connections, connection);
    return connection;
end

-- main functions
function library._getTeam(player)
    return player.Team;
end

function library._getCharacter(player)
    local character = player.Character;
    return character, character and findFirstChild(player.Character, "HumanoidRootPart");
end

function library._getPlayerFromCharacter(character)
    return players:GetPlayerFromCharacter(character);
end

function library._getHealth(player, character)
    local humanoid = findFirstChild(character, "Humanoid");

    if (humanoid) then
        return humanoid.Health, humanoid.MaxHealth;
    end

    return 100, 100;
end

function library._getWeapon(player, character)
    return "Hands"
end

function library._visibleCheck(character, origin, target)
    local params = raycastParamsNew();

    params.FilterDescendantsInstances = { library._getCharacter(localPlayer), character, currentCamera };
    params.FilterType = filterType;
    params.IgnoreWater = true;

    return raycast(workspace, origin, target - origin, params) == nil;
end

function library._getScaleFactor(fov, depth)
    if (lastFov ~= fov) then
        lastScale = mathTan(mathRad(fov * 0.5)) * 2;
        lastFov = fov;
    end

    return 1 / (lastScale * depth) * 1000;
end

function library._getBoxSize(character)
    if (library.settings.boxType == "Static" or not isA(character, "Model")) then
        return vector2New(library.settings.boxStaticWidth, library.settings.boxStaticHeight);
    end

    local _, size = character:GetBoundingBox();
    return size;
end

function library._getBoxData(character, depth)
    local size = library._getBoxSize(character);
    local scaleFactor = library._getScaleFactor(currentCamera.FieldOfView, depth);
    return mathFloor(size.X * scaleFactor), mathFloor(size.Y * scaleFactor);
end

function library._addEsp(player)
    if (player == localPlayer) then
        return
    end

    local font = isSynV3 and 1 or 2;

    local objects = {
        name = create("Text", {
            Color = library.settings.nameColor,
            Text = player.Name,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        }),
        team = create("Text", {
            Color = library.settings.teamColor,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        }),
        boxOutline = create("Square", {
            Color = color3New(),
            Transparency = 0.5,
            Thickness = 3,
            Filled = false
        }),
        box = create("Square", {
            Color = library.settings.boxColor,
            Thickness = 1,
            Filled = false
        }),
        boxFill = create("Square", {
            Color = library.settings.boxFillColor,
            Transparency = library.settings.boxFillTransparency,
            Thickness = 1,
            Filled = true
        }),
        healthbarOutline = create("Square", {
            Color = color3New(),
            Transparency = 0.5,
            Thickness = 3,
            Filled = true
        }),
        healthbar = create("Square", {
            Color = library.settings.healthbarColor,
            Thickness = 1,
            Filled = true
        }),
        healthtext = create("Text", {
            Color = library.settings.healthtextColor,
            Size = 13,
            Center = false,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        }),
        distance = create("Text", {
            Color = library.settings.distanceColor,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        }),
        weapon = create("Text", {
            Color = library.settings.weaponColor,
            Size = 13,
            Center = true,
            Outline = true,
            OutlineColor = color3New(),
            Font = font
        }),
        arrow = create("Triangle", {
            Color = library.settings.oofArrowsColor,
            Thickness = 1,
            Filled = true
        })
    };

    library._espCache[player] = objects;
end

function library._removeEsp(player)
    local espCache = library._espCache[player];

    if (espCache) then
        for index, object in next, espCache do
            object:Remove();
            espCache[index] = nil;
        end
    end
end

function library._addChams(character)
    local player = library._getPlayerFromCharacter(character);

    if (player == localPlayer) then
        return
    end

    local objects = {};

    for _, part in next, getChildren(character) do
        if (isA(part, "BasePart")) then
            objects[part] = {
                inline = create("BoxHandleAdornment", {
                    Parent = library._screenGui,
                    Size = part.Size + vector3New(0.05, 0.05, 0.05),
                    Adornee = part,
                    Color3 = library.settings.chamsInlineColor,
                    Transparency = library.settings.chamsInlineTransparency,
                    AlwaysOnTop = true
                }),
                outline = create("BoxHandleAdornment", {
                    Parent = library._screenGui,
                    Size = part.Size + vector3New(0.15, 0.15, 0.15),
                    Adornee = part,
                    Color3 = library.settings.chamsOutlineColor,
                    Transparency = library.settings.chamsOutlineTransparency,
                })
            };
        end
    end

    library._chamsCache[character] = objects;
end

function library._removeChams(character)
    local chamsCache = library._chamsCache[character];

    if (chamsCache) then
        for _, part in next, chamsCache do
            part.inline:Destroy();
            part.outline:Destroy();
        end
    end
end

function library:Load(renderPriority)
    for _, player in next, players:GetPlayers() do
        self._addEsp(player);
    end

    self:AddConnection(players.PlayerAdded, function(player)
        self._addEsp(player);
    end);

    self:AddConnection(players.PlayerRemoving, function(player)
        self._removeEsp(player);
    end);

    local priority = renderPriority or Enum.RenderPriority.Camera.Value + 1;

    runService:BindToRenderStep("main_esp_rendering", priority, function()
        for player, cache in next, self._espCache do
            local team = self._getTeam(player);
            local character, root = self._getCharacter(player);
            local enabled = self.settings.enabled;

            if (self.settings.teamCheck and team == self._getTeam(localPlayer)) then
                enabled = false
            end

            if (enabled and character and root) then
                local enabled = true;
                local cameraCFrame = currentCamera.CFrame;
                local cameraPosition, rootPosition = cameraCFrame.Position, root.Position;

                if (self.settings.visibleOnly and not self._visibleCheck(character, cameraPosition, rootPosition)) then
                    enabled = false;
                end

                if (enabled) then
                    local torsoPosition, onScreen, depth = worldToViewportPoint(rootPosition);

                    local x, y = torsoPosition.X, torsoPosition.Y;
                    local width, height = self._getBoxData(character, depth);
                    local boxSize = vector2New(width, height);
                    local boxPosition = vector2New(mathFloor(x - width * 0.5), mathFloor(y - height * 0.5));

                    local health, maxHealth = self._getHealth(player, character);
                    local healthbarSize = vector2New(self.settings.healthbarSize, height);
                    local healthbarPosition = boxPosition - vector2New(healthbarSize.X + 3, 0);

                    local objectSpace = pointToObjectSpace(cameraCFrame, rootPosition);
                    local angle = mathAtan2(objectSpace.Z, objectSpace.X);
                    local direction = vector2New(mathCos(angle), mathSin(angle));
                    local viewportSize = currentCamera.ViewportSize;
                    local position = vector2New(viewportSize.X * 0.5, viewportSize.Y * 0.5) + direction * self.settings.oofArrowsRadius;

                    cache.arrow.Visible = not onScreen and self.settings.oofArrows;
                    cache.arrow.PointA = roundVector(position);
                    cache.arrow.PointB = roundVector(position - rotateVector(direction, 30) * self.settings.oofArrowsSize);
                    cache.arrow.PointC = roundVector(position - rotateVector(direction, -30) * self.settings.oofArrowsSize);

                    cache.name.Visible = onScreen and self.settings.names;
                    cache.name.Color = self.settings.nameColor;
                    cache.name.Position = vector2New(x, boxPosition.Y - cache.name.TextBounds.Y - 2);

                    cache.team.Visible = onScreen and self.settings.teams;
                    cache.team.Text = team ~= nil and team.Name or "No Team";
                    cache.team.Color = (self.settings.teamUseTeamColor and team ~= nil) and team.TeamColor.Color or self.settings.teamColor;
                    cache.team.Position = vector2New(x + width * 0.5 + cache.team.TextBounds.X * 0.5 + 2, boxPosition.Y - 2);

                    cache.box.Visible = onScreen and self.settings.boxes;
                    cache.box.Size = boxSize;
                    cache.box.Position = boxPosition;

                    cache.boxOutline.Visible = cache.box.Visible;
                    cache.boxOutline.Size = boxSize;
                    cache.boxOutline.Position = boxPosition;

                    cache.boxFill.Visible = onScreen and self.settings.boxFill;
                    cache.boxFill.Size = boxSize;
                    cache.boxFill.Position = boxPosition;

                    cache.healthbar.Visible = onScreen and self.settings.healthbar;
                    cache.healthbar.Size = vector2New(healthbarSize.X, -(height * (health / maxHealth)));
                    cache.healthbar.Position = healthbarPosition + vector2New(0, height);

                    cache.healthbarOutline.Visible = cache.healthbar.Visible;
                    cache.healthbarOutline.Size = healthbarSize + vector2New(2, 2);
                    cache.healthbarOutline.Position = healthbarPosition - vector2New(1, 1);

                    cache.healthtext.Visible = onScreen and self.settings.distance;
                    cache.healthtext.Text = mathFloor(health) .. " HP";
                    cache.healthtext.Color = self.settings.healthtextColor;
                    cache.healthtext.Position = healthbarPosition - vector2New(cache.healthtext.TextBounds.X + 2, -(height * (1 - (health / maxHealth))) + 2);

                    cache.distance.Visible = onScreen and self.settings.distance;
                    cache.distance.Text = mathFloor((cameraPosition - rootPosition).Magnitude) .. " Studs";
                    cache.distance.Color = self.settings.distanceColor;
                    cache.distance.Position = vector2New(x, boxPosition.Y + height);

                    cache.weapon.Visible = onScreen and self.settings.weapon;
                    cache.weapon.Text = library._getWeapon(player, character);
                    cache.weapon.Color = self.settings.weaponColor;
                    cache.weapon.Position = vector2New(x, boxPosition.Y + height + (cache.distance.Visible and cache.distance.TextBounds.Y + 1 or 0));
                else
                    for _, object in next, cache do
                        object.Visible = false;
                    end
                end
            else
                for _, object in next, cache do
                    object.Visible = false;
                end
            end
        end
    end);

    runService:BindToRenderStep("main_chams_rendering", priority + 1, function()
    end);
end

function library:Unload()
    runService:UnbindFromRenderStep("main_esp_rendering");
    runService:UnbindFromRenderStep("main_chams_rendering");

    self._screenGui:Destroy();

    for index, connection in next, self._connections do
        connection:Disconnect();
        self._connections[index] = nil;
    end

    for _, player in next, players:GetPlayers() do
        self._removeEsp(player);
    end

    for _, cache in next, library._chamsCache do
        for _, part in next, cache do
            part.inline:Destroy();
            part.outline:Destroy();
        end
    end
end

return setmetatable({}, library);