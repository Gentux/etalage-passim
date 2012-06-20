# -*- coding: utf-8 -*-


# Etalage-Passim -- Customization of Etalage for Passim
# By: Emmanuel Raviart <eraviart@easter-eggs.com>
#
# Copyright (C) 2012 Easter-eggs
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


from etalage import pois, ramdb


class Poi(pois.Poi):
    @classmethod
    def index_pois(cls):
        for self in ramdb.poi_by_id.itervalues():
            if self.schema_name == 'ServiceInfo':
                ramdb.indexed_pois_id.add(self._id)
                for poi in self.iter_descendant_or_self_pois():
                    poi.index(self._id)
        for self in ramdb.poi_by_id.itervalues():
            del self.bson

#    @classmethod
#    def index_pois(cls):
#        for self in ramdb.poi_by_id.itervalues():
#            if self.schema_name == 'ServiceInfo':
#                ramdb.indexed_pois_id.add(self._id)
#            self.index(self._id)
#            del self.bson

    def iter_descendant_or_self_pois(self, visited_pois_id = None):
        if visited_pois_id is None:
            visited_pois_id = set()
        if self._id not in visited_pois_id:
            visited_pois_id.add(self._id)
            yield self
            for field in self.fields:
                if field.id == 'link':
                    if field.value is not None:
                        linked_poi = ramdb.poi_by_id.get(field.value)
                        if linked_poi is not None:
                            for poi in linked_poi.iter_descendant_or_self_pois(visited_pois_id):
                                yield poi
                elif field.id == 'links':
                    if field.value is not None:
                        for linked_poi_id in field.value:
                            linked_poi = ramdb.poi_by_id.get(linked_poi_id)
                            if linked_poi is not None:
                                for poi in linked_poi.iter_descendant_or_self_pois(visited_pois_id):
                                    yield poi

    def generate_all_fields(self):
        fields = super(Poi, self).generate_all_fields()
        pois.pop_first_field(fields, 'last-update')
        return fields
