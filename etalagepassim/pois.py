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


import itertools

from biryani import strings

from etalage import conv, pois, ramdb


class Poi(pois.Poi):
    ids_by_coverage = {}  # class attribute
    ids_by_schema_name = {}  # class attribute
    ids_by_transport_type = {}  # class attribute
    weight_by_coverage = {
        u'Départementale': 1,
        u'Locale': 0,
        u'Nationale': 3,
        u'Régionale': 2,
        }

    @classmethod
    def clear_indexes(cls):
        super(Poi, cls).clear_indexes()

        cls.ids_by_coverage.clear()
        cls.ids_by_schema_name.clear()
        cls.ids_by_transport_type.clear()

    @classmethod
    def extract_non_territorial_search_data(cls, ctx, data):
        return dict(
            coverages = data['coverages'],
            schemas_name = data['schemas_name'],
            term = data['term'],
            transport_types = data['transport_types'],
            )

    @classmethod
    def extract_search_inputs_from_params(cls, ctx, params):
        return dict(
            coverages = params.getall('coverage'),
            schemas_name = params.getall('schema'),
            filter = params.get('filter'),
            term = params.get('term'),
            territory = params.get('territory'),
            transport_types = params.getall('transport_type'),
            )

    def index(self, indexed_poi_id):
        super(Poi, self).index(indexed_poi_id)

        if self.schema_name == 'OffreTransport':
            if not self.competence_territories_id and not self.instance_by_id[indexed_poi_id].competence_territories_id:
                france_id = ramdb.territory_id_by_kind_code[(u'Country', u'FR')]
                self.competence_territories_id = set([france_id])
                self.ids_by_competence_territory_id.setdefault(france_id, set()).add(indexed_poi_id)

            for field in self.fields:
                field_slug = strings.slugify(field.label)
                if field.id == 'select':
                    if field_slug == 'couverture-territoriale' and field.value is not None:
                        self.ids_by_coverage.setdefault(field.value, set()).add(indexed_poi_id)
                    elif field_slug == 'type-de-transport' and field.value is not None:
                        self.ids_by_transport_type.setdefault(field.value, set()).add(indexed_poi_id)

        self.ids_by_schema_name.setdefault(self.schema_name, set()).add(indexed_poi_id)

    @classmethod
    def index_pois(cls):
        for self in cls.instance_by_id.itervalues():
            if self.schema_name == 'ServiceInfo':
                cls.indexed_ids.add(self._id)
                for poi in self.iter_descendant_or_self_pois():
                    if self.competence_territories_id is not None and poi.schema_name != 'ServiceInfo' \
                            and poi.bson['metadata'].get('territories'):
                        # When "ServiceInfo" contains a field "territories" (named "Territoire couvert") use it as
                        # competence territories and ignore the "territories" in children (especially of schema
                        # "OffreTransport").
                        poi_territories_metadata = poi.bson['metadata'].pop('territories')
                        poi_territories = poi.bson.pop('territories')
                        poi.index(self._id)
                        poi.bson['metadata']['territories'] = poi_territories_metadata
                        poi.bson['territories'] = poi_territories
                    else:
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
                        if linked_poi is not None and linked_poi.schema_name != 'ServiceInfo':
                            for poi in linked_poi.iter_descendant_or_self_pois(visited_pois_id):
                                yield poi
                elif field.id == 'links':
                    if field.value is not None:
                        for linked_poi_id in field.value:
                            linked_poi = self.instance_by_id.get(linked_poi_id)
                            if linked_poi is not None and linked_poi.schema_name != 'ServiceInfo':
                                for poi in linked_poi.iter_descendant_or_self_pois(visited_pois_id):
                                    yield poi
            for child_id in (self.ids_by_parent_id.get(self._id) or set()):
                child = self.instance_by_id.get(child_id)
                if child is not None and child.schema_name != 'ServiceInfo':
                    for poi in child.iter_descendant_or_self_pois(visited_pois_id):
                        yield poi

    @classmethod
    def iter_ids(cls, ctx, competence_territories_id = None, coverages = None, presence_territory = None,
            schemas_name = None, term = None, transport_types = None):
        intersected_sets = []

        if competence_territories_id is not None:
            territory_competent_pois_id = ramdb.union_set(
                cls.ids_by_competence_territory_id.get(competence_territory_id)
                for competence_territory_id in competence_territories_id
                )
            if not territory_competent_pois_id:
                return set()
            intersected_sets.append(territory_competent_pois_id)

        for coverage in (coverages or []):
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

        for transport_type in (transport_types or []):
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
    def iter_sort_pois_list(cls, ctx, poi_by_id):
        encountered_pois_id = set()
        for weight, coverage in sorted(
                (weight, coverage)
                for coverage, weight in cls.weight_by_coverage.iteritems()
                ):
            for poi_id in (cls.ids_by_coverage.get(coverage) or []):
                poi = poi_by_id.get(poi_id)
                if poi is None:
                    continue
                if poi_id in encountered_pois_id:
                    continue
                encountered_pois_id.add(poi_id)
                yield poi

    @classmethod
    def make_inputs_to_search_data(cls):
        return conv.struct(
            dict(
                coverages = conv.uniform_sequence(conv.pipe(
                    conv.cleanup_line,
                    conv.test_in(cls.ids_by_coverage),
                    )),
                filter = conv.input_to_filter,
                schemas_name = conv.uniform_sequence(conv.pipe(
                    conv.cleanup_line,
                    conv.test_in(ramdb.schema_title_by_name),
                    )),
                term = conv.input_to_slug,
                territory = conv.input_to_postal_distribution_to_geolocated_territory,
                transport_types = conv.uniform_sequence(conv.pipe(
                    conv.cleanup_line,
                    conv.test_in(cls.ids_by_transport_type),
                    )),
                ),
            default = 'drop',
            keep_none_values = True,
            )

    @classmethod
    def rename_input_to_param(cls, input_name):
        return dict(
            coverages = u'coverage',
            schemas_name = u'schema',
            transport_types = u'transport_type',
            ).get(input_name, input_name)

    @classmethod
    def sort_and_paginate_pois_list(cls, ctx, pager, poi_by_id, **other_search_data):
        return list(itertools.islice(cls.iter_sort_pois_list(ctx, poi_by_id), pager.first_item_index,
            pager.last_item_number))
