LastUpdate = "19/11/21"

UpdateContent = ""

function BuildContext()
  local updates = {
    {date = "2019/11/21", content = "Add Russian language by [iMiAMi]."},
    {date = "2019/11/20", content = "Add Korean language by [firefanda]."},
    {date = "2019/11/19", content = "Add City Status in world tracker."}
  }

  UpdateContent = "Concies UI - Recent Updates"

  for _, item in ipairs(updates) do
    UpdateContent = UpdateContent .. "[NEWLINE][NEWLINE]"
    UpdateContent = UpdateContent .. item.date .. "[NEWLINE]" .. item.content
  end
end
BuildContext()
