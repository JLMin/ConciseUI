LastUpdate = "19/11/19"

UpdateContent = ""

function BuildContext()
  local updates = {
    {date = "2019/11/19", content = "Add City Status in world tracker."},
    {date = "2019/11/17", content = "Options for quick combat and quick movement."},
    {date = "2019/11/15", content = "Deal Panel update."},
  }

  UpdateContent = "Concies UI - Recent Updates"

  for _, item in ipairs(updates) do
    UpdateContent = UpdateContent .. "[NEWLINE][NEWLINE]"
    UpdateContent = UpdateContent .. item.date .. "[NEWLINE]" .. item.content
  end
end
BuildContext()