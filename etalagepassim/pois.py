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


from biryani import strings

from etalage import conv, pois, ramdb


class Poi(pois.Poi):
    ids_by_coverage = {}  # class attribute
    ids_by_schema_name = {}  # class attribute
    ids_by_transport_type = {}  # class attribute

    @classmethod
    def clear_indexes(cls):
        super(Poi, cls).clear_indexes()

        cls.ids_by_coverage.clear()
        cls.ids_by_schema_name.clear()
        cls.ids_by_transport_type.clear()

    @classmethod
    def extract_non_territorial_search_data(cls, ctx, data):
        return dict(
            coverage = data['coverage'],
            schemas_name = data['schemas_name'],
            term = data['term'],
            transport_type = data['transport_type'],
            )

    @classmethod
    def extract_search_inputs_from_params(cls, ctx, params):
        return dict(
            coverage = params.get('coverage'),
            schemas_name = params.getall('schema'),
            filter = params.get('filter'),
            term = params.get('term'),
            territory = params.get('territory'),
            transport_type = params.get('transport_type'),
            )

    def index(self, indexed_poi_id):
        super(Poi, self).index(indexed_poi_id)

        if self.schema_name == 'OffreTransport':
            if not self.competence_territories_id:
                france_id = ramdb.territory_id_by_kind_code[(u'Country', u'FR')]
                self.competence_territories_id = set([france_id])
                self.ids_by_competence_territory_id.setdefault(france_id, set()).add(indexed_poi_id)

            coverage_field = self.get_first_field(u'select', u'Couverture territoriale')
            if coverage_field is not None and coverage_field.value is not None:
                self.ids_by_coverage.setdefault(coverage_field.value, set()).add(indexed_poi_id)

            transport_type_field = self.get_first_field(u'select', u'Type de transport')
            if transport_type_field is not None and transport_type_field.value is not None:
                self.ids_by_transport_type.setdefault(transport_type_field.value, set()).add(indexed_poi_id)

        self.ids_by_schema_name.setdefault(self.schema_name, set()).add(indexed_poi_id)

    @classmethod
    def index_pois(cls):
        for self in cls.instance_by_id.itervalues():
            if self.schema_name == 'ServiceInfo':
                cls.indexed_ids.add(self._id)
                for poi in self.iter_descendant_or_self_pois():
                    poi.index(self._id)
        for self in cls.instance_by_id.itervalues():
            del self.bson

    def iter_descendant_or_self_pois(self, visited_pois_id = None):
        if visited_pois_id is None:
            visited_pois_id = set()
        if self._id not in visited_pois_id:
            visited_pois_id.add(self._id)
            yield self
            for field in self.fields:
                if field.id == 'link':
                    if field.value is not None:
                        linked_poi = self.instance_by_id.get(field.value)
                        if linked_poi is not None:
                            for poi in linked_poi.iter_descendant_or_self_pois(visited_pois_id):
                                yield poi
                elif field.id == 'links':
                    if field.value is not None:
                        for linked_poi_id in field.value:
                            linked_poi = self.instance_by_id.get(linked_poi_id)
                            if linked_poi is not None:
                                for poi in linked_poi.iter_descendant_or_self_pois(visited_pois_id):
                                    yield poi
            for child_id in (self.ids_by_parent_id.get(self._id) or set()):
                child = self.instance_by_id.get(child_id)
                if child is not None:
                    for poi in child.iter_descendant_or_self_pois(visited_pois_id):
                        yield poi

    @classmethod
    def iter_ids(cls, ctx, competence_territories_id = None, coverage = None, presence_territory = None,
            schemas_name = None, term = None, transport_type = None):
        intersected_sets = []

        if competence_territories_id is not None:
            territory_competent_pois_id = ramdb.union_set(
                cls.ids_by_competence_territory_id.get(competence_territory_id)
                for competence_territory_id in competence_territories_id
                )
            if not territory_competent_pois_id:
                return set()
            intersected_sets.append(territory_competent_pois_id)

        if coverage is not None:
            coverage_pois_id = cls.ids_by_coverage.get(coverage)
            if not coverage_pois_id:
                return set()
            intersected_sets.append(coverage_pois_id)

        if presence_territory is not None:
            territory_present_pois_id = cls.ids_by_presence_territory_id.get(presence_territory._id)
            if not territory_present_pois_id:
                return set()
            intersected_sets.append(territory_present_pois_id)

        for schema_name in set(schemas_name or []):
            schema_pois_id = cls.ids_by_schema_name.get(schema_name)
            if not schema_pois_id:
                return set()
            intersected_sets.append(schema_pois_id)

        # We should filter on term *after* having looked for competent organizations. Otherwise, when no organization
        # matching term is found, the nearest organizations will be used even when there are competent organizations
        # (that don't match the term).
        if term:
            prefixes = strings.slugify(term).split(u'-')
            pois_id_by_prefix = {}
            for prefix in prefixes:
                if prefix in pois_id_by_prefix:
                    # TODO? Handle pois with several words sharing the same prefix?
                    continue
                pois_id_by_prefix[prefix] = ramdb.union_set(
                    pois_id
                    for word, pois_id in cls.ids_by_word.iteritems()
                    if word.startswith(prefix)
                    ) or set()
            intersected_sets.extend(pois_id_by_prefix.itervalues())

        if transport_type is not None:
            transport_type_pois_id = cls.ids_by_transport_type.get(transport_type)
            if not transport_type_pois_id:
                return set()
            intersected_sets.append(transport_type_pois_id)

        found_pois_id = ramdb.intersection_set(intersected_sets)
        if found_pois_id is None:
            return cls.indexed_ids
        return found_pois_id

    def generate_all_fields(self):
        fields = super(Poi, self).generate_all_fields()
        pois.pop_first_field(fields, 'last-update')
        return fields

    @classmethod
    def make_inputs_to_search_data(cls):
        return conv.struct(
            dict(
                coverage = conv.pipe(
                    conv.cleanup_line,
                    conv.test_in(cls.ids_by_coverage),
                    ),
                filter = conv.input_to_filter,
                schemas_name = conv.uniform_sequence(conv.pipe(
                    conv.cleanup_line,
                    conv.test_in(ramdb.schema_title_by_name),
                    )),
                term = conv.input_to_slug,
                territory = conv.input_to_postal_distribution_to_geolocated_territory,
                transport_type = conv.pipe(
                    conv.cleanup_line,
                    conv.test_in(cls.ids_by_transport_type),
                    ),
                ),
            default = 'drop',
            keep_none_values = True,
            )

    @classmethod
    def rename_input_to_param(cls, input_name):
        return dict(
            schemas_name = u'schema',
            ).get(input_name, input_name)
