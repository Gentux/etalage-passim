# -*- coding: utf-8 -*-


# Etalage-Passim -- Customization of Etalage for Passim
# By: Emmanuel Raviart <eraviart@easter-eggs.com>
#
# Copyright (C) 2011, 2012, 2013 Easter-eggs
# http://gitorious.org/passim/etalage-passim
#
# This file is part of Etalage-Passim.
#
# Etalage-Passim is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Etalage-Passim is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


"""Context loaded and saved in WSGI requests"""


import gettext

import webob

from . import conf


__all__ = ['Ctx', 'null_ctx']


class Ctx(object):
    _parent = None
    default_values = dict(
        _lang = None,
        _scopes = UnboundLocalError,
        _translator = None,
        base_categories_slug = None,
        category_tags_slug = None,
        container_base_url = None,
        distance = None,  # Max distance in km
        gadget_id = None,
        hide_directory = False,
        req = None,
        subscriber = None,
        )
    env_keys = ('_lang', '_scopes', '_translator')

    def __init__(self, req = None):
        if req is not None:
            self.req = req
            etalagepassim_env = req.environ.get('etalagepassim', {})
            for key in object.__getattribute__(self, 'env_keys'):
                value = etalagepassim_env.get(key)
                if value is not None:
                    setattr(self, key, value)

    def __getattribute__(self, name):
        try:
            return object.__getattribute__(self, name)
        except AttributeError:
            parent = object.__getattribute__(self, '_parent')
            if parent is None:
                default_values = object.__getattribute__(self, 'default_values')
                if name in default_values:
                    return default_values[name]
                raise
            return getattr(parent, name)

    @property
    def _(self):
        return self.translator.ugettext

    def blank_req(self, path, environ = None, base_url = None, headers = None, POST = None, **kw):
        env = environ.copy() if environ else {}
        etalagepassim_env = env.setdefault('etalagepassim', {})
        for key in self.env_keys:
            value = getattr(self, key)
            if value is not None:
                etalagepassim_env[key] = value
        return webob.Request.blank(path, environ = env, base_url = base_url, headers = headers, POST = POST, **kw)

    def get_containing(self, name, depth = 0):
        """Return the n-th (n = ``depth``) context containing attribute named ``name``."""
        ctx_dict = object.__getattribute__(self, '__dict__')
        if name in ctx_dict:
            if depth <= 0:
                return self
            depth -= 1
        parent = ctx_dict.get('_parent')
        if parent is None:
            return None
        return parent.get_containing(name, depth = depth)

    def get_inherited(self, name, default = UnboundLocalError, depth = 1):
        ctx = self.get_containing(name, depth = depth)
        if ctx is None:
            if default is UnboundLocalError:
                raise AttributeError('Attribute %s not found in %s' % (name, self))
            return default
        return object.__getattribute__(ctx, name)

    def iter(self):
        yield self
        parent = object.__getattribute__(self, '_parent')
        if parent is not None:
            for ancestor in parent.iter():
                yield ancestor

    def iter_containing(self, name):
        ctx_dict = object.__getattribute__(self, '__dict__')
        if name in ctx_dict:
            yield self
        parent = ctx_dict.get('_parent')
        if parent is not None:
            for ancestor in parent.iter_containing(name):
                yield ancestor

    def iter_inherited(self, name):
        for ctx in self.iter_containing(name):
            yield object.__getattribute__(ctx, name)

    def lang_del(self):
        del self._lang
        if self.req is not None and self.req.environ.get('etalagepassim') is not None \
                and '_lang' in self.req.environ['etalagepassim']:
            del self.req.environ['etalagepassim']['_lang']

    def lang_get(self):
        if self._lang is None:
            # self._lang = self.req.accept_language.best_matches('en-US') if self.req is not None else []
            # Note: Don't forget to add country-less language code when only a "language-COUNTRY" code is given.
            self._lang = ['fr-FR', 'fr']
            if self.req is not None:
                self.req.environ.setdefault('etalagepassim', {})['_lang'] = self._lang
        return self._lang

    def lang_set(self, lang):
        self._lang = lang
        if self.req is not None:
            self.req.environ.setdefault('etalagepassim', {})['_lang'] = self._lang
        # Reinitialize translator for new languages.
        if self._translator is not None:
            # Don't del self._translator, because attribute _translator can be defined in a parent.
            self._translator = None
            if self.req is not None and self.req.environ.get('etalagepassim') is not None \
                    and '_translator' in self.req.environ['etalagepassim']:
                del self.req.environ['etalagepassim']['_translator']

    lang = property(lang_get, lang_set, lang_del)

    def new(self, **kwargs):
        ctx = Ctx()
        ctx._parent = self
        for name, value in kwargs.iteritems():
            setattr(ctx, name, value)
        return ctx

    @property
    def parent(self):
        return object.__getattribute__(self, '_parent')

    def scopes_del(self):
        del self._scopes
        if self.req is not None and self.req.environ.get('wenoit_etalagepassim') is not None \
                and '_scopes' in self.req.environ['wenoit_etalagepassim']:
            del self.req.environ['wenoit_etalagepassim']['_scopes']

    def scopes_get(self):
        return self._scopes

    def scopes_set(self, scopes):
        self._scopes = scopes
        if self.req is not None:
            self.req.environ.setdefault('wenoit_etalagepassim', {})['_scopes'] = scopes

    scopes = property(scopes_get, scopes_set, scopes_del)

    @property
    def session(self):
        return self.req.environ.get('beaker.session') if self.req is not None else None

    @property
    def translator(self):
        """Get a valid translator object from one or several languages names."""
        if self._translator is None:
            languages = self.lang
            if not languages:
                return gettext.NullTranslations()
            if not isinstance(languages, list):
                languages = [languages]
            translator = gettext.NullTranslations()
            i18n_dir_by_plugin_name = conf['i18n_dir_by_plugin_name'] or {}
            for name, i18n_dir in [
                    ('biryani', conf['biryani_i18n_dir']),
                    (conf['package_slug'], conf['i18n_dir']),
                    ] + sorted(i18n_dir_by_plugin_name.iteritems()):
                if name is not None and i18n_dir is not None:
                    translator = new_translator(name, i18n_dir, languages, fallback = translator)
            self._translator = translator
        return self._translator


null_ctx = Ctx()
null_ctx.lang = ['fr-FR', 'fr']


def new_translator(domain, localedir, languages, fallback = None):
    new = gettext.translation(domain, localedir, fallback = True, languages = languages)
    if fallback is not None:
        new.add_fallback(fallback)
    return new
