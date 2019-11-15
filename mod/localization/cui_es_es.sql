-- =============================================================================
-- CUI Ingame Text - [Spanish] by [MinuZzzZz] 4/26/2019
-- =============================================================================

INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text) VALUES

-- =============================================================================
-- City Panel
("es_ES", "LOC_CUI_CP_MANAGE_CITIZENS_TILES",                                   "Gestionar Ciudadanos y Casillas"),

-- =============================================================================
-- City States Panel
("es_ES", "LOC_CUI_CSP_ENVOYS_SUZERAIN",                                        "Enviados totales: {1_num}, Suzerano de: {2_num}"),

-- =============================================================================
-- Deal Panel
("es_ES", "LOC_CUI_DP_GOLD_EDIT_TOOLTIP",                                       "Clic-I: Incluir, Clic-D: Retirar"),
("es_ES", "LOC_CUI_DP_THEY_HAVE_ITEM_TOOLTIP",                                  "Ya tienen"),
("es_ES", "LOC_CUI_DP_WE_HAVE_ITEM_TOOLTIP",                                    "Ya tenemos"),
("es_ES", "LOC_CUI_DP_WE_HAVE_ONLY_ONE_TOOLTIP",                                "We only have one"),

-- =============================================================================
-- Diplomatic Banner
("es_ES", "LOC_CUI_DB_CITY",                                                    "Ciudades: {1_num}"),
("es_ES", "LOC_CUI_DB_RELIGION",                                                "Religión: {1_name}"),
("es_ES", "LOC_CUI_DB_NONE",                                                    "Ninguno"),
("es_ES", "LOC_CUI_DB_PEACE_DEAL_AVAILABLE",                                    "[Acuerdo de Paz disponible]"),
("es_ES", "LOC_CUI_DB_PEACE_DEAL_NOT_AVAILABLE",                                "[Acuerdo de Paz: {1_Remaining}[ICON_TURN]]"),
("es_ES", "LOC_CUI_DB_RELATIONSHIP",                                            "Relaciones: {1_Relationship}"),
("es_ES", "LOC_CUI_DB_GRIEVANCES_NONE",                                         "Sin Quejas"),
("es_ES", "LOC_CUI_DB_GRIEVANCES",                                              "Quejas: {1_Grievances}"),
("es_ES", "LOC_CUI_DB_THEY_CAN_OFFER",                                          "Pueden ofrecernos:"),
("es_ES", "LOC_CUI_DB_WE_CAN_OFFER",                                            "Podemos ofrecerles:"),
("es_ES", "LOC_CUI_DB_GOLD",                                                    "Oro:"),
("es_ES", "LOC_CUI_DB_GOLD_AND_FAVOR",                                          "Oro y Favor Diplomático:"),
("es_ES", "LOC_CUI_DB_SCORE_AND_YIELDS",                                        "Puntuación y Rendimientos:"),
("es_ES", "LOC_CUI_DB_MARS_PROJECT",                                            "Colonización de Marte: {1_progress}  {2_progress}  {3_progress}"),
("es_ES", "LOC_CUI_DB_EXOPLANET_EXPEDITION",                                    "Expedición Exoplanetaria: {1_progress}{2_progress}{3_progress}{4_progress}{5_progress}"),
("es_ES", "LOC_CUI_DB_VISITING_TOURISTS",                                       "Turistas Extranjeros: {1_num} / {2_total}"),
("es_ES", "LOC_CUI_DB_CAPITALS_CAPTURED",                                       "Capitales Capturadas: {1_num}"),
("es_ES", "LOC_CUI_DB_CIVS_CONVERTED",                                          "Civilizaciones Convertidas: {1_num} / {2_total}"),
("es_ES", "LOC_CUI_DB_DIPLOMATIC_POINT",                                        "Puntos de Victoria Diplomática: {1_num} / {2_total}"),

-- =============================================================================
-- Espionage Panel
("es_ES", "LOC_CUI_EP_FILTER_ALL",                                              "Todas"),
("es_ES", "LOC_CUI_EP_FILTER_SHOW_CITIES",                                      "Mostrar Ciudades"),

-- =============================================================================
-- Minimap Panel
("es_ES", "LOC_CUI_MP_SHOW_DISTRICTS_TOOLTIP",                                  "Mostrar Iconos de Distrito"),
("es_ES", "LOC_CUI_MP_SHOW_WONDERS_TOOLTIP",                                    "Mostrar Iconos de Maravilla"),
("es_ES", "LOC_CUI_MP_AUTONAMING",                                              "Nombrar"),
("es_ES", "LOC_CUI_MP_AUTONAMING_TOOLTIP",                                      "Nombrar Marcadores automáticamente"),
("es_ES", "LOC_CUI_MO_SHOW_IMPROVED_RESOURCES",                                 "Mostrar Iconos de Recursos Mejorados"),
("es_ES", "LOC_CUI_MO_TOGGLE_IMPROVED_TOOLTIP",                                 "Alternar Iconos de Recursos Mejorados"),
("es_ES", "LOC_CUI_MO_SHOW_UNIT_FLAGS",                                         "Mostrar Banderas de unidad"),
("es_ES", "LOC_CUI_MP_TOGGLE_UNIT_FLAGS_TOOLTIP",                               "Alternan Banderas de unidad"),
("es_ES", "LOC_CUI_MO_SHOW_CITY_BANNERS",                                       "Mostrar Estandartes de ciudad"),
("es_ES", "LOC_CUI_MP_TOGGLE_CITY_BANNERS_TOOLTIP",                             "Alternar Estandartes de ciudad"),
("es_ES", "LOC_CUI_MO_SHOW_TRADERS",                                            "Mostrar Comerciantes"),
("es_ES", "LOC_CUI_MP_TOGGLE_TRADERS_TOOLTIP",                                  "Alternar Iconos de comerciante"),
("es_ES", "LOC_CUI_MO_SHOW_RELIGIONS",                                          "Show Religion Units"),
("es_ES", "LOC_CUI_MP_TOGGLE_RELIGIONS_TOOLTIP",                                "Toggle Religion Flags"),

-- =============================================================================
-- Report Screen
("es_ES", "LOC_CUI_RS_SHOW_CITY_DETAILS",                                       "Mostrar  detalles de ciudad"),
("es_ES", "LOC_CUI_RS_BUILDING_NUMBER",                                         "Número de Edificios"),
("es_ES", "LOC_CUI_RS_TOTALS",                                                  "Totales: {1_num}"),
("es_ES", "LOC_CUI_RS_DEALS_OUTGOING",                                          "Salientes"),
("es_ES", "LOC_CUI_RS_DEALS_INCOMING",                                          "Entrantes"),

-- =============================================================================
-- SpyInfo
("es_ES", "LOC_CUI_SI_SPY_AVAILABLE",                                           "{1_num} [ICON_Unit] {1_num : plural 1?Espía; other?Espías;} disponibles"),
("es_ES", "LOC_CUI_SI_SPY_CAPACITY",                                            "{1_num} [ICON_Unit] {1_num : plural 1?Espía; other?Espías;} permitidos"),

-- =============================================================================
-- World Tracker
("es_ES", "LOC_CUI_WT_REMINDER",                                                "Recordatorio"),
("es_ES", "LOC_CUI_WT_TECH_REMINDER_TOOLTIP",                                   "El color de fondo cambia a verde cuando la tecnología puede ser completada mediante un Eureka."),
("es_ES", "LOC_CUI_WT_CIVIC_REMINDER_TOOLTIP",                                  "El color de fondo cambia a verde cuando el principio puede ser completado mediante una Inspiración."),
("es_ES", "LOC_CUI_WT_GOSSIP_LOG",                                              "Informe de Chismorreos"),
("es_ES", "LOC_CUI_WT_COMBAT_LOG",                                              "Informe de Combate"),
("es_ES", "LOC_CUI_WT_PERSIST",                                                 "Persistir"),
("es_ES", "LOC_CUI_WT_GLOG_PERSIST_TOOLTIP",                                    "No limpiar el informe de chismorreos entre turnos."),
("es_ES", "LOC_CUI_WT_CLOG_PERSIST_TOOLTIP",                                    "No limpiar el informe de combate entre turnos."),

-- =============================================================================
-- Trade Panel
("es_ES", "LOC_CUI_TP_SORT_BY_FOOD_TOOLTIP",                                    "Ordenar por [ICON_Food]Alimentos."),
("es_ES", "LOC_CUI_TP_SORT_BY_PRODUCTION_TOOLTIP",                              "Ordenar por [ICON_Production]Producción."),
("es_ES", "LOC_CUI_TP_SORT_BY_GOLD_TOOLTIP",                                    "Ordenar por [ICON_Gold]Oro."),
("es_ES", "LOC_CUI_TP_SORT_BY_SCIENCE_TOOLTIP",                                 "Ordenar por [ICON_Science]Ciencia."),
("es_ES", "LOC_CUI_TP_SORT_BY_CULTURE_TOOLTIP",                                 "Ordenar por [ICON_Culture]Cultura."),
("es_ES", "LOC_CUI_TP_SORT_BY_FAITH_TOOLTIP",                                   "Ordenar por [ICON_Faith]Fe."),
("es_ES", "LOC_CUI_TP_SORT_BY_TURNS_REMAINING_TOOLTIP",                         "Ordenar por [ICON_Turn]Turnos para completar ruta."),
("es_ES", "LOC_CUI_TP_REPEAT",                                                  "Repetir"),
("es_ES", "LOC_CUI_TP_REPEAT_TOOLTIP",                                          "Repetir ruta comercial indefinidamente con este comerciante."),
("es_ES", "LOC_CUI_TP_SELECT_A_CITY",                                           "Elegir Nueva Ciuad de Origen."),

-- =============================================================================
-- Espionage Panel
("es_ES", "LOC_CUI_EP_SHOW_CITYS",                                              "Mostrar Ciudades"),
("es_ES", "LOC_CUI_EP_SIPHON_FUNDS",                                            "Gana ({1_GoldString}) de Oro."),

-- =============================================================================
-- Production Panel
("es_ES", "LOC_CUI_PP_QUEUE_DEFAULT",                                           "Usar Cola por defecto"),

-- =============================================================================
-- Great Works
("es_ES", "LOC_CUI_GW_SORT_BY_CITY",                                            "Ordenar por Ciudad"),
("es_ES", "LOC_CUI_GW_SORT_BY_BUILDING",                                        "Ordenar por Edificio"),
("es_ES", "LOC_CUI_GW_THEMING_HELPER",                                          "Ayudante"),
("es_ES", "LOC_CUI_GW_THEMING_HELPER_TOOLTIP",                                  "Toma tres Grandes Obras / Arttefactos del mismo color y números diferentes para completar el tema."),

-- =============================================================================
-- Notes
("es_ES", "LOC_CUI_NOTES",                                                      "Notas"),
("es_ES", "LOC_CUI_NOTE_LAST_EDIT",                                             "[ Turno: {1_num} ]"),
("es_ES", "LOC_CUI_NOTE_EMPTY",                                                 "Nota vacía"),

-- =============================================================================
-- Options
("es_ES", "LOC_CUI_OPTIONS_TAB_VICTORY",                                        "Victories"),
("es_ES", "LOC_CUI_OPTIONS_TAB_LOG",                                            "Logs"),
("es_ES", "LOC_CUI_OPTIONS_TAB_POPUP",                                          "Popups"),
("es_ES", "LOC_CUI_OPTIONS_TAB_REMIND",                                         "Remind"),
("es_ES", "LOC_CUI_OPTIONS_DESC_VICTORY",                                       "Please select the victory you want to track."),
("es_ES", "LOC_CUI_OPTIONS_DESC_LOG",                                           "Please elect where the logs will be displayed."),
("es_ES", "LOC_CUI_OPTIONS_DESC_POPUP",                                         "Please select the popover you want to enable."),
("es_ES", "LOC_CUI_OPTIONS_DESC_REMIND",                                        "Please select the reminder you want to use."),
--
("es_ES", "LOC_CUI_OPTIONS_LOG_SHOW_NONE",                                      "Disable"),
("es_ES", "LOC_CUI_OPTIONS_LOG_DEFAULT",                                        "Default position"),
("es_ES", "LOC_CUI_OPTIONS_LOG_WORLDTRACKER",                                   "World Tracker"),
("es_ES", "LOC_CUI_OPTIONS_LOG_BOTH",                                           "Both"),
--
("es_ES", "LOC_CUI_OPTIONS_POPUP_RESEARCH",                                     "Tech/Civic complete"),
("es_ES", "LOC_CUI_OPTIONS_POPUP_AUDIO",                                        "Tech/Civic audio"),
("es_ES", "LOC_CUI_OPTIONS_POPUP_ERA_SCORE",                                    "Gain era score"),
("es_ES", "LOC_CUI_OPTIONS_POPUP_GREAT_WORK",                                   "Create great works"),
("es_ES", "LOC_CUI_OPTIONS_POPUP_RELIC",                                        "Get relics"),
--
("es_ES", "LOC_CUI_OPTIONS_REMIND_TECH",                                        "Tech complete by eureka"),
("es_ES", "LOC_CUI_OPTIONS_REMIND_CIVIC",                                       "Civic complete by inspire"),
("es_ES", "LOC_CUI_OPTIONS_REMIND_GOVERNMENT",                                  "Free government chance"),
("es_ES", "LOC_CUI_OPTIONS_REMIND_GOVERNOR",                                    "Governor titles available"),

-- =============================================================================
-- Screenshot
("es_ES", "LOC_CUI_SCREENSHOT_TOOLTIP",                                         "Entrar en Modo de Captura de Pantalla[NEWLINE][NEWLINE]El Modo de Captura de Pantalla oculta los elementos de la IU para tomar capturas limpias.[NEWLINE][NEWLINE]Click-izquierdo para ocultar los elementos de la IU[NEWLINE]Click-derecho para ocultar los elementos de la IU, excepto los estandartes de Ciudad[NEWLINE] Mantener ALT para girar la pantalla[NEWLINE]ESC para salir del Modo de Captura de Pantalla."),

-- =============================================================================
("es_ES", "LOC_CUI_COLON", ": ");
-- EOF