-- =============================================================================
-- CUI Ingame Text - [French] by [G.] 3/1/2019
-- =============================================================================

INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text) VALUES

-- =============================================================================
-- City Panel
("fr_FR", "LOC_CUI_CP_MANAGE_CITIZENS_TILES",                                   "Gestion des citoyens"),

-- =============================================================================
-- City States Panel
("fr_FR", "LOC_CUI_CSP_ENVOYS_SUZERAIN",                                        "Émissaires envoyés : {1_num}, Suzerain de : {2_num}"),

-- =============================================================================
-- Deal Panel
("fr_FR", "LOC_CUI_DP_GOLD_EDIT_TOOLTIP",                                       "Clique gauche pour ajouter ; clique droit pour soustraire"),
("fr_FR", "LOC_CUI_DP_THEY_HAVE_ITEM_TOOLTIP",                                  "Ils possèdent déjà"),
("fr_FR", "LOC_CUI_DP_WE_HAVE_ITEM_TOOLTIP",                                    "Nous possédons déjà"),

-- =============================================================================
-- Diplomatic Banner
("fr_FR", "LOC_CUI_DB_CITY",                                                    "Villes : {1_num}"),
("fr_FR", "LOC_CUI_DB_RELIGION",                                                "Religion fondée : {1_name}"),
("fr_FR", "LOC_CUI_DB_NONE",                                                    "Aucune"),
("fr_FR", "LOC_CUI_DB_PEACE_DEAL_AVAILABLE",                                    "[Traité de paix disponible]"),
("fr_FR", "LOC_CUI_DB_PEACE_DEAL_NOT_AVAILABLE",                                "[Traité de paix : {1_Remaining}[ICON_TURN]]"),
("fr_FR", "LOC_CUI_DB_RELATIONSHIP",                                            "Relations : {1_Relationship}"),
("fr_FR", "LOC_CUI_DB_GRIEVANCES_NONE",                                         "Aucun grief"),
("fr_FR", "LOC_CUI_DB_GRIEVANCES",                                              "Griefs : {1_Grievances}"),
("fr_FR", "LOC_CUI_DB_THEY_CAN_OFFER",                                          "Ils peuvent offrir :"),
("fr_FR", "LOC_CUI_DB_WE_CAN_OFFER",                                            "Nous pouvons offrir :"),
("fr_FR", "LOC_CUI_DB_GOLD",                                                    "Or :"),
("fr_FR", "LOC_CUI_DB_GOLD_AND_FAVOR",                                          "Or et faveurs diplomatiques :"),
("fr_FR", "LOC_CUI_DB_SCORE_AND_YIELDS",                                        "Score et rendements :"),
("fr_FR", "LOC_CUI_DB_MARS_PROJECT",                                            "Colonie sur Mars : {1_progress}  {2_progress}  {3_progress}"),
("fr_FR", "LOC_CUI_DB_EXOPLANET_EXPEDITION",                                    "Expédition exoplanètaire : {1_progress}{2_progress}{3_progress}{4_progress}{5_progress}"),
("fr_FR", "LOC_CUI_DB_VISITING_TOURISTS",                                       "Touristes étrangers : {1_num} / {2_total}"),
("fr_FR", "LOC_CUI_DB_CAPITALS_CAPTURED",                                       "Capitales capturées : {1_num}"),
("fr_FR", "LOC_CUI_DB_CIVS_CONVERTED",                                          "Civilisations converties : {1_num} / {2_total}"),
("fr_FR", "LOC_CUI_DB_DIPLOMATIC_POINT",                                        "Points de victoire diplomatique : {1_num} / {2_total}"),

-- =============================================================================
-- Espionage Panel
("fr_FR", "LOC_CUI_EP_FILTER_ALL",                                              "Toutes"),
("fr_FR", "LOC_CUI_EP_FILTER_SHOW_CITIES",                                      "Montrer les villes"),

-- =============================================================================
-- Minimap Panel
("fr_FR", "LOC_CUI_MP_SHOW_DISTRICTS_TOOLTIP",                                  "Afficher les icônes des quartiers"),
("fr_FR", "LOC_CUI_MP_SHOW_WONDERS_TOOLTIP",                                    "Afficher les icônes des merveilles"),
("fr_FR", "LOC_CUI_MP_AUTONAMING",                                              "Noms auto."),
("fr_FR", "LOC_CUI_MP_AUTONAMING_TOOLTIP",                                      "Marqueurs nommés automatiquement"),
("fr_FR", "LOC_CUI_MO_SHOW_IMPROVED_RESOURCES",                                 "Afficher icônes ressources aménagées"),
("fr_FR", "LOC_CUI_MO_TOGGLE_IMPROVED_TOOLTIP",                                 "Afficher les icônes des ressources aménagées"),
("fr_FR", "LOC_CUI_MO_SHOW_UNIT_FLAGS",                                         "Afficher les icônes des unités"),
("fr_FR", "LOC_CUI_MP_TOGGLE_UNIT_FLAGS_TOOLTIP",                               "Afficher les icônes des unités"),
("fr_FR", "LOC_CUI_MO_SHOW_CITY_BANNERS",                                       "Afficher bannières (noms) des villes"),
("fr_FR", "LOC_CUI_MP_TOGGLE_CITY_BANNERS_TOOLTIP",                             "Afficher les bannières (noms) des villes"),
("fr_FR", "LOC_CUI_MO_SHOW_TRADERS",                                            "Afficher les négociants"),
("fr_FR", "LOC_CUI_MP_TOGGLE_TRADERS_TOOLTIP",                                  "Afficher les icônes des négociants"),
("fr_FR", "LOC_CUI_MO_SHOW_RELIGIONS",                                          "Show Religion Units"),
("fr_FR", "LOC_CUI_MP_TOGGLE_RELIGIONS_TOOLTIP",                                "Toggle Religion Flags"),

-- =============================================================================
-- Report Screen
("fr_FR", "LOC_CUI_RS_SHOW_CITY_DETAILS",                                       "Afficher les détails de la ville"),
("fr_FR", "LOC_CUI_RS_BUILDING_NUMBER",                                         "Nombre de bâtiments"),
("fr_FR", "LOC_CUI_RS_TOTALS",                                                  "Total : {1_num}"),
("fr_FR", "LOC_CUI_RS_DEALS_OUTGOING",                                          "Sortant"),
("fr_FR", "LOC_CUI_RS_DEALS_INCOMING",                                          "Entrant"),

-- =============================================================================
-- Top Panel
("fr_FR", "LOC_CUI_SI_SPY_AVAILABLE",                                           "{1_num} [ICON_Unit] {1_num : plural 1?Espion disponible; other?Espions disponibles;}"),
("fr_FR", "LOC_CUI_SI_SPY_CAPACITY",                                            "{1_num} [ICON_Unit] {1_num : plural 1?Espion possible; other?Espions possibles;}"),

-- =============================================================================
-- World Tracker
("fr_FR", "LOC_CUI_WT_REMINDER",                                                "Rappel"),
("fr_FR", "LOC_CUI_WT_TECH_REMINDER_TOOLTIP",                                   "La couleur de fond passe au vert lorsque la technologie peut être terminée en obtenant un eureka."),
("fr_FR", "LOC_CUI_WT_CIVIC_REMINDER_TOOLTIP",                                  "La couleur d'arrière-plan passe au vert lorsque le dogme peut être terminé en obtenant une inspiration."),
("fr_FR", "LOC_CUI_WT_GOSSIP_LOG",                                              "Registre des rumeurs"),
("fr_FR", "LOC_CUI_WT_COMBAT_LOG",                                              "Registre des combats"),
("fr_FR", "LOC_CUI_WT_PERSIST",                                                 "Laisser"),
("fr_FR", "LOC_CUI_WT_GLOG_PERSIST_TOOLTIP",                                    "N'effacez pas le journal des rumeurs entre les tours."),
("fr_FR", "LOC_CUI_WT_CLOG_PERSIST_TOOLTIP",                                    "N'effacez pas le journal des combats entre les tours."),

-- =============================================================================
-- Trade Panel
("fr_FR", "LOC_CUI_TP_SORT_BY_FOOD_TOOLTIP",                                    "Trier par [ICON_Food]Nourriture."),
("fr_FR", "LOC_CUI_TP_SORT_BY_PRODUCTION_TOOLTIP",                              "Trier par [ICON_Production]Production."),
("fr_FR", "LOC_CUI_TP_SORT_BY_GOLD_TOOLTIP",                                    "Trier par [ICON_Gold]Or."),
("fr_FR", "LOC_CUI_TP_SORT_BY_SCIENCE_TOOLTIP",                                 "Trier par [ICON_Science]Science."),
("fr_FR", "LOC_CUI_TP_SORT_BY_CULTURE_TOOLTIP",                                 "Trier par [ICON_Culture]Culture."),
("fr_FR", "LOC_CUI_TP_SORT_BY_FAITH_TOOLTIP",                                   "Trier par [ICON_Faith]Foi."),
("fr_FR", "LOC_CUI_TP_SORT_BY_TURNS_REMAINING_TOOLTIP",                         "Trier par [ICON_Turn]Tours nécessaires pour compléter la route."),
("fr_FR", "LOC_CUI_TP_REPEAT",                                                  "Répéter"),
("fr_FR", "LOC_CUI_TP_REPEAT_TOOLTIP",                                          "Répéter la route commerciale indéfiniment."),
("fr_FR", "LOC_CUI_TP_SELECT_A_CITY",                                           "Choisir une nouvelle ville d'origine."),

-- =============================================================================
-- Espionage Panel
("fr_FR", "LOC_CUI_EP_SHOW_CITYS",                                              "Montrer les villes"),
("fr_FR", "LOC_CUI_EP_SIPHON_FUNDS",                                            "Gain de ({1_GoldString}) de rendement en Or."),

-- =============================================================================
-- Production Panel
("fr_FR", "LOC_CUI_PP_QUEUE_DEFAULT",                                           "Utiliser par défaut la liste de production."),

-- =============================================================================
-- Great Works
("fr_FR", "LOC_CUI_GW_SORT_BY_CITY",                                            "Trier par Ville"),
("fr_FR", "LOC_CUI_GW_SORT_BY_BUILDING",                                        "Trier par Bâtiment"),
("fr_FR", "LOC_CUI_GW_THEMING_HELPER",                                          "Aide thématisation"),
("fr_FR", "LOC_CUI_GW_THEMING_HELPER_TOOLTIP",                                  "Placez 3 chefs-d’œuvre/artefacts de la même couleur et avec des numéros différents pour obtenir un bonus thématique."),

-- =============================================================================
-- Notes
("fr_FR", "LOC_CUI_NOTES",                                                      "Notes"),
("fr_FR", "LOC_CUI_NOTE_LAST_EDIT",                                             "[ Dernière édition tour : {1_num} ]"),
("fr_FR", "LOC_CUI_NOTE_EMPTY",                                                 "Note vide"),

-- =============================================================================
-- Screenshot
("fr_FR", "LOC_CUI_SCREENSHOT_TOOLTIP",                                         "Mode photo[NEWLINE][NEWLINE]L'interface utilisateur n'apparaitra pas dans ce mode pour vous permettre de prendre des photos propres.[NEWLINE][NEWLINE]Click gauche pour cacher tous les éléments de l'interface[NEWLINE]Click droit pour cacher tout sauf les bannières des villes[NEWLINE] ALT pour faire pivoter l'écran[NEWLINE]ESC pour sortir du mode photo"),

-- =============================================================================
-- Civ Assistant
("fr_FR", "LOC_CUI_CA_SURPLUS_RESOUCES",                                        "Surplus de ressources de luxe"),
("fr_FR", "LOC_CUI_CA_SURPLUS_RESOUCES_OPT",                                    "Surplus de ressources de luxe"),

-- =============================================================================
("fr_FR", "LOC_CUI_COLON", ": ");
-- EOF