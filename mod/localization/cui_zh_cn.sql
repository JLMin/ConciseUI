-- =============================================================================
-- CUI Ingame Text - [Simplified Chinese] by [eudaimonia]
-- =============================================================================

INSERT OR REPLACE INTO LocalizedText (Language, Tag, Text) VALUES

-- =============================================================================
-- City Panel
("zh_Hans_CN", "LOC_CUI_CP_MANAGE_CITIZENS_TILES",                              "市民与单元格管理"),

-- =============================================================================
-- City States Panel
("zh_Hans_CN", "LOC_CUI_CSP_ENVOYS_SUZERAIN",                                   "派遣使者：{1_num}，宗主国：{2_num}"),

-- =============================================================================
-- Deal Panel
("zh_Hans_CN", "LOC_CUI_DP_GOLD_EDIT_TOOLTIP",                                  "左键增加，右键减少"),
("zh_Hans_CN", "LOC_CUI_DP_THEY_HAVE_ITEM_TOOLTIP",                             "他们已拥有"),
("zh_Hans_CN", "LOC_CUI_DP_WE_HAVE_ITEM_TOOLTIP",                               "我们已拥有"),

-- =============================================================================
-- Diplomatic Banner
("zh_Hans_CN", "LOC_CUI_DB_CITY",                                               "城市：{1_num}"),
("zh_Hans_CN", "LOC_CUI_DB_RELIGION",                                           "宗教：{1_name}"),
("zh_Hans_CN", "LOC_CUI_DB_NONE",                                               "无"),
("zh_Hans_CN", "LOC_CUI_DB_PEACE_DEAL_AVAILABLE",                               "[和平协议可用]"),
("zh_Hans_CN", "LOC_CUI_DB_PEACE_DEAL_NOT_AVAILABLE",                           "[和平协议：{1_Remaining}[ICON_TURN]]"),
("zh_Hans_CN", "LOC_CUI_DB_RELATIONSHIP",                                       "关系：{1_Relationship}"),
("zh_Hans_CN", "LOC_CUI_DB_GRIEVANCES_NONE",                                    "无不满"),
("zh_Hans_CN", "LOC_CUI_DB_GRIEVANCES",                                         "不满：{1_Grievances}"),
("zh_Hans_CN", "LOC_CUI_DB_THEY_CAN_OFFER",                                     "他们可以提供："),
("zh_Hans_CN", "LOC_CUI_DB_WE_CAN_OFFER",                                       "我们可以提供："),
("zh_Hans_CN", "LOC_CUI_DB_GOLD",                                               "金币："),
("zh_Hans_CN", "LOC_CUI_DB_GOLD_AND_FAVOR",                                     "金币及外交支持："),
("zh_Hans_CN", "LOC_CUI_DB_SCORE_AND_YIELDS",                                   "分数及收益："),
("zh_Hans_CN", "LOC_CUI_DB_MARS_PROJECT",                                       "火星殖民进度：{1_progress}  {2_progress}  {3_progress}"),
("zh_Hans_CN", "LOC_CUI_DB_EXOPLANET_EXPEDITION",                               "系外行星探索：{1_progress}{2_progress}{3_progress}{4_progress}{5_progress}"),
("zh_Hans_CN", "LOC_CUI_DB_VISITING_TOURISTS",                                  "国际游客数量：{1_num} / {2_total}"),
("zh_Hans_CN", "LOC_CUI_DB_CAPITALS_CAPTURED",                                  "已占领的首都：{1_num}"),
("zh_Hans_CN", "LOC_CUI_DB_CIVS_CONVERTED",                                     "已转化的文明：{1_num} / {2_total}"),
("zh_Hans_CN", "LOC_CUI_DB_DIPLOMATIC_POINT",                                   "外交胜利点数：{1_num} / {2_total}"),

-- =============================================================================
-- Espionage Panel
("zh_Hans_CN", "LOC_CUI_EP_FILTER_ALL",                                         "全部"),
("zh_Hans_CN", "LOC_CUI_EP_FILTER_SHOW_CITIES",                                 "选择城市"),

-- =============================================================================
-- Minimap Panel
("zh_Hans_CN", "LOC_CUI_MP_SHOW_DISTRICTS_TOOLTIP",                             "显示区域图标"),
("zh_Hans_CN", "LOC_CUI_MP_SHOW_WONDERS_TOOLTIP",                               "显示奇观图标"),
("zh_Hans_CN", "LOC_CUI_MP_AUTONAMING",                                         "自动命名"),
("zh_Hans_CN", "LOC_CUI_MP_AUTONAMING_TOOLTIP",                                 "自动给地图导航命名"),
("zh_Hans_CN", "LOC_CUI_MO_SHOW_IMPROVED_RESOURCES",                            "显示已改良资源图标"),
("zh_Hans_CN", "LOC_CUI_MO_TOGGLE_IMPROVED_TOOLTIP",                            "开启/关闭已改良资源图标"),
("zh_Hans_CN", "LOC_CUI_MO_SHOW_UNIT_FLAGS",                                    "显示单位图标"),
("zh_Hans_CN", "LOC_CUI_MP_TOGGLE_UNIT_FLAGS_TOOLTIP",                          "开启/关闭单位图标"),
("zh_Hans_CN", "LOC_CUI_MO_SHOW_CITY_BANNERS",                                  "显示城市横幅"),
("zh_Hans_CN", "LOC_CUI_MP_TOGGLE_CITY_BANNERS_TOOLTIP",                        "开启/关闭城市横幅"),
("zh_Hans_CN", "LOC_CUI_MO_SHOW_TRADERS",                                       "显示商人图标"),
("zh_Hans_CN", "LOC_CUI_MP_TOGGLE_TRADERS_TOOLTIP",                             "开启/关闭商人图标"),
("zh_Hans_CN", "LOC_CUI_MO_SHOW_RELIGIONS",                                     "显示宗教单位图标"),
("zh_Hans_CN", "LOC_CUI_MP_TOGGLE_RELIGIONS_TOOLTIP",                           "开启/关闭宗教单位图标"),

-- =============================================================================
-- Report Screen
("zh_Hans_CN", "LOC_CUI_RS_SHOW_CITY_DETAILS",                                  "显示城市细节"),
("zh_Hans_CN", "LOC_CUI_RS_BUILDING_NUMBER",                                    "建筑数量"),
("zh_Hans_CN", "LOC_CUI_RS_TOTALS",                                             "总计：{1_num}"),
("zh_Hans_CN", "LOC_CUI_RS_DEALS_OUTGOING",                                     "支出"),
("zh_Hans_CN", "LOC_CUI_RS_DEALS_INCOMING",                                     "收入"),

-- =============================================================================
-- SpyInfo
("zh_Hans_CN", "LOC_CUI_SI_SPY_AVAILABLE",                                      "{1_num} [ICON_Unit] 间谍可用"),
("zh_Hans_CN", "LOC_CUI_SI_SPY_CAPACITY",                                       "{1_num} [ICON_Unit] 间谍上限"),

-- =============================================================================
-- World Tracker
("zh_Hans_CN", "LOC_CUI_WT_REMINDER",                                           "触发提示"),
("zh_Hans_CN", "LOC_CUI_WT_TECH_REMINDER_TOOLTIP",                              "当科技可通过触发尤里卡的方式完成时，背景色将变为绿色。"),
("zh_Hans_CN", "LOC_CUI_WT_CIVIC_REMINDER_TOOLTIP",                             "当市政可通过触发鼓舞的方式完成时，背景色将变为绿色。"),
("zh_Hans_CN", "LOC_CUI_WT_GOSSIP_LOG",                                         "小道消息"),
("zh_Hans_CN", "LOC_CUI_WT_COMBAT_LOG",                                         "战斗记录"),
("zh_Hans_CN", "LOC_CUI_WT_PERSIST",                                            "保留记录"),
("zh_Hans_CN", "LOC_CUI_WT_GLOG_PERSIST_TOOLTIP",                               "回合结束时不清空小道消息。"),
("zh_Hans_CN", "LOC_CUI_WT_CLOG_PERSIST_TOOLTIP",                               "回合结束时不清空战斗记录。"),

-- =============================================================================
-- Trade Panel
("zh_Hans_CN", "LOC_CUI_TP_SORT_BY_FOOD_TOOLTIP",                               "按 [ICON_Food] 食物排序"),
("zh_Hans_CN", "LOC_CUI_TP_SORT_BY_PRODUCTION_TOOLTIP",                         "按 [ICON_Production] 生产力排序"),
("zh_Hans_CN", "LOC_CUI_TP_SORT_BY_GOLD_TOOLTIP",                               "按 [ICON_Gold] 金币排序"),
("zh_Hans_CN", "LOC_CUI_TP_SORT_BY_SCIENCE_TOOLTIP",                            "按 [ICON_Science] 科技值排序"),
("zh_Hans_CN", "LOC_CUI_TP_SORT_BY_CULTURE_TOOLTIP",                            "按 [ICON_Culture] 文化值排序"),
("zh_Hans_CN", "LOC_CUI_TP_SORT_BY_FAITH_TOOLTIP",                              "按 [ICON_Faith] 信仰值排序"),
("zh_Hans_CN", "LOC_CUI_TP_SORT_BY_TURNS_REMAINING_TOOLTIP",                    "按 [ICON_Turn] 剩余回合数排序"),
("zh_Hans_CN", "LOC_CUI_TP_REPEAT",                                             "重复"),
("zh_Hans_CN", "LOC_CUI_TP_REPEAT_TOOLTIP",                                     "这位商人将无限重复他的贸易路线。"),
("zh_Hans_CN", "LOC_CUI_TP_SELECT_A_CITY",                                      "选择一个新的出发地。"),

-- =============================================================================
-- Espionage Panel
("zh_Hans_CN", "LOC_CUI_EP_SHOW_CITYS",                                         "显示城市"),
("zh_Hans_CN", "LOC_CUI_EP_SIPHON_FUNDS",                                       "获得（{1_GoldString}）金币。"),

-- =============================================================================
-- Production Panel
("zh_Hans_CN", "LOC_CUI_PP_QUEUE_DEFAULT",                                      "默认使用队列"),

-- =============================================================================
-- Great Works
("zh_Hans_CN", "LOC_CUI_GW_SORT_BY_CITY",                                       "按城市排序"),
("zh_Hans_CN", "LOC_CUI_GW_SORT_BY_BUILDING",                                   "按建筑排序"),
("zh_Hans_CN", "LOC_CUI_GW_THEMING_HELPER",                                     "主题化助手"),
("zh_Hans_CN", "LOC_CUI_GW_THEMING_HELPER_TOOLTIP",                             "选择同色不同数字的三个巨作/文物组成一个主题"),

-- =============================================================================
-- Notes
("zh_Hans_CN", "LOC_CUI_NOTES",                                                 "备忘录"),
("zh_Hans_CN", "LOC_CUI_NOTE_LAST_EDIT",                                        "[ 最后编辑于：{1_num}回合 ]"),
("zh_Hans_CN", "LOC_CUI_NOTE_EMPTY",                                            "无记录"),

-- =============================================================================
-- Screenshot
("zh_Hans_CN", "LOC_CUI_SCREENSHOT_TOOLTIP",                                    "进入截图模式[NEWLINE][NEWLINE]截图模式会隐藏大部分或所有的界面元素，可以让你获得清爽的截图。[NEWLINE][NEWLINE]左键点击隐藏所有界面[NEWLINE]右键点击保留城市横幅[NEWLINE]按住ALT键旋转屏幕[NEWLINE]按ESC键退出截图模式"),

-- =============================================================================
("zh_Hans_CN", "LOC_CUI_COLON", "：");
-- EOF