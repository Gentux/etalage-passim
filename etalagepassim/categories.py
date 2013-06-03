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


"""Objects for RAM-based POIs"""


import logging

from biryani import strings
from suq import representations

from . import ramdb


__all__ = ['Category']


log = logging.getLogger(__name__)


class Category(representations.UserRepresentable):
    name = None
    tags_slug = None

    def __init__(self, **attributes):
        if attributes:
            self.set_attributes(**attributes)

    def index(self):
        for word in self.slug.split(u'-'):
            ramdb.categories_slug_by_word.setdefault(word, set()).add(self.slug)
        for tag_slug in (self.tags_slug or set()):
            ramdb.categories_slug_by_tag_slug.setdefault(tag_slug, set()).add(self.slug)

    @classmethod
    def load(cls, category_bson):
        self = cls(
            name = category_bson['title'],
            tags_slug = set(category_bson.get('tags_code') or []) or None,
            )
        ramdb.category_by_slug[self.slug] = self
        return self

    def set_attributes(self, **attributes):
        """Set given attributes and return a boolean stating whether existing attributes have changed."""
        changed = False
        for name, value in attributes.iteritems():
            if value is getattr(self.__class__, name, UnboundLocalError):
                if value is not getattr(self, name, UnboundLocalError):
                    delattr(self, name)
                    changed = True
            elif value is not getattr(self, name, UnboundLocalError):
                setattr(self, name, value)
                changed = True
        return changed

    @property
    def slug(self):
        return strings.slugify(self.name) or None
