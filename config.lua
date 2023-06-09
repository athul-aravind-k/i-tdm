Config = {}

Config.startPed = {
    pos = vector4(-96.88, -960.31, 26.29, 19.86),
    model = "csb_cop",
    hash = 0x9AB35F63,
    targetZone = vector3(-96.88, -960.31, 27.29),
    targetHeading = 19.86,
    minZ = 25.29,
    maxZ = 29.29,
}

Config.pedInvincibleTime = 3 --seconds

Config.reloadSkinEvent =
'illenium-appearance:client:reloadSkin' -- change this event according to the clothing system used.

Config.Clothes = {
    --1 is drawable id and 2 is texture id
    male = {
        ['tshirt_1'] = 15, --shirt number
        ['tshirt_2'] = 0,  --shirt texture
        ['torso_1'] = 61,
        ['torso_2'] = 3,
        ['arms'] = 27,
        ['pants_1'] = 34,
        ['pants_2'] = 0,
        ['shoes_1'] = 25,
        ['shoes_2'] = 0,
        ['helmet_1'] = 115,
        ['helmet_2'] = 0,
        ['bproof_1'] = 0,
        ['bproof_2'] = 0,
        ['mask_1'] = 52,
        ['mask_2'] = 0
    },
    female = {
        ['tshirt_1'] = 14,
        ['tshirt_2'] = 0,
        ['torso_1'] = 54,
        ['torso_2'] = 3,
        ['arms'] = 25,
        ['pants_1'] = 33,
        ['pants_2'] = 0,
        ['shoes_1'] = 25,
        ['shoes_2'] = 0,
        ['helmet_1'] = 114,
        ['helmet_2'] = 0,
        ['bproof_1'] = 0,
        ['bproof_2'] = 0,
        ['mask_1'] = 52,
        ['mask_2'] = 0
    }

}

Config.DMTime = 20    --minutes

Config.DM_Weapons = { --first weapon will be forced in hand
    0xFAD1F1C9,       -- carbine mk2
    0xAF113F99,       -- Advanced Rifle
    0x7F229F94,       -- bullpup rifle
    0x92A27487,       --dagger
    0xC1B3C3D1,       --heavy rifle
    0x22D8FE39,       --ap pistol
    0xEFE7E2DF,       --assault smg
    0x2BE6766B,       --micro smg
    0xEF951FBB,       --Double Barrel Shotgun
    0x1D073A89,       --pump shotgun
}

Config.TDM_maps = {
    ['map1'] = {
        name = 'map1',
        blueZone = {
            zones = {
                vector2(-141.98475646973, -967.61022949219),
                vector2(-159.50726318359, -962.21325683594),
                vector2(-156.33354187012, -953.54205322266),
                vector2(-138.01190185547, -958.60101318359)
            },
            minZ = 269.13491821289,
            maxZ = 269.13537597656,
            name = 'blue-i-tdm-zone'
        },
        redZone = {
            zones = {
                vector2(-175.18975830078, -1014.0055541992),
                vector2(-172.46995544434, -1005.4836425781),
                vector2(-158.72077941895, -1010.2446899414),
                vector2(-162.40629577637, -1018.9063720703)
            },
            minZ = 254.1315612793,
            maxZ = 254.13157653809,
            name = 'red-i-tdm-zone'
        }
    },
    ['map2'] = {
        name = 'map2',
        blueZone = {
            zones = {
                vector2(-454.16821289062, -1063.3009033203),
                vector2(-457.79571533203, -1060.8662109375),
                vector2(-453.81274414062, -1054.8918457031),
                vector2(-450.27285766602, -1057.7987060547)
            },
            minZ = 40.663990020752,
            maxZ = 40.813987731934,
            name = 'blue-i-tdm-zone'
        },
        redZone = {
            zones = {
                vector2(-501.70162963867, -988.39373779297),
                vector2(-494.60110473633, -988.35162353516),
                vector2(-494.42663574219, -994.97198486328),
                vector2(-501.83108520508, -993.88128662109)
            },
            minZ = 40.729976654053,
            maxZ = 40.814037322998,
            name = 'red-i-tdm-zone'
        }
    }
}

Config.DM_maps = {
    ['map1'] = {
        name = 'map1',
        label = 'Military Base',
        image = 'military.png',
        maxMembers = 10,
        zone = {
            zones = {
                vector2(-1962.1414794922, 3389.6958007812),
                vector2(-1953.3248291016, 3389.36328125),
                vector2(-1941.896118164, 3383.5915527344),
                vector2(-1933.1735839844, 3378.7177734375),
                vector2(-1853.9486083984, 3332.0190429688),
                vector2(-1862.6149902344, 3314.5905761718),
                vector2(-1903.5860595704, 3244.8041992188),
                vector2(-1914.8081054688, 3227.1791992188),
                vector2(-1963.8157958984, 3255.3771972656),
                vector2(-1997.3795166016, 3274.7314453125),
                vector2(-2047.707397461, 3303.9045410156),
                vector2(-2050.474609375, 3319.8786621094),
                vector2(-2041.142944336, 3330.1882324218),
                vector2(-2011.791015625, 3353.8227539062),
                vector2(-1980.2680664062, 3380.099609375),
                vector2(-1969.392211914, 3388.6267089844)
            },
            name = "deathmatchzone1",
            minZ = 25,
            maxZ = 50
        },
        spawnpoints = {
            vector4(-1911.42, 3295.26, 33.0, 110.4),
            vector4(-1954.9, 3298.19, 32.96, 53.3),
            vector4(-1936.13, 3334.29, 32.96, 146.46),
            vector4(-1953.86, 3363.97, 32.96, 254.0),
            vector4(-1931.97, 3343.79, 40.23, 130.06),
            vector4(-1979.99, 3357.78, 32.88, 271.62),
            vector4(-1999.26, 3324.51, 32.96, 229.16),
            vector4(-2010.52, 3308.81, 32.94, 247.68),
            vector4(-1981.17, 3304.52, 40.17, 35.93),
            vector4(-1963.57, 3317.64, 32.96, 239.95)
        }
    },
    ['map2'] = {
        name = 'map2',
        label = 'Humane Labs',
        image = 'humane.png',
        maxMembers = 15,
        zone = {
            zones = {
                vector2(3469.8298339844, 3764.4143066406),
                vector2(3533.4379882812, 3752.4094238282),
                vector2(3550.3232421875, 3750.2524414062),
                vector2(3603.1606445312, 3745.4326171875),
                vector2(3610.0256347656, 3742.3681640625),
                vector2(3618.5524902344, 3755.0483398438),
                vector2(3621.2995605468, 3757.1708984375),
                vector2(3632.2653808594, 3749.2458496094),
                vector2(3630.2634277344, 3745.3994140625),
                vector2(3650.7082519532, 3731.5241699218),
                vector2(3616.8254394532, 3695.4096679688),
                vector2(3593.9235839844, 3693.8344726562),
                vector2(3579.8635253906, 3696.3132324218),
                vector2(3567.2468261718, 3702.1049804688),
                vector2(3551.2331542968, 3699.9416503906),
                vector2(3520.8015136718, 3684.4135742188),
                vector2(3496.775390625, 3702.0915527344),
                vector2(3453.38671875, 3708.076171875),
                vector2(3449.3996582032, 3713.70703125),
                vector2(3452.5876464844, 3731.4758300782),
                vector2(3456.0031738282, 3749.9226074218)
            },
            name = "deathmatchzone2",
            minZ = 25,
            maxZ = 50,
        },
        spawnpoints = {
            vector4(3481.35, 3759.18, 31.73, 169.2),
            vector4(3504.42, 3752.26, 31.54, 157.97),
            vector4(3520.83, 3747.91, 32.41, 187.88),
            vector4(3546.08, 3741.23, 36.69, 187.32),
            vector4(3627.59, 3722.97, 35.79, 102.95),
            vector4(3620.99, 3720.41, 40.87, 103.51),
            vector4(3592.83, 3695.77, 36.64, 103.51),
            vector4(3523.7, 3699.1, 33.89, 344.18),
            vector4(3496.51, 3701.69, 33.89, 344.18),
            vector4(3496.51, 3701.69, 33.89, 344.18),
            vector4(3470.75, 3710.55, 36.64, 79.17)
        }
    },
    ['map3'] = {
        name = 'map3',
        label = 'North C',
        image = 'northc.png',
        maxMembers = 15,
        zone = {
            zones = {
                vector2(1492.012084961, 4380.8408203125),
                vector2(1467.2999267578, 4406.2446289062),
                vector2(1433.4523925782, 4430.0654296875),
                vector2(1400.5805664062, 4438.7934570312),
                vector2(1387.2119140625, 4430.5703125),
                vector2(1384.9328613282, 4395.466796875),
                vector2(1352.9473876954, 4396.396484375),
                vector2(1336.576171875, 4399.4018554688),
                vector2(1316.7061767578, 4402.4775390625),
                vector2(1298.5709228516, 4400.3432617188),
                vector2(1281.9223632812, 4384.0932617188),
                vector2(1282.884765625, 4370.64453125),
                vector2(1279.8775634766, 4350.4663085938),
                vector2(1271.5131835938, 4333.0034179688),
                vector2(1283.6901855468, 4315.1494140625),
                vector2(1288.8729248046, 4303.47265625),
                vector2(1301.259399414, 4293.1796875),
                vector2(1311.7042236328, 4289.8662109375),
                vector2(1345.2020263672, 4284.3745117188),
                vector2(1375.818725586, 4270.9946289062),
                vector2(1387.1004638672, 4269.1245117188),
                vector2(1403.4519042968, 4273.25390625),
                vector2(1406.8850097656, 4303.599609375),
                vector2(1420.6881103516, 4328.7622070312),
                vector2(1445.5721435546, 4333.3325195312),
                vector2(1465.146850586, 4346.5600585938)
            },
            name = "deathmatchzone3",
            minZ = 31,
            maxZ = 62,
        },
        spawnpoints = {
            vector4(1441.91, 4370.58, 43.83, 130.93),
            vector4(1386.82, 4393.7, 44.25, 228.98),
            vector4(1334.16, 4396.69, 44.59, 108.7),
            vector4(1310.5, 4386.39, 41.19, 250.26),
            vector4(1293.5, 4343.57, 41.32, 252.79),
            vector4(1293.3, 4322.85, 38.31, 299.49),
            vector4(1304.14, 4312.79, 37.73, 314.5),
            vector4(1317.4, 4303.77, 38.03, 2.46),
            vector4(1340.17, 4319.72, 37.98, 345.24),
            vector4(1363.64, 4340.0, 39.7, 63.06),
            vector4(1373.13, 4355.75, 44.36, 16.41),
            vector4(1363.47, 4359.1, 44.5, 279.59),
            vector4(1337.75, 4361.57, 44.36, 254.67),
            vector4(1314.77, 4375.55, 41.33, 223.76)
        }
    },
    ['map4'] = {
        name = 'map4',
        label = 'Sandy Shores',
        image = 'sandy.png',
        maxMembers = 15,
        zone = {
            zones = {
                vector2(1544.9641113282, 3748.0795898438),
                vector2(1595.6434326172, 3674.7290039062),
                vector2(1474.8540039062, 3620.2680664062),
                vector2(1444.9539794922, 3700.7358398438)
            },
            name = "deathmatchzone4",
            minZ = 25,
            maxZ = 50,
        },
        spawnpoints = {
            vector4(1577.17, 3684.28, 34.67, 179.74),
            vector4(1555.0, 3663.73, 34.84, 39.9),
            vector4(1525.1, 3653.05, 35.22, 21.2),
            vector4(1494.92, 3635.72, 34.69, 311.3),
            vector4(1472.55, 3679.74, 34.12, 205.87),
            vector4(1497.17, 3675.07, 34.48, 166.13),
            vector4(1506.29, 3693.74, 39.06, 286.74),
            vector4(1516.99, 3706.61, 34.42, 169.62),
            vector4(1528.04, 3715.44, 34.67, 185.0),
            vector4(1538.68, 3706.54, 34.69, 120.37),
            vector4(1519.95, 3687.16, 34.75, 223.76),
            vector4(1517.64, 3655.97, 35.12, 73.1),
        }
    },
    ['map5'] = {
        name = 'map5',
        label = 'Funfair Amusements',
        image = 'funfair.png',
        maxMembers = 15,
        zone = {
            zones = {
                vector2(-1735.205078125, -1122.8074951172),
                vector2(-1646.2779541016, -1016.0761108398),
                vector2(-1594.2342529296, -1056.6103515625),
                vector2(-1590.1334228516, -1060.163696289),
                vector2(-1631.7109375, -1109.5383300782),
                vector2(-1661.2723388672, -1148.4989013672),
                vector2(-1678.9559326172, -1169.8562011718)
            },
            name = "deathmatchzone5",
            minZ = 9,
            maxZ = 25,
        },
        spawnpoints = {
            vector4(-1697.38, -1129.61, 13.15, 281.31),
            vector4(-1691.76, -1108.19, 13.15, 280.0),
            vector4(-1668.07, -1076.04, 13.15, 226.52),
            vector4(-1634.84, -1090.07, 13.03, 49.8),
            vector4(-1668.73, -1104.05, 18.3, 234.91),
            vector4(-1648.67, -1113.74, 13.02, 113.06),
            vector4(-1669.0, -1144.51, 13.02, 36.34),
            vector4(-1700.65, -1109.92, 20.52, 287.85),
            vector4(-1694.57, -1097.62, 13.15, 228.04),
            vector4(-1633.59, -1045.25, 13.15, 197.25),
            vector4(-1654.22, -1082.53, 18.51, 195.33),
            vector4(-1615.65, -1076.41, 13.02, 85.98),
        }
    },
    ['map6'] = {
        name = 'map6',
        label = 'Junkyard',
        image = 'junkyard.png',
        maxMembers = 15,
        zone = {
            zones = {
                vector2(-411.13906860352, -1705.920288086),
                vector2(-417.70629882812, -1724.5350341796),
                vector2(-429.31414794922, -1753.7934570312),
                vector2(-433.82369995118, -1758.271850586),
                vector2(-469.84210205078, -1767.8957519532),
                vector2(-503.39547729492, -1763.4464111328),
                vector2(-521.4566040039, -1755.4777832032),
                vector2(-561.34765625, -1727.2709960938),
                vector2(-568.35998535156, -1722.0959472656),
                vector2(-523.67797851562, -1695.6643066406),
                vector2(-491.1974182129, -1678.8673095704),
                vector2(-465.88333129882, -1685.6518554688),
                vector2(-430.4506225586, -1677.390258789),
                vector2(-417.47756958008, -1694.5217285156)
            },
            name = "deathmatchzone6",
            minZ = 10,
            maxZ = 25,
        },
        spawnpoints = {
            vector4(-419.63, -1706.91, 19.34, 84.72),
            vector4(-434.91, -1724.91, 18.86, 339.15),
            vector4(-450.51, -1726.2, 18.69, 356.72),
            vector4(-473.48, -1739.38, 17.53, 104.8),
            vector4(-495.9, -1756.36, 18.4, 327.07),
            vector4(-511.21, -1737.87, 19.25, 317.67),
            vector4(-498.87, -1710.36, 19.37, 141.19),
            vector4(-469.07, -1718.64, 18.69, 286.71),
            vector4(-473.14, -1693.05, 18.93, 262.1),
            vector4(-449.15, -1691.04, 18.96, 175.91),
            vector4(-444.6, -1712.82, 18.72, 6.09),
        }
    },
}
