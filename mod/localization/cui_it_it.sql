-- =============================================================================
-- CUI Ingame Text - [Italian] by [Diaz Ex Machina] 2/18/2019
-- =============================================================================

INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text) VALUES

-- =============================================================================
-- City Panel
("it_IT", "LOC_CUI_CP_MANAGE_CITIZENS_TILES",                                   "Gestione cittadini e caselle"),

-- =============================================================================
-- City States Panel
("it_IT", "LOC_CUI_CSP_ENVOYS_SUZERAIN",                                        "Emissari inviati: {1_num}, Sovrano: {2_num}"),

-- =============================================================================
-- Deal Panel
("it_IT", "LOC_CUI_DP_GOLD_EDIT_TOOLTIP",                                       "Click sinistro aggiunge, click destro sottrae"),
("it_IT", "LOC_CUI_DP_THEY_HAVE_ITEM_TOOLTIP",                                  "Loro hanno già"),
("it_IT", "LOC_CUI_DP_WE_HAVE_ITEM_TOOLTIP",                                    "Noi abbiamo già"),

-- =============================================================================
-- Diplomatic Banner
("it_IT", "LOC_CUI_DB_CITY",                                                    "Città: {1_num}"),
("it_IT", "LOC_CUI_DB_RELIGION",                                                "Istituisci Religione: {1_name}"),
("it_IT", "LOC_CUI_DB_NONE",                                                    "Nessuna"),
("it_IT", "LOC_CUI_DB_PEACE_DEAL_AVAILABLE",                                    "[Accordo di pace disponibile]"),
("it_IT", "LOC_CUI_DB_PEACE_DEAL_NOT_AVAILABLE",                                "[Proposta di pace: {1_Remaining}[ICON_TURN]]"),
("it_IT", "LOC_CUI_DB_RELATIONSHIP",                                            "Relazioni: {1_Relationship}"),
("it_IT", "LOC_CUI_DB_GRIEVANCES_NONE",                                         "Nessuna rimostranza"),
("it_IT", "LOC_CUI_DB_GRIEVANCES",                                              "Rimostranza: {1_Grievances}"),
("it_IT", "LOC_CUI_DB_THEY_CAN_OFFER",                                          "Loro possono offrire:"),
("it_IT", "LOC_CUI_DB_WE_CAN_OFFER",                                            "Noi possiamo offrire:"),
("it_IT", "LOC_CUI_DB_GOLD",                                                    "Oro:"),
("it_IT", "LOC_CUI_DB_GOLD_AND_FAVOR",                                          "Oro e favore:"),
("it_IT", "LOC_CUI_DB_SCORE_AND_YIELDS",                                        "Punteggio e rese:"),
("it_IT", "LOC_CUI_DB_MARS_PROJECT",                                            "Colonia marziana: {1_progress}  {2_progress}  {3_progress}"),
("it_IT", "LOC_CUI_DB_EXOPLANET_EXPEDITION",                                    "Spedizione verso esopianeta: {1_progress}{2_progress}{3_progress}{4_progress}{5_progress}"),
("it_IT", "LOC_CUI_DB_VISITING_TOURISTS",                                       "Turisti in visita: {1_num} / {2_total}"),
("it_IT", "LOC_CUI_DB_CAPITALS_CAPTURED",                                       "Capitali catturate: {1_num}"),
("it_IT", "LOC_CUI_DB_CIVS_CONVERTED",                                          "Civiltà convertite: {1_num} / {2_total}"),
("it_IT", "LOC_CUI_DB_DIPLOMATIC_POINT",                                        "Punti vittoria diplomatica: {1_num} / {2_total}"),

-- =============================================================================
-- Espionage Panel
("it_IT", "LOC_CUI_EP_FILTER_ALL",                                              "Tutto"),
("it_IT", "LOC_CUI_EP_FILTER_SHOW_CITIES",                                      "Mostra città"),

-- =============================================================================
-- Minimap Panel
("it_IT", "LOC_CUI_MP_SHOW_DISTRICTS_TOOLTIP",                                  "Mostra icone distretti"),
("it_IT", "LOC_CUI_MP_SHOW_WONDERS_TOOLTIP",                                    "Mostra icone meraviglie"),
("it_IT", "LOC_CUI_MP_AUTONAMING",                                              "Nomina"),
("it_IT", "LOC_CUI_MP_AUTONAMING_TOOLTIP",                                      "Nomina spilli automaticamente"),
("it_IT", "LOC_CUI_MO_SHOW_IMPROVED_RESOURCES",                                 "Mostra icone risorse migliorate"),
("it_IT", "LOC_CUI_MO_TOGGLE_IMPROVED_TOOLTIP",                                 "Mostra/nascondi icone risorse migliorate"),
("it_IT", "LOC_CUI_MO_SHOW_UNIT_FLAGS",                                         "Mostra segnaposti unità"),
("it_IT", "LOC_CUI_MP_TOGGLE_UNIT_FLAGS_TOOLTIP",                               "Mostra/nascondi segnaposti unità"),
("it_IT", "LOC_CUI_MO_SHOW_CITY_BANNERS",                                       "Mostra banner città"),
("it_IT", "LOC_CUI_MP_TOGGLE_CITY_BANNERS_TOOLTIP",                             "Mostra/nascondi banner città"),
("it_IT", "LOC_CUI_MO_SHOW_TRADERS",                                            "Mostra commercianti"),
("it_IT", "LOC_CUI_MP_TOGGLE_TRADERS_TOOLTIP",                                  "Mostra/nascondi icone commerciante"),
("it_IT", "LOC_CUI_MO_SHOW_RELIGIONS",                                          "Show Religion Units"),
("it_IT", "LOC_CUI_MP_TOGGLE_RELIGIONS_TOOLTIP",                                "Toggle Religion Flags"),

-- =============================================================================
-- Report Screen
("it_IT", "LOC_CUI_RS_SHOW_CITY_DETAILS",                                       "Mostra dettagli città"),
("it_IT", "LOC_CUI_RS_BUILDING_NUMBER",                                         "Numero di edifici"),
("it_IT", "LOC_CUI_RS_TOTALS",                                                  "Totali: {1_num}"),
("it_IT", "LOC_CUI_RS_DEALS_OUTGOING",                                          "In uscita"),
("it_IT", "LOC_CUI_RS_DEALS_INCOMING",                                          "In entrata"),

-- =============================================================================
-- Top Panel
("it_IT", "LOC_CUI_SI_SPY_AVAILABLE",                                           "{1_num} [ICON_Unit] {1_num : plural 1?Spia; other?Spie;} disponibile/i"),
("it_IT", "LOC_CUI_SI_SPY_CAPACITY",                                            "{1_num} [ICON_Unit] {1_num : plural 1?Spia; other?Spie;} arruolabile/i"),

-- =============================================================================
-- World Tracker
("it_IT", "LOC_CUI_WT_REMINDER",                                                "Promemoria"),
("it_IT", "LOC_CUI_WT_TECH_REMINDER_TOOLTIP",                                   "Il colore di sfondo cambia in verde quando la tecnologia può essere completata con l'acquisto di un Eureka."),
("it_IT", "LOC_CUI_WT_CIVIC_REMINDER_TOOLTIP",                                  "Il colore di sfondo cambia in verde quando il civico può essere finito ottenendo un'ispirazione."),
("it_IT", "LOC_CUI_WT_GOSSIP_LOG",                                              "Registro Pettegolezzi"),
("it_IT", "LOC_CUI_WT_COMBAT_LOG",                                              "Registro Combattimenti"),
("it_IT", "LOC_CUI_WT_PERSIST",                                                 "Persisti"),
("it_IT", "LOC_CUI_WT_GLOG_PERSIST_TOOLTIP",                                    "Non cancellare il registro dei pettegolezzi tra un turno e l'altro."),
("it_IT", "LOC_CUI_WT_CLOG_PERSIST_TOOLTIP",                                    "Non cancellare il registro dei combattimenti tra un turno e l'altro."),

-- =============================================================================
-- Trade Panel
("it_IT", "LOC_CUI_TP_SORT_BY_FOOD_TOOLTIP",                                    "Ordina per [ICON_Food]Cibo."),
("it_IT", "LOC_CUI_TP_SORT_BY_PRODUCTION_TOOLTIP",                              "Ordina per [ICON_Production]Produzione."),
("it_IT", "LOC_CUI_TP_SORT_BY_GOLD_TOOLTIP",                                    "Ordina per [ICON_Gold]Oro."),
("it_IT", "LOC_CUI_TP_SORT_BY_SCIENCE_TOOLTIP",                                 "Ordina per [ICON_Science]Scienza."),
("it_IT", "LOC_CUI_TP_SORT_BY_CULTURE_TOOLTIP",                                 "Ordina per [ICON_Culture]Cultura."),
("it_IT", "LOC_CUI_TP_SORT_BY_FAITH_TOOLTIP",                                   "Ordina per [ICON_Faith]Fede."),
("it_IT", "LOC_CUI_TP_SORT_BY_TURNS_REMAINING_TOOLTIP",                         "Ordina per [ICON_Turn]turni per completare la rotta."),
("it_IT", "LOC_CUI_TP_REPEAT",                                                  "Ripeti"),
("it_IT", "LOC_CUI_TP_REPEAT_TOOLTIP",                                          "Fai ripetere la rotta a questo commerciante indefinitivamente."),
("it_IT", "LOC_CUI_TP_SELECT_A_CITY",                                           "Seleziona una nuova città d'origine."),

-- =============================================================================
-- Espionage Panel
("it_IT", "LOC_CUI_EP_SHOW_CITYS",                                              "Mostra città"),
("it_IT", "LOC_CUI_EP_SIPHON_FUNDS",                                            "Ottieni ({1_GoldString}) resa d'Oro."),

-- =============================================================================
-- Production Panel
("it_IT", "LOC_CUI_PP_QUEUE_DEFAULT",                                           "Utilizza coda di default"),

-- =============================================================================
-- Great Works
("it_IT", "LOC_CUI_GW_SORT_BY_CITY",                                            "Ordina per città"),
("it_IT", "LOC_CUI_GW_SORT_BY_BUILDING",                                        "Ordina per edificio"),
("it_IT", "LOC_CUI_GW_THEMING_HELPER",                                          "Assistente temi"),
("it_IT", "LOC_CUI_GW_THEMING_HELPER_TOOLTIP",                                  "Scegli tre Grandi Capolavori / Manufatti dello stesso colore e numeri diversi per completare un tema"),

-- =============================================================================
-- Notes
("it_IT", "LOC_CUI_NOTES",                                                      "Note"),
("it_IT", "LOC_CUI_NOTE_LAST_EDIT",                                             "[ Ultima modifica al turno：{1_num} ]"),
("it_IT", "LOC_CUI_NOTE_EMPTY",                                                 "Nota Vuota"),

-- =============================================================================
-- Screenshot
("it_IT", "LOC_CUI_SCREENSHOT_TOOLTIP",                                         "Enter Screenshot Mode[NEWLINE][NEWLINE]Screenshot Mode will hide most or all UI Elements, allows you to take clean screenshots.[NEWLINE][NEWLINE]Left-click hide all UI Elements[NEWLINE]Right-click hide all UI Elements except for City Banners[NEWLINE]Hold ALT to rotate the screen[NEWLINE]Press ESC to exit Screenshot Mode"),

-- =============================================================================
-- Civ Assistant
("it_IT", "LOC_CUI_CA_SURPLUS_RESOUCES",                                        "Risorse di lusso in avanzo"),
("it_IT", "LOC_CUI_CA_SURPLUS_RESOUCES_OPT",                                    "Risorse di lusso in avanzo"),

-- =============================================================================
("it_IT", "LOC_CUI_COLON", ": ");
-- EOF