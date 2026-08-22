# -*- coding: utf-8 -*-
"""Create and normalize the public INQ Marks configuration before startup."""

import json
import os


_CONFIG_DIR = os.path.normpath(
    os.path.join(os.getcwd(), 'mods', 'configs', 'inq', 'marks')
)
_CONFIG_FILE = os.path.join(_CONFIG_DIR, 'marks.json')
_VALID_STYLES = ('classic', 'compact', 'polaroid', 'neer', 'minimal')
_DEFAULT_STYLE = 'classic'


def _safeLower(value):
    if value is None:
        return ''
    try:
        return unicode(value).lower()
    except Exception:
        try:
            return str(value).lower()
        except Exception:
            return ''


def _ensureConfigDir():
    if os.path.isdir(_CONFIG_DIR):
        return
    try:
        os.makedirs(_CONFIG_DIR)
    except OSError:
        pass


def _minimalConfig(style):
    return {'battleBadgeStyle': style}


def _prepareConfig():
    _ensureConfigDir()
    loaded = {}
    if os.path.isfile(_CONFIG_FILE):
        try:
            with open(_CONFIG_FILE, 'rb') as stream:
                loaded = json.load(stream)
            if not isinstance(loaded, dict):
                loaded = {}
        except Exception:
            loaded = {}

    style = _safeLower(loaded.get('battleBadgeStyle'))
    if style not in _VALID_STYLES:
        # Migrate the previous single-style key once.
        style = _safeLower(loaded.get('badgeStyle'))
    if style not in _VALID_STYLES:
        # Migrate an old garage-only config once, then remove the garage key.
        style = _safeLower(loaded.get('garageBadgeStyle'))
    if style not in _VALID_STYLES:
        style = _DEFAULT_STYLE

    config = _minimalConfig(style)
    if loaded == config:
        return

    try:
        with open(_CONFIG_FILE, 'wb') as stream:
            json.dump(config, stream, indent=4)
    except Exception:
        pass


_prepareConfig()
