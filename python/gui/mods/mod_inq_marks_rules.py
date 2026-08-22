# -*- coding: utf-8 -*-
"""Runtime rules for INQ Marks.

Keeps the battle badge limited to standard random battles, uses one public
battleBadgeStyle setting, and selects a matching garage badge automatically
when that style has a garage renderer.
"""

import json
import os

import BigWorld
import constants

try:
    from gui.mods import mod_inq_marks as marks
except ImportError:
    import mod_inq_marks as marks


_VALID_STYLES = ('classic', 'compact', 'polaroid', 'neer', 'minimal')
_GARAGE_STYLES = ('classic', 'compact', 'polaroid')
_DEFAULT_STYLE = 'classic'


def _minimalConfig(style):
    return {'battleBadgeStyle': style}


def _loadSingleStyleConfig():
    marks._ensureConfigDir()
    loaded = {}
    if os.path.isfile(marks._CONFIG_FILE):
        try:
            with open(marks._CONFIG_FILE, 'rb') as stream:
                loaded = json.load(stream)
            if not isinstance(loaded, dict):
                loaded = {}
        except Exception:
            loaded = {}

    style = marks._safeLower(loaded.get('battleBadgeStyle'))
    if style not in _VALID_STYLES:
        # One-time migration from the previous single-style config.
        style = marks._safeLower(loaded.get('badgeStyle'))
    if style not in _VALID_STYLES:
        # One-time migration from an old garage-only config.
        style = marks._safeLower(loaded.get('garageBadgeStyle'))
    if style not in _VALID_STYLES:
        style = _DEFAULT_STYLE

    config = _minimalConfig(style)
    if loaded != config:
        try:
            with open(marks._CONFIG_FILE, 'wb') as stream:
                json.dump(config, stream, indent=4)
        except Exception:
            marks.logger.exception('config: failed to write battleBadgeStyle setting')
    return config


def _loadSingleStyle(self):
    config = _loadSingleStyleConfig()
    style = marks._safeLower(config.get('battleBadgeStyle'))
    if style not in _VALID_STYLES:
        style = _DEFAULT_STYLE

    styleID = int(marks._CONFIG_BADGE_STYLES.get(style, 0))
    self._configEnabled = True
    self._configMarkBadge = True
    self._configPanelBodyVisible = False
    self._configBadgeStyle = styleID
    self._configBattleBadgeStyle = styleID
    self._garageBadgeEnabled = style in _GARAGE_STYLES
    self._markBadgeOpen = True
    self._battleBadgeEnabled = True


def _updateGarageVisibility(self):
    if not (self._panelReady and self._injectorView):
        return

    hangarCheck = self._hangarVisible
    if hangarCheck:
        try:
            lsm = marks.getLobbyStateMachine()
            if lsm is not None:
                routeInfo = lsm.visibleRouteInfo
                hangarCheck = self._isHangarState(routeInfo.state)
        except Exception:
            pass

    visible = bool(
        getattr(self, '_garageBadgeEnabled', True)
        and self._configEnabled
        and hangarCheck
        and self._visibleByData
        and not self._modsSettingsOpen
        and self._queueModeAllowed
        and not self._strongholdScreenOpen
        and not self._userHidden
    )
    if self._lastVisibleState == visible:
        return
    self._lastVisibleState = visible
    try:
        self._injectorView.flashObject.as_setVisible(visible)
    except Exception:
        marks.logger.exception('as_setVisible failed')


def _randomBattleState():
    """Return True for standard random, False for another mode, None if not ready."""
    if marks._isReplayPlaying():
        return False
    try:
        player = BigWorld.player()
        arena = getattr(player, 'arena', None)
        if arena is None:
            return None

        bonusType = getattr(arena, 'bonusType', None)
        arenaBonusType = getattr(constants, 'ARENA_BONUS_TYPE', None)
        regular = getattr(arenaBonusType, 'REGULAR', None) if arenaBonusType is not None else None
        if bonusType is not None and regular is not None:
            return bonusType == regular

        guiType = getattr(player, 'arenaGuiType', None)
        if guiType is None:
            guiType = getattr(arena, 'guiType', None)
        arenaGuiType = getattr(constants, 'ARENA_GUI_TYPE', None)
        randomType = getattr(arenaGuiType, 'RANDOM', None) if arenaGuiType is not None else None
        if guiType is not None and randomType is not None:
            return guiType == randomType
    except Exception:
        marks.logger.exception('battle mode check failed')
    return None


def _tryEnterRandomBattle(self, attempt):
    state = _randomBattleState()
    if state is None:
        if attempt < 30:
            self._battleEnterCallbackId = BigWorld.callback(
                0.35, lambda: self._tryEnterBattle(attempt + 1))
        return

    self._battleEnterCallbackId = None
    if not state:
        marks.logger.debug('battle enter: skipped, only standard random battles are allowed')
        return

    tankID = self._snapshotBaselineForBattle()
    if tankID is None:
        if attempt < 30:
            self._battleEnterCallbackId = BigWorld.callback(
                0.35, lambda: self._tryEnterBattle(attempt + 1))
        return
    if self._ctrl._battleMode and self._ctrl._battleTankID == tankID:
        return

    marks.logger.debug('battle enter: accepted standard random tankID=%s', tankID)
    self._ctrl.enterBattle(tankID)


marks._loadConfigFile = _loadSingleStyleConfig
marks.InqMarksController._loadConfig = _loadSingleStyle
marks.InqMarksController._updateVisibility = _updateGarageVisibility
marks._InqMarksMod._tryEnterBattle = _tryEnterRandomBattle

# The main module creates its controller during import, before this rules module
# is loaded. Apply the new config immediately to that existing instance.
try:
    marks._g_inq_marks._ctrl._loadConfig()
    marks._g_inq_marks._ctrl._lastVisibleState = None
except Exception:
    marks.logger.exception('rules: failed to reload Marks configuration')
