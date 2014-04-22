

_G.championData = {
    ["Lux"] = {charName = "Lux", skillshots = {
        ["Light Binding"] =  {name = "Light Binding", spellName = "LuxLightBinding", castDelay = 250, projectileName = "LuxLightBinding_mis.troy", projectileSpeed = 1200, range = 1300, radius = 80, type = "line", danger = 1},
        ["Lux LightStrike Kugel"] = {name = "LuxLightStrikeKugel", spellName = "LuxLightStrikeKugel", castDelay = 250, projectileName = "LuxLightstrike_mis.troy", projectileSpeed = 1400, range = 1100, radius = 275, type = "circular", danger = 0},
        ["Lux Malice Cannon"] =  {name = "Lux Malice Cannon", spellName = "LuxMaliceCannon", castDelay = 1375, projectileName = "Enrageweapon_buf_02.troy", projectileSpeed = math.huge, range = 3500, radius = 190, type = "line", danger = 0},
    }},
    ["Nidalee"] = {charName = "Nidalee", skillshots = {
        ["Javelin Toss"] = {name = "Javelin Toss", spellName = "JavelinToss", castDelay = 125, projectileName = "nidalee_javelinToss_mis.troy", projectileSpeed = 1300, range = 1500, radius = 60, type = "line", danger = 1}
    }},
    ["Kennen"] = {charName = "Kennen", skillshots = {
        ["Thundering Shuriken"] = {name = "Thundering Shuriken", spellName = "KennenShurikenHurlMissile1", castDelay = 180, projectileName = "kennen_ts_mis.troy", projectileSpeed = 1700, range = 1050, radius = 50, type = "line", danger = 0}--could be 4 if you have 2 marks
    }},
    ["Amumu"] = {charName = "Amumu", skillshots = {
        ["Bandage Toss"] = {name = "Bandage Toss", spellName = "BandageToss", castDelay = 250, projectileName = "Bandage_beam.troy", projectileSpeed = 2000, range = 1100, radius = 80, type = "line", evasiondanger = true, danger = 1}
    }},
    ["Lee Sin"] = {charName = "LeeSin", skillshots = {
        ["Sonic Wave"] = {name = "Sonic Wave", spellName = "BlindMonkQOne", castDelay = 250, projectileName = "blindMonk_Q_mis_01.troy", projectileSpeed = 1800, range = 1100, radius = 60+10, type = "line", danger = 1} --if he hit this he will slow you
    }},
    ["Morgana"] = {charName = "Morgana", skillshots = {
        ["Dark Binding Missile"] = {name = "Dark Binding", spellName = "DarkBindingMissile", castDelay = 250, projectileName = "DarkBinding_mis.troy", projectileSpeed = 1200, range = 1300, radius = 80, type = "line", danger = 1},
    }},
    ["Ezreal"] = {charName = "Ezreal", skillshots = {
        ["Mystic Shot"]             = {name = "Mystic Shot",      spellName = "EzrealMysticShot",      castDelay = 250, projectileName = "Ezreal_mysticshot_mis.troy",  projectileSpeed = 2000, range = 1200,  radius = 80,  type = "line", danger = 0},
        ["Essence Flux"]            = {name = "Essence Flux",     spellName = "EzrealEssenceFlux",     castDelay = 250, projectileName = "Ezreal_essenceflux_mis.troy", projectileSpeed = 1500, range = 1050,  radius = 80,  type = "line", danger = 0},
        ["Mystic Shot (Pulsefire)"] = {name = "Mystic Shot",      spellName = "EzrealMysticShotPulse", castDelay = 250, projectileName = "Ezreal_mysticshot_mis.troy",  projectileSpeed = 2000, range = 1200,  radius = 80,  type = "line", danger = 0},
        ["Trueshot Barrage"]        = {name = "Trueshot Barrage", spellName = "EzrealTrueshotBarrage", castDelay = 1000, projectileName = "Ezreal_TrueShot_mis.troy",    projectileSpeed = 2000, range = 20000, radius = 160, type = "line", danger = 0},
    }},
    ["Ahri"] = {charName = "Ahri", skillshots = {
        ["Orb of Deception"] = {name = "Orb of Deception", spellName = "AhriOrbofDeception", castDelay = 250, projectileName = "Ahri_Orb_mis.troy", projectileSpeed = 2500, range = 900, radius = 100, type = "line", danger = 0},
        ["Orb of Deception Back"] = {name = "Orb of Deception Back", spellName = "AhriOrbofDeception!", castDelay = 250+360, projectileName = "Ahri_Orb_mis_02.troy", projectileSpeed = 915, range = 900, radius = 100, type = "line", danger = 0},
        ["Charm"] = {name = "Charm", spellName = "AhriSeduce", castDelay = 250, projectileName = "Ahri_Charm_mis.troy", projectileSpeed = 1000, range = 1000, radius = 60, type = "line", danger = 1}
    }},
    ["Olaf"] = {charName = "Olaf", skillshots = {
        ["Undertow"] = {name = "Undertow", spellName = "OlafAxeThrow", castDelay = 250, projectileName = "olaf_axe_mis.troy", projectileSpeed = 1600, range = 1000, radius = 90, type = "line", danger = 1}
    }},
    ["Leona"] = {charName = "Leona", skillshots = {
        ["Zenith Blade"] = {name = "Zenith Blade", spellName = "LeonaZenithBlade", castDelay = 250, projectileName = "Leona_ZenithBlade_mis.troy", projectileSpeed = 2000, range = 900, radius = 80, type = "line", danger = 1},
        ["Leona Solar Flare"] = {name = "Leona Solar Flare", spellName = "LeonaSolarFlare", castDelay = 250, projectileName = "Leona_SolarFlare_cas.troy", projectileSpeed = 2000, range = 1200, radius = 300, type = "circular", danger = 1}
    }},
    ["Karthus"] = {charName = "Karthus", skillshots = {
        ["Lay Waste"] = {name = "Lay Waste", spellName = "LayWaste", castDelay = 250, projectileName = "LayWaste_point.troy", projectileSpeed = 1750, range = 875, radius = 140, type = "circular", danger = 0}
    }},
    ["Chogath"] = {charName = "Chogath", skillshots = {
        ["Rupture"] = {name = "Rupture", spellName = "Rupture", castDelay = 0, projectileName = "rupture_cas_01_red_team.troy", projectileSpeed = 950, range = 950, radius = 250, type = "circular", danger = 1}
    }},
    ["Blitzcrank"] = {charName = "Blitzcrank", skillshots = {
       ["Rocket Grab"] = {name = "Rocket Grab", spellName = "RocketGrab", castDelay = 250, projectileName = "FistGrab_mis.troy", projectileSpeed = 1800, range = 1050, radius = 70, type = "line", danger = 1}
    }},
    ["Anivia"] = {charName = "Anivia", skillshots = {
        ["Flash Frost"] = {name = "Flash Frost", spellName = "FlashFrostSpell", castDelay = 250, projectileName = "cryo_FlashFrost_mis.troy", projectileSpeed = 850, range = 1100, radius = 110, type = "line", danger = 1}
    }},
    ["Zyra"] = {charName = "Zyra", skillshots = {
      --  ["Deadly Bloom"]   = {name = "Deadly Bloom", spellName = "ZyraQFissure", castDelay = 250, projectileName = "zyra_Q_cas.troy", projectileSpeed = 1400, range = 825, radius = 220, type = "circular", danger = 0},
        ["Grasping Roots"] = {name = "Grasping Roots", spellName = "ZyraGraspingRoots", castDelay = 250, projectileName = "Zyra_E_sequence_impact.troy", projectileSpeed = 1150, range = 1150, radius = 70,  type = "line", danger = 1},
        ["Zyra Passive Death"] = {name = "Zyra Passive", spellName = "zyrapassivedeathmanager", castDelay = 500, projectileName = "zyra_passive_plant_mis.troy", projectileSpeed = 2000, range = 1474, radius = 60,  type = "line", danger = 0},
    }},
    --[[["Gragas"] = {charName = "Gragas", skillshots = {
        ["Barrel Roll"] = {name = "Barrel Roll", spellName = "GragasBarrelRoll", castDelay = 250, projectileName = "gragas_barrelroll_mis.troy", projectileSpeed = 1000, range = 1115, radius = 180, type = "circle", danger = 0},
        ["Barrel Roll Missile"] = {name = "Barrel Roll Missile", spellName = "GragasBarrelRollMissile", castDelay = 0, projectileName = "gragas_barrelroll_mis.troy", projectileSpeed = 1000, range = 1115, radius = 180, type = "circle", danger = 0},
    }},]]
    ["Nautilus"] = {charName = "Nautilus", skillshots = {
        ["Dredge Line"] = {name = "Dredge Line", spellName = "NautilusAnchorDrag", castDelay = 250, projectileName = "Nautilus_Q_mis.troy", projectileSpeed = 2000, range = 1080, radius = 80, type = "line", danger = 1},
    }},
    --[[["Urgot"] = {charName = "Urgot", skillshots = {
        ["Acid Hunter"] = {name = "Acid Hunter", spellName = "UrgotHeatseekingLineMissile", castDelay = 175, projectileName = "UrgotLineMissile_mis.troy", projectileSpeed = 1600, range = 1000, radius = 60, type = "line", danger = 0},
        ["Plasma Grenade"] = {name = "Plasma Grenade", spellName = "UrgotPlasmaGrenade", castDelay = 250, projectileName = "UrgotPlasmaGrenade_mis.troy", projectileSpeed = 1750, range = 900, radius = 250, type = "circular", danger = 1},
    }},]]
    ["Caitlyn"] = {charName = "Caitlyn", skillshots = {
        ["Piltover Peacemaker"] = {name = "Piltover Peacemaker", spellName = "CaitlynPiltoverPeacemaker", castDelay = 625, projectileName = "caitlyn_Q_mis.troy", projectileSpeed = 2200, range = 1300, radius = 90, type = "line", danger = 0},
        ["Caitlyn Entrapment"] = {name = "Caitlyn Entrapment", spellName = "CaitlynEntrapment", castDelay = 150, projectileName = "caitlyn_entrapment_mis.troy", projectileSpeed = 2000, range = 950, radius = 80, type = "line", danger = 1},
    }},
    ["Mundo"] = {charName = "DrMundo", skillshots = {
        ["Infected Cleaver"] = {name = "Infected Cleaver", spellName = "InfectedCleaverMissile", castDelay = 250, projectileName = "dr_mundo_infected_cleaver_mis.troy", projectileSpeed = 2000, range = 1050, radius = 75, type = "line", danger = 1},
    }},
    ["Brand"] = {charName = "Brand", skillshots = {
        ["BrandBlaze"] = {name = "BrandBlaze", spellName = "BrandBlaze", castDelay = 250, projectileName = "BrandBlaze_mis.troy", projectileSpeed = 1600, range = 1100, radius = 80, type = "line", danger = 1},
        ["Pillar of Flame"] = {name = "Pillar of Flame", spellName = "BrandFissure", castDelay = 250, projectileName = "BrandPOF_tar_green.troy", projectileSpeed = 900, range = 1100, radius = 240, type = "circular", danger = 0}
    }},
    ["Corki"] = {charName = "Corki", skillshots = {
        ["Missile Barrage"] = {name = "Missile Barrage", spellName = "MissileBarrage", castDelay = 250, projectileName = "corki_MissleBarrage_mis.troy", projectileSpeed = 2000, range = 1300, radius = 40, type = "line", danger = 0},
        ["Missile Barrage big"] = {name = "Missile Barrage big", spellName = "MissileBarrage!", castDelay = 250, projectileName = "Corki_MissleBarrage_DD_mis.troy", projectileSpeed = 2000, range = 1300, radius = 40, type = "line", danger = 0}
    }},
    ["TwistedFate"] = {charName = "TwistedFate", skillshots = {
        ["Loaded Dice"] = {name = "Loaded Dice", spellName = "WildCards", castDelay = 250, projectileName = "Roulette_mis.troy", projectileSpeed = 1000, range = 1450, radius = 40, type = "line", danger = 0},
    }},
    ["Swain"] = {charName = "Swain", skillshots = {
        ["Nevermove"] = {name = "Nevermove", spellName = "SwainShadowGrasp", castDelay = 250, projectileName = "swain_shadowGrasp_transform.troy", projectileSpeed = 1000, range = 900, radius = 180, type = "circular", danger = 1}
    }},
    ["Cassiopeia"] = {charName = "Cassiopeia", skillshots = {
        ["Noxious Blast"] = {name = "Noxious Blast", spellName = "CassiopeiaNoxiousBlast", castDelay = 250, projectileName = "CassNoxiousSnakePlane_green.troy", projectileSpeed = 500, range = 850, radius = 130, type = "circular", danger = 0},
    }},
    ["Sivir"] = {charName = "Sivir", skillshots = { --hard to measure speed
        ["Boomerang Blade"] = {name = "Boomerang Blade", spellName = "SivirQ", castDelay = 250, projectileName = "Sivir_Base_Q_mis.troy", projectileSpeed = 1350, range = 1175, radius = 101, type = "line", danger = 0},
    }},
    ["Ashe"] = {charName = "Ashe", skillshots = {
        ["Enchanted Arrow"] = {name = "Enchanted Arrow", spellName = "EnchantedCrystalArrow", castDelay = 250, projectileName = "EnchantedCrystalArrow_mis.troy", projectileSpeed = 1600, range = 25000, radius = 130, type = "line", danger = 1},
    }},
    ["KogMaw"] = {charName = "KogMaw", skillshots = {
        ["Living Artillery"] = {name = "Living Artillery", spellName = "KogMawLivingArtillery", castDelay = 250, projectileName = "KogMawLivingArtillery_mis.troy", projectileSpeed = 1050, range = 2200, radius = 225, type = "circular", danger = 0}
    }},
    ["Khazix"] = {charName = "Khazix", skillshots = {
        ["KhazixW"] = {name = "KhazixW", spellName = "KhazixW", castDelay = 250, projectileName = "Khazix_W_mis_enhanced.troy", projectileSpeed = 1700, range = 1025, radius = 70, type = "line", danger = 1},
        ["khazixwlong"] = {name = "khazixwlong", spellName = "khazixwlong", castDelay = 250, projectileName = "Khazix_W_mis_enhanced.troy", projectileSpeed = 1700, range = 1025, radius = 70, type = "line", danger = 1},
    }},
    ["Zed"] = {charName = "Zed", skillshots = {
        ["ZedShuriken"] = {name = "ZedShuriken", spellName = "ZedShuriken", castDelay = 250, projectileName = "Zed_Q_Mis.troy", projectileSpeed = 1700, range = 925, radius = 50, type = "line", danger = 0},
        --["ZedShuriken2"] = {name = "ZedShuriken2", spellName = "ZedShuriken!", castDelay = 250, projectileName = "Zed_Q2_Mis.troy", projectileSpeed = 1700, range = 925, radius = 50, type = "line", danger = 0},
    }},
    ["Leblanc"] = {charName = "Leblanc", skillshots = {
        ["Ethereal Chains"] = {name = "Ethereal Chains", spellName = "LeblancSoulShackle", castDelay = 250, projectileName = "leBlanc_shackle_mis.troy", projectileSpeed = 1600, range = 960, radius = 70, type = "line", danger = 1},
        ["Ethereal Chains R"] = {name = "Ethereal Chains R", spellName = "LeblancSoulShackleM", castDelay = 250, projectileName = "leBlanc_shackle_mis_ult.troy", projectileSpeed = 1600, range = 960, radius = 70, type = "line", danger = 1},
    }},
    ["Draven"] = {charName = "Draven", skillshots = {
        ["Stand Aside"] = {name = "Stand Aside", spellName = "DravenDoubleShot", castDelay = 250, projectileName = "Draven_E_mis.troy", projectileSpeed = 1400, range = 1100, radius = 130, type = "line", danger = 1},
        ["DravenR"] = {name = "DravenR", spellName = "DravenRCast", castDelay = 500, projectileName = "Draven_R_mis!.troy", projectileSpeed = 2000, range = 25000, radius = 160, type = "line", danger = 0},
    }},
    ["Elise"] = {charName = "Elise", skillshots = {
        ["Cocoon"] = {name = "Cocoon", spellName = "EliseHumanE", castDelay = 250, projectileName = "Elise_human_E_mis.troy", projectileSpeed = 1450, range = 1100, radius = 70, type = "line", danger = 1}
    }},
    ["Lulu"] = {charName = "Lulu", skillshots = {
        ["LuluQ"] = {name = "LuluQ", spellName = "LuluQ", castDelay = 250, projectileName = "Lulu_Q_Mis.troy", projectileSpeed = 1450, range = 1000, radius = 50, type = "line", danger = 1}
    }},
    ["Thresh"] = {charName = "Thresh", skillshots = {
        ["ThreshQ"] = {name = "ThreshQ", spellName = "ThreshQ", castDelay = 500, projectileName = "Thresh_Q_whip_beam.troy", projectileSpeed = 1900, range = 1100, radius = 65, type = "line", danger = 1} -- 60 real radius
    }},
    ["Shen"] = {charName = "Shen", skillshots = {
        ["ShadowDash"] = {name = "ShadowDash", spellName = "ShenShadowDash", castDelay = 0, projectileName = "shen_shadowDash_mis.troy", projectileSpeed = 3000, range = 575, radius = 50, type = "line", danger = 1}
    }},
    ["Quinn"] = {charName = "Quinn", skillshots = {
        ["QuinnQ"] = {name = "QuinnQ", spellName = "QuinnQ", castDelay = 250, projectileName = "Quinn_Q_missile.troy", projectileSpeed = 1550, range = 1050, radius = 80, type = "line", danger = 0}
    }},
    ["Veigar"] = {charName = "Veigar", skillshots = {
        ["Dark Matter"] = {name = "VeigarDarkMatter", spellName = "VeigarDarkMatter", castDelay = 250, projectileName = "!", projectileSpeed = 900, range = 900, radius = 225, type = "circular", danger = 0}
    }},
    --[[["Diana"] = {charName = "Diana", skillshots = {
        ["Diana Arc"] = {name = "DianaArc", spellName = "DianaArc", castDelay = 250, projectileName = "Diana_Q_trail.troy", projectileSpeed = 1600, range = 1000, radius = 195, type="circular", danger = 0},
    }},]]
    ["Jayce"] = {charName = "Jayce", skillshots = {
        ["JayceShockBlast"] = {name = "JayceShockBlast", spellName = "JayceShockBlast!", castDelay = 250, projectileName = "JayceOrbLightning.troy", projectileSpeed = 1450, range = 1050, radius = 70, type = "line", danger = 0},
        ["JayceShockBlastCharged"] = {name = "JayceShockBlastCharged", spellName = "JayceShockBlast", castDelay = 250, projectileName = "JayceOrbLightningCharged.troy", projectileSpeed = 2350, range = 1600, radius = 70, type = "line", danger = 0},
    }},
    ["Nami"] = {charName = "Nami", skillshots = {
        ["NamiQ"] = {name = "NamiQ", spellName = "NamiQ", castDelay = 250, projectileName = "Nami_Q_mis.troy", projectileSpeed = 1500, range = 1625, radius = 225, type="circular", danger = 1}
    }},
    ["Fizz"] = {charName = "Fizz", skillshots = {
        ["Fizz Ultimate"] = {name = "Fizz ULT", spellName = "FizzMarinerDoom", castDelay = 250, projectileName = "Fizz_UltimateMissile.troy", projectileSpeed = 1350, range = 1275, radius = 80, type = "line", danger = 1},
    }},
    ["Varus"] = {charName = "Varus", skillshots = {
        ["Varus Q Missile"] = {name = "Varus Q Missile", spellName = "VarusQ!", castDelay = 0, projectileName = "VarusQ_mis.troy", projectileSpeed = 1900, range = 1600, radius = 70, type = "line", danger = 0},
        ["Varus E"] = {name = "Varus E", spellName = "VarusE", castDelay = 250, projectileName = "VarusEMissileLong.troy", projectileSpeed = 1500, range = 925, radius = 275, type = "circular", danger = 1},
        ["VarusR"] = {name = "VarusR", spellName = "VarusR", castDelay = 250, projectileName = "VarusRMissile.troy", projectileSpeed = 1950, range = 1250, radius = 100, type = "line", danger = 1},
    }},
    ["Karma"] = {charName = "Karma", skillshots = {
        ["KarmaQ"] = {name = "KarmaQ", spellName = "KarmaQ", castDelay = 250, projectileName = "TEMP_KarmaQMis.troy", projectileSpeed = 1700, range = 1050, radius = 90, type = "line", danger = 1},
    }},
    ["Aatrox"] = {charName = "Aatrox", skillshots = {--Radius starts from 150 and scales down, so I recommend putting half of it, because you won't dodge pointblank skillshots.
        ["Blade of Torment"] = {name = "Blade of Torment", spellName = "AatroxE", castDelay = 250, projectileName = "AatroxBladeofTorment_mis.troy", projectileSpeed = 1200, range = 1075, radius = 75, type = "line", danger = 1},
        ["AatroxQ"] = {name = "AatroxQ", spellName = "AatroxQ", castDelay = 250, projectileName = "AatroxQ.troy", projectileSpeed = 450, range = 650, radius = 145, type = "circular", danger = 1},
   }},
    ["Xerath"] = {charName = "Xerath", skillshots = {
        ["Xerath Arcanopulse"] =  {name = "Xerath Arcanopulse", spellName = "XerathArcanopulse", castDelay = 1375, projectileName = "Xerath_Beam_cas.troy", projectileSpeed = math.huge, range = 1025, radius = 100, type = "line", danger = 0},
        ["Xerath Arcanopulse Extended"] =  {name = "Xerath Arcanopulse Extended", spellName = "xeratharcanopulseextended", castDelay = 1375, projectileName = "Xerath_Beam_cas.troy", projectileSpeed = math.huge, range = 1625, radius = 100, type = "line", danger = 0},
        ["xeratharcanebarragewrapper"] = {name = "xeratharcanebarragewrapper", spellName = "xeratharcanebarragewrapper", castDelay = 250, projectileName = "Xerath_E_cas_green.troy", projectileSpeed = 300, range = 1100, radius = 265, type = "circular", danger = 0},
        ["xeratharcanebarragewrapperext"] = {name = "xeratharcanebarragewrapperext", spellName = "xeratharcanebarragewrapperext", castDelay = 250, projectileName = "Xerath_E_cas_green.troy", projectileSpeed = 300, range = 1600, radius = 265, type = "circular", danger = 0},
    }},
    ["Lucian"] = {charName = "Lucian", skillshots = {
        ["LucianQ"] =  {name = "LucianQ", spellName = "LucianQ", castDelay = 350, projectileName = "Lucian_Q_laser.troy", projectileSpeed = math.huge, range = 570*2, radius = 65, type = "line", danger = 0},
        ["LucianW"] =  {name = "LucianW", spellName = "LucianW", castDelay = 300, projectileName = "Lucian_W_mis.troy", projectileSpeed = 1600, range = 1000, radius = 80, type = "line", danger = 0},
    }},
    ["Viktor"] = {charName = "Viktor", skillshots = {
        ["ViktorDeathRay1"] =  {name = "ViktorDeathRay1", spellName = "ViktorDeathRay!", castDelay = 500, projectileName = "Viktor_DeathRay_Fix_Mis.troy", projectileSpeed = 780, range = 700, radius = 80, type = "line", danger = 0},
        ["ViktorDeathRay2"] =  {name = "ViktorDeathRay2", spellName = "ViktorDeathRay!", castDelay = 500, projectileName = "Viktor_DeathRay_Fix_Mis_Augmented.troy", projectileSpeed = 780, range = 700, radius = 80, type = "line", danger = 0},
    }},
    ["Rumble"] = {charName = "Rumble", skillshots = {
        ["RumbleGrenade"] =  {name = "RumbleGrenade", spellName = "RumbleGrenade", castDelay = 250, projectileName = "rumble_taze_mis.troy", projectileSpeed = 2000, range = 950, radius = 90, type = "line", danger = 1},
    }},
    ["Nocturne"] = {charName = "Nocturne", skillshots = {
        ["NocturneDuskbringer"] =  {name = "NocturneDuskbringer", spellName = "NocturneDuskbringer", castDelay = 250, projectileName = "NocturneDuskbringer_mis.troy", projectileSpeed = 1400, range = 1125, radius = 60, type = "line", danger = 0},
    }},
    ["Orianna"] = {charName = "Orianna", skillshots = {
        --["OrianaIzunaCommand"] =  {name = "OrianaIzunaCommand", spellName = "OrianaIzunaCommand!", castDelay = 250, projectileName = "Oriana_Ghost_mis.troy", projectileSpeed = 1200, range = 2000, radius = 80, type = "line", danger = 0},
    }},
    ["Ziggs"] = {charName = "Ziggs", skillshots = {
        ["ZiggsQ"] =  {name = "ZiggsQ", spellName = "ZiggsQ", castDelay = 250, projectileName = "ZiggsQ.troy", projectileSpeed = 3000, range = 2000, radius = 155, type = "circular", danger = 0},
        ["ZiggsW"] =  {name = "ZiggsW", spellName = "ZiggsW", castDelay = 250, projectileName = "ZiggsW_mis.troy", projectileSpeed = 3000, range = 2000, radius = 210, type = "circular", danger = 1},
        ["ZiggsE"] =  {name = "ZiggsE", spellName = "ZiggsE", castDelay = 250, projectileName = "ZiggsE_Mis_Large.troy", projectileSpeed = 3000, range = 2000, radius = 235, type = "circular", danger = 1},
    }},
    ["Galio"] = {charName = "Galio", skillshots = {
        ["GalioResoluteSmite"] =  {name = "GalioResoluteSmite", spellName = "GalioResoluteSmite", castDelay = 250, projectileName = "galio_concussiveBlast_mis.troy", projectileSpeed = 850, range = 2000, radius = 200, type = "circular", danger = 1},
    }},
    ["Jinx"] = {charName = "Jinx", skillshots = {
        ["W"] =  {name = "Zap", spellName = "JinxWMissile", castDelay = 600, projectileName = "Jinx_W_mis.troy", projectileSpeed = 3300, range = 1450, radius = 70, type = "line", danger = 1},
        ["R"] =  {name = "Super Mega Death Rocket", spellName = "JinxRWrapper", castDelay = 600, projectileName = "Jinx_R_Mis.troy", projectileSpeed = 2200, range = 20000, radius = 120, type = "line", danger = 0},
    }},         
}
_G.dashchampionData = {
    ["Vayne"] = {slot = _Q, range = 300, delay = 250},
    ["Riven"] = {slot = _E, range = 325, delay = 250},
    ["Ezreal"] = {slot = _E, range = 450, delay = 250},
    ["Caitlyn"] = {slot = _E, range = 400, delay = 250},
    ["Kassadin"] = {slot = _R, range = 700, delay = 250},
    ["Graves"] = {slot = _E, range = 425, delay = 250},
    ["Renekton"] = {slot = _E, range = 450, delay = 250},
    ["Aatrox"] = {slot = _Q, range = 650, delay = 250},
    ["Gragas"] = {slot = _E, range = 600, delay = 250},
    ["Khazix"] = {slot = _E, range = 600, delay = 250},
    ["Lucian"] = {slot = _E, range = 425, delay = 250},
    ["Sejuani"] = {slot = _Q, range = 650, delay = 250},
    ["Shen"] = {slot = _E, range = 575, delay = 250},
    ["Tryndamere"] = {slot = _E, range = 660, delay = 250},
    ["Tristana"] = {slot = _W, range = 900, delay = 250},
    ["Corki"] = {slot = _W, range = 800, delay = 250},
}
_
