[View Full Changelog](https://github.com/enderneko/AbstractFramework/compare/r12...99f9c7d2fda26af56f5103def0fe5adcadfbfedf)

### New

- AF.player.battleTagMD5
- Basic hook system
- Color scaling and adjustment utilities
- Custom group support for PixelUpdater
- Events: AF_GROUP_PERMISSION_CHANGED, AF_MARKER_PERMISSION_CHANGED, AF_GROUP_UPDATE, AF_GROUP_TYPE_CHANGED, AF_PLAYER_LOGIN_DELAYED, AF_PLAYER_SPEC_UPDATE, AF_POPUPS_READY
- Frame flash animation functions
- Some icons
- Widget pool and button group for scroll list

### New functions

- AF_BorderedFrame.SetBorderColor, AF_BorderedFrame.SetBackgroundColor
- AF_Button.GetOnClick
- AF_CheckButton.SetOnCheck, AF_CheckButton.SetTextColor
- AF_IconButton.SetHoverBorder
- AF_ScrollFrame.SetContentHeights
- AF_ScrollList.ScrollTo, AF_ScrollList.GetWidgets
- AF_Slider.SetPercentage, AF_Slider.SetStep
- AF.AttachToCursor, AF.DetachFromCursor, AF.GetMouseFocus
- AF.CreateFlipBookFrame, AF.CreateGlow, AF.CreateIcon
- AF.GetAutoVerticalAnchor, AF.GetClassIcon, AF.IterateSortedClasses
- AF.GetDateTable, AF.GetMedia, AF.GetNextDaySeconds, AF.GetNPCSubtitle, AF.GetNPCFaction, AF.GetSpecRole, AF.GetUnitColor, AF.GetLevelColor, AF.GetUnitColorName
- AF.IndexOf, AF.LastIndexOf, AF.InsertAll, AF.InsertIfNotExists
- AF.InvertColor, AF.InvertColorHex
- AF.InvokeOnEnter, AF.InvokeOnLeave
- AF.LowerFirst
- AF.LSM_GetBarTextureDropdownItems, AF.LSM_GetFontDropdownItems, AF.LSM_GetFontOutlineDropdownItems
- AF.MergeExistingKeys
- AF.MoveElementToEnd, AF.MoveElementToIndex
- AF.ReAnchorRegion
- AF.RemoveCombatProtectionFromFrame
- AF.SetChecked, AF.SetProtectedFrameShown
- AF.TruncateFontStringByWidth, AF.TruncateFontStringByLength, AF.TruncateStringByLength
- AF.UnitClassBase, AF.UnregisterAddonLoaded
- AF.UpdateBaseFont, AF.UpdateFont

### Changed/Improved

- Added _scrollParent check for Tooltips
- Adjusted frame levels for dialogs and masks
- Adjusted scale multiplier for 1440p in GetBestScale
- AF_SimpleStatusBar.SetGradientColor
- AF.CreateButtonGroup
- AF.CreateGradientTexture, AF_Button.SetTexture
- AF.GetAnchorPoints_Simple
- AF.GetBestScale
- AF.SetDraggable
- AF.SetSizeToFitText rewritten as AF.ResizeToFitText
- AF.UnitFullName now supports non-players
- Alternate label support for EditBox
- Auto-resizing for AF_Switch
- Dropdown: SetOnClick renamed to SetOnSelect, removed dropdownType
- EditBox: pass self to onTextChanged
- File extension check for sound and font paths
- Font management improvements
- fontSizeOffset renamed to fontSizeDelta
- Moved PixelUtil into Utils
- OnUpdateExecutor: batching and totalTasks for onFinish
- Optional mask overlay for global dialog
- pcall for DecompressDeflate error handling
- Protected frame show/hide functions
- Removed AF.RegisterForCloseDropdown
- Renamed dropdown item and orientation functions for clarity
- Renamed group iterator and tooltip functions
- Various annotation updates
