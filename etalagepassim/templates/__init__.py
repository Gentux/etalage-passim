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


"""Mako templates rendering"""


import json


js = lambda x: json.dumps(x, encoding = 'utf-8', ensure_ascii = False)
lookup = None  # TemplateLookup inited by function load_environment.


def render(ctx, template_path, **kw):
    return lookup.get_template(template_path).render_unicode(
        _ = ctx.translator.ugettext,
        ctx = ctx,
        js = js,
        N_ = lambda message: message,
        req = ctx.req,
        **kw).strip()


def render_def(ctx, template_path, def_name, **kw):
    return lookup.get_template(template_path).get_def(def_name).render_unicode(
        _ = ctx.translator.ugettext,
        ctx = ctx,
        js = js,
        N_ = lambda message: message,
        req = ctx.req,
        **kw).strip()
