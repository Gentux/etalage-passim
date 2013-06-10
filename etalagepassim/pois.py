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


"""Objects for POIs"""


from copy import copy
import datetime
import itertools
import logging
import math
import sys
import urlparse
import urllib

import bson
from biryani import strings
from suq import monpyjama, representations
import webob.multidict

from . import conf, conv, ramdb, urls


__all__ = ['Cluster', 'Field', 'get_first_field', 'iter_fields', 'Poi', 'pop_first_field']

log = logging.getLogger(__name__)


class Cluster(representations.UserRepresentable):
    bottom = None  # South latitude of rectangle enclosing all POIs of cluster
    center_latitude = None  # Copy of center_pois[*].geo[0] for quick access
    center_longitude = None  # Copy of center_pois[*].geo[1] for quick access
    center_pois = None  # POIs at the center of cluster, sharing the same coordinates
     # False = Not competent for current territory, None = Competent for any territory or unknown territory,
     # True = Competent for current territory
    competent = False
    count = None  # Number of POIs in cluster
    left = None  # West longitude of rectangle enclosing all POIs of cluster
    right = None  # East longitude of rectangle enclosing all POIs of cluster
    top = None  # North latitude of rectangle enclosing all POIs of cluster


class Field(representations.UserRepresentable):
    id = None  # Petitpois id = format of value
    kind = None
    label = None
    relation = None
    type = None
    value = None

    def __init__(self, **attributes):
        if attributes:
            self.set_attributes(**attributes)

    def get_first_field(self, id, label = None):
        # Note: Only for composite fields.
        return get_first_field(self.value, id, label = label)

    @property
    def is_composite(self):
        return self.id in ('adr', 'date-range', 'source')

    def iter_csv_fields(self, ctx, counts_by_label, parent_ref = None):
        """Iter fields, entering inside composite fields."""
        if self.value is not None:
            if self.is_composite:
                same_label_index = counts_by_label.get(self.label, 0)
                ref = (parent_ref or []) + [self.label, same_label_index]
                field_counts_by_label = {}
                for field in self.value:
                    for subfield_ref, subfield in field.iter_csv_fields(ctx, field_counts_by_label,
                            parent_ref = ref):
                        yield subfield_ref, subfield
                if field_counts_by_label:
                    # Some subfields were not empty, so increment number of exported fields having the same label.
                    counts_by_label[self.label] = same_label_index + 1
            elif self.id in ('autocompleters', 'checkboxes'):
                field_attributes = self.__dict__.copy()
                field_attributes['value'] = u'\n'.join(self.value)
                field = Field(**field_attributes)
                same_label_index = counts_by_label.get(field.label, 0)
                yield (parent_ref or []) + [field.label, same_label_index], field
                counts_by_label[field.label] = same_label_index + 1
            elif self.id == 'commune':
                field_attributes = self.__dict__.copy()
                field_attributes['label'] = u'Code Insee commune'  # Better than "Commune"
                field = Field(**field_attributes)
                same_label_index = counts_by_label.get(field.label, 0)
                yield (parent_ref or []) + [field.label, same_label_index], field
                counts_by_label[field.label] = same_label_index + 1
            elif self.id == 'geo':
                for field in (
                        Field(id = 'float', value = self.value[0], label = u'Latitude'),
                        Field(id = 'float', value = self.value[1], label = u'Longitude'),
                        Field(id = 'int', value = self.value[2], label = u'Précision'),
                        ):
                    for subfield_ref, subfield in field.iter_csv_fields(ctx, counts_by_label, parent_ref = parent_ref):
                        yield subfield_ref, subfield
            elif self.id == 'links':
                field_attributes = self.__dict__.copy()
                field_attributes['value'] = u'\n'.join(
                    unicode(object_id)
                    for object_id in self.value
                    )
                field = Field(**field_attributes)
                same_label_index = counts_by_label.get(field.label, 0)
                yield (parent_ref or []) + [field.label, same_label_index], field
                counts_by_label[field.label] = same_label_index + 1
            elif self.id == 'poi-last-update':
                last_update_field = copy(self)
                last_update_field.value = last_update_field.value.strftime('%d/%m/%Y')
                last_update_label_index = counts_by_label.get(self.label, 0)
                yield (parent_ref or []) + [self.label, last_update_label_index], last_update_field
                counts_by_label[self.label] = last_update_label_index + 1
            elif self.id == 'postal-distribution':
                postal_code, postal_routing = conv.check(conv.split_postal_distribution)(self.value, state = ctx)
                for field in (
                        Field(id = 'postal-code', value = postal_code, label = u'Code postal'),
                        Field(id = 'postal-routing', value = postal_routing, label = u'Localité'),
                        ):
                    for subfield_ref, subfield in field.iter_csv_fields(ctx, counts_by_label, parent_ref = parent_ref):
                        yield subfield_ref, subfield
            elif self.id == 'street-address':
                for item_value in self.value.split('\n'):
                    item_value = item_value.strip()
                    item_field_attributes = self.__dict__.copy()
                    item_field_attributes['id'] = 'street-address-lines'  # Change ID to avoid infinite recursion.
                    # item_field_attributes['label'] = u'Adresse'  # Better than "N° et libellé de voie"?
                    item_field_attributes['value'] = item_value
                    item_field = Field(**item_field_attributes)
                    for subfield_ref, subfield in item_field.iter_csv_fields(ctx, counts_by_label,
                            parent_ref = parent_ref):
                        yield subfield_ref, subfield
            elif self.id == 'territories':
                territories = [
                    territory
                    for territory in (
                        ramdb.territory_by_id.get(territory_id)
                        for territory_id in self.value
                        )
                    if territory is not None
                    ]
                if territories:
                    field_attributes = self.__dict__.copy()
                    field_attributes['value'] = u'\n'.join(
                        territory.main_postal_distribution_str
                        for territory in territories
                        )
                    field = Field(**field_attributes)
                    same_label_index = counts_by_label.get(field.label, 0)
                    yield (parent_ref or []) + [field.label, same_label_index], field
                    counts_by_label[field.label] = same_label_index + 1
            elif self.id == 'territory':
                territory = ramdb.territory_by_id.get(self.value)
                if territory is not None:
                    field_attributes = self.__dict__.copy()
                    field_attributes['value'] = territory.main_postal_distribution_str
                    field = Field(**field_attributes)
                    same_label_index = counts_by_label.get(field.label, 0)
                    yield (parent_ref or []) + [field.label, same_label_index], field
                    counts_by_label[field.label] = same_label_index + 1
            elif isinstance(self.value, list):
                for item_value in self.value:
                    item_field_attributes = self.__dict__.copy()
                    item_field_attributes['value'] = item_value
                    item_field = Field(**item_field_attributes)
                    for subfield_ref, subfield in item_field.iter_csv_fields(ctx, counts_by_label,
                            parent_ref = parent_ref):
                        yield subfield_ref, subfield
            else:
                # Note: self.value is now always a single value, not a list.
                same_label_index = counts_by_label.get(self.label, 0)
                yield (parent_ref or []) + [self.label, same_label_index], self
                counts_by_label[self.label] = same_label_index + 1

    @property
    def linked_pois_id(self):
        if self.id not in ('link', 'links'):
            return None
        if self.value is None:
            return None
        if isinstance(self.value, list):
            return self.value
        if isinstance(self.value, basestring):
            # When field is a CSV field, links are a linefeed-separated list of IDs
            return [
                bson.objectid.ObjectId(id_str)
                for id_str in self.value.split()
                ]
        return [self.value]

    @classmethod
    def load(cls, id, metadata, value):
        if len(metadata) != (1 if 'kind' in metadata else 0) \
                + (1 if 'label' in metadata else 0) \
                + (1 if 'relation' in metadata else 0) \
                + (1 if 'type' in metadata else 0) \
                + (1 + len(metadata['positions']) if 'positions' in metadata else 0):
            log.warning('Unexpected attributes in field {0}, metadata {1}, value {2}'.format(id, metadata, value))
        if 'positions' in metadata:
            fields_position = {}
            fields = []
            for field_id in metadata['positions']:
                field_position = fields_position.get(field_id, 0)
                fields_position[field_id] = field_position + 1
                field_metadata = metadata[field_id][field_position]
                field_value = value[field_id][field_position]
                fields.append(cls.load(field_id, field_metadata, field_value))
            value = fields or None
        elif id == 'territories':
            # Replace each kind-code with the corresponding territory ID.
            if value is not None:
                value = [
                    territory_id
                    for territory_id in (
                        ramdb.territory_id_by_kind_code.get((territory_kind_code['kind'],
                            territory_kind_code['code']))
                        for territory_kind_code in value
                        )
                    if territory_id is not None
                    ]
        return cls(
            id = id,
            kind = metadata.get('kind'),
            label = metadata['label'],
            relation = metadata.get('relation'),
            type = metadata.get('type'),
            value = value,
            )

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


class Poi(representations.UserRepresentable):
    _id = None
    # IDs of territories for which POI is fully competent. None when POI has no notion of competence territory
    competence_territories_id = None
    fields = None
    geo = None
    ids_by_category_slug = {}
    ids_by_competence_territory_id = {}
    ids_by_coverage = {}
    ids_by_begin_datetime = []
    ids_by_end_datetime = []
    ids_by_last_update_datetime = []
    ids_by_parent_id = {}
    ids_by_presence_territory_id = {}
    ids_by_schema_name = {}
    ids_by_transport_mode = {}
    ids_by_transport_type = {}
    ids_by_word = {}
    indexed_ids = set()
    multimodal_info_service_ids = set()
    instance_by_id = {}
    last_update_datetime = None
    last_update_organization = None
    name = None
    parent_id = None
    petitpois_url = None  # class attribute defined in subclass. URL of Petitpois site
    postal_distribution_str = None
    schema_name = None
    slug_by_id = {}
    street_address = None
    subclass_by_database_name = {}
    theme_slug = None
    weight_by_coverage = {
        u'Départementale': 1,
        u'Locale': 0,
        u'Nationale': 3,
        u'Régionale': 2,
        }

    def __init__(self, **attributes):
        if attributes:
            self.set_attributes(**attributes)

    @classmethod
    def clear_indexes(cls):
        cls.indexed_ids.clear()
        cls.instance_by_id.clear()
        cls.ids_by_parent_id.clear()
        cls.ids_by_category_slug.clear()
        cls.ids_by_competence_territory_id.clear()
        cls.ids_by_presence_territory_id.clear()
        cls.ids_by_word.clear()
        cls.slug_by_id.clear()
        cls.subclass_by_database_name.clear()

        # FIXME: IMPORTED CODE
        cls.ids_by_coverage.clear()
        cls.ids_by_schema_name.clear()
        cls.ids_by_transport_mode.clear()
        cls.ids_by_transport_type.clear()

    @classmethod
    def extract_non_territorial_search_data(cls, ctx, data):
        return dict(
            term = data['term'],
            )

    @classmethod
    def extract_search_inputs_from_params(cls, ctx, params):
        return dict(
            geolocation = params.get('geolocation'),
            term = params.get('term'),
            )

    def generate_all_fields(self):
        """Return all fields of POI including dynamic ones (ie linked fields, etc)."""
        fields = self.fields[:] if self.fields is not None else []

        # Add children POIs as linked fields.
        children = sorted(
            (
                self.instance_by_id[child_id]
                for child_id in self.ids_by_parent_id.get(self._id, set())
                ),
            key = lambda child: (child.schema_name, child.name),
            )
        for child in children:
            fields.append(Field(id = 'link', label = ramdb.schema_title_by_name[child.schema_name],
                value = child._id))

        # Add last-update field.
        fields.append(Field(id = 'last-update', label = u"Dernière mise à jour", value = u' par '.join(
            unicode(fragment)
            for fragment in (
                self.last_update_datetime.strftime('%Y-%m-%d %H:%M') if self.last_update_datetime is not None else None,
                self.last_update_organization,
                )
            if fragment
            )))

        pop_first_field(fields, 'last-update')
        return fields

    def get_first_field(self, id, label = None):
        return get_first_field(self.fields, id, label = label)

    def get_full_url(self, ctx, params_prefix = 'cmq_'):
        if ctx.container_base_url is None:
            return urls.get_full_url(ctx, 'organismes', self.slug, self._id)
        else:
            parsed_container_base_url = urlparse.urlparse(ctx.container_base_url)
            params = dict([
                ('{0}path'.format(params_prefix), urls.get_url(ctx, 'organismes', self.slug, self._id))
                ])
            params.update(dict(urlparse.parse_qsl(parsed_container_base_url.query)))
            return urlparse.urljoin(
                '{0}://{1}{2}'.format(
                    parsed_container_base_url.scheme,
                    parsed_container_base_url.netloc,
                    parsed_container_base_url.path
                    ),
                '?{0}#{0}'.format(urllib.urlencode(params)),
                )

    @classmethod
    def get_search_params_name(cls, ctx):
        return set(
            cls.rename_input_to_param(name)
            for name in cls.extract_search_inputs_from_params(ctx, webob.multidict.MultiDict()).iterkeys()
            )

    @classmethod
    def get_visibility_params_names(cls, ctx):
        visibility_params = list(cls.get_search_params_name(ctx))
        visibility_params.extend([
            'checkboxes',
            'directory',
            'export',
            'gadget',
            'home',
            'legend',
            'list',
            'map',
            'minisite',
            ])
        return [
            'hide_{0}'.format(visibility_param)
            for visibility_param in visibility_params
            ]

    def index(self, indexed_poi_id):
        poi_bson = self.bson
        metadata = poi_bson['metadata']
        for category_slug in (metadata.get('categories-index') or set()):
            self.ids_by_category_slug.setdefault(category_slug, set()).add(indexed_poi_id)

        if conf['index.date.field']:
            for date_range_index, date_range_metadata in enumerate(metadata.get('date-range') or []):
                if date_range_metadata['label'] == conf['index.date.field']:
                    date_range_values = poi_bson['date-range'][date_range_index]
                    date_range_begin = date_range_values.get('date-range-begin', [None])[0]
                    date_range_end = date_range_values.get('date-range-end', [None])[0]

                    if date_range_begin is not None:
                        for index, (begin_datetime, poi_id) in enumerate(self.ids_by_begin_datetime):
                            if begin_datetime is not None and begin_datetime < date_range_begin:
                                break
                    else:
                        index = 0
                    self.ids_by_begin_datetime.insert(index, (date_range_begin, indexed_poi_id))
                    if date_range_end is not None:
                        for index, (end_datetime, poi_id) in enumerate(self.ids_by_end_datetime):
                            if end_datetime is not None and end_datetime > date_range_end:
                                break
                    else:
                        index = 0
                    self.ids_by_end_datetime.insert(index, (date_range_end, indexed_poi_id))
            if not metadata.get('date-range'):
                self.ids_by_begin_datetime.append((None, indexed_poi_id))
                self.ids_by_end_datetime.append((None, indexed_poi_id))
        self.ids_by_last_update_datetime.append((self.last_update_datetime, indexed_poi_id))

        for i, territory_metadata in enumerate(metadata.get('territories') or []):
            # Note: Don't fail when territory doesn't exist, because Passim can be configured to ignore some kinds
            # of territories (cf conf['territories_kinds']).
            self.competence_territories_id = set(
                territory_id
                for territory_id in (
                    ramdb.territory_id_by_kind_code.get((territory_kind_code['kind'], territory_kind_code['code']))
                    for territory_kind_code in poi_bson['territories'][i]
                    )
                if territory_id is not None
                )
            for territory_id in self.competence_territories_id:
                self.ids_by_competence_territory_id.setdefault(territory_id, set()).add(indexed_poi_id)
            break
        if not self.competence_territories_id:
            self.ids_by_competence_territory_id.setdefault(None, set()).add(indexed_poi_id)

        poi_territories_id = set(
            territory_id
            for territory_id in (
                ramdb.territory_id_by_kind_code.get((territory_kind_code['kind'], territory_kind_code['code']))
                for territory_kind_code in metadata['territories-index']
                if territory_kind_code['kind'] not in (u'Country', u'InternationalOrganization')
                )
            if territory_id is not None
            ) if metadata.get('territories-index') is not None else None
        for territory_id in (poi_territories_id or set()):
            self.ids_by_presence_territory_id.setdefault(territory_id, set()).add(indexed_poi_id)

        for word in strings.slugify(self.name).split(u'-'):
            self.ids_by_word.setdefault(word, set()).add(indexed_poi_id)
        self.slug_by_id[indexed_poi_id] = strings.slugify(self.name)

        if self.schema_name == 'OffreTransport':
            if not self.competence_territories_id and not self.instance_by_id[indexed_poi_id].competence_territories_id:
                france_id = ramdb.territory_id_by_kind_code[(u'Country', u'FR')]
                self.competence_territories_id = set([france_id])
                self.ids_by_competence_territory_id.setdefault(france_id, set()).add(indexed_poi_id)

            for field in self.fields:
                field_slug = strings.slugify(field.label)
                if field.id == 'checkboxes':
                    if field_slug == 'mode-de-transport' and field.value is not None:
                        for transport_mode in field.value:
                            self.ids_by_transport_mode.setdefault(transport_mode, set()).add(
                                indexed_poi_id)
                if field.id == 'select':
                    if field_slug == 'couverture-territoriale' and field.value is not None:
                        self.ids_by_coverage.setdefault(field.value, set()).add(indexed_poi_id)
                    elif field_slug == 'type-de-transport' and field.value is not None:
                        self.ids_by_transport_type.setdefault(field.value, set()).add(indexed_poi_id)

        self.ids_by_schema_name.setdefault(self.schema_name, set()).add(indexed_poi_id)

    @classmethod
    def index_pois(cls):
        for self in cls.instance_by_id.itervalues():
            if self.is_multimodal_info_service():
                cls.multimodal_info_service_ids.add(self._id)
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

    def is_multimodal_info_service(self):
        for field in self.fields:
            if field.id == 'boolean' and strings.slugify(field.label) == 'service-d-information-multimodale':
                return conv.check(conv.guess_bool(field.value))

    @classmethod
    def is_search_param_visible(cls, ctx, name):
        param_visibility_name = 'hide_{0}'.format(name)
        return getattr(ctx, param_visibility_name, False) \
            if param_visibility_name.startswith('show_') \
            else not getattr(ctx, param_visibility_name, False)

    def iter_csv_fields(self, ctx):
        counts_by_label = {}

        id_field = Field(id = 'poi-id', value = self._id, label = u'Identifiant')
        for subfield_ref, subfield in id_field.iter_csv_fields(ctx, counts_by_label):
            yield subfield_ref, subfield

        last_update_field = Field(
            id = 'poi-last-update',
            value = self.last_update_datetime,
            label = u'Date de dernière modification'
            )
        for subfield_ref, subfield in last_update_field.iter_csv_fields(ctx, counts_by_label):
            yield subfield_ref, subfield

        if self.fields is not None:
            for field in self.fields:
                for subfield_ref, subfield in field.iter_csv_fields(ctx, counts_by_label):
                    yield subfield_ref, subfield

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
            schemas_name = None, term = None, transport_modes = None, transport_types = None):
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
        if term and isinstance(term, basestring):
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

        for transport_mode in (transport_modes or []):
            transport_mode_pois_id = cls.ids_by_transport_mode.get(transport_mode)
            if not transport_mode_pois_id:
                return set()
            intersected_sets.append(transport_mode_pois_id)

        for transport_type in (transport_types or []):
            transport_type_pois_id = cls.ids_by_transport_type.get(transport_type)
            if not transport_type_pois_id:
                return set()
            intersected_sets.append(transport_type_pois_id)

        found_pois_id = ramdb.intersection_set(intersected_sets)
        if found_pois_id is None:
            return cls.indexed_ids
        return found_pois_id

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
    def load(cls, poi_bson):
        metadata = poi_bson['metadata']
        last_update = metadata['last-update']
        if poi_bson.get('geo') is None:
            geo = None
        else:
            geo = poi_bson['geo'][0]
            if len(geo) > 2 and geo[2] == 0:
                # Don't use geographical coordinates with a 0 accuracy because their coordinates may be None.
                geo = None
        self = cls(
            _id = poi_bson['_id'],
            geo = geo,
            last_update_datetime = last_update['date'],
            last_update_organization = last_update['organization'],
            name = metadata['title'],
            schema_name = metadata['schema-name'],
            )

        if conf['theme_field'] is None:
            theme_field_id = None
            theme_field_name = None
        else:
            theme_field_id = conf['theme_field']['id']
            theme_field_name = conf['theme_field'].get('name')
        fields_position = {}
        fields = []
        for field_id in metadata['positions']:
            field_position = fields_position.get(field_id, 0)
            fields_position[field_id] = field_position + 1
            field_metadata = metadata[field_id][field_position]
            field_value = poi_bson[field_id][field_position]
            field = Field.load(field_id, field_metadata, field_value)
            if field.id == u'adr' and self.postal_distribution_str is None:
                for sub_field in (field.value or []):
                    if sub_field.id == u'postal-distribution':
                        self.postal_distribution_str = sub_field.value
                    elif sub_field.id == u'street-address':
                        self.street_address = sub_field.value
            elif field.id == u'link' and field.relation == u'parent':
                assert self.parent is None, str(self)
                self.parent_id = field.value

            if field_id == theme_field_id and (
                    theme_field_name is None or theme_field_name == strings.slugify(field.label)):
                if field.id == u'organism-type':
                    organism_type_slug = ramdb.category_slug_by_pivot_code.get(field.value)
                    if organism_type_slug is None:
                        log.warning('Ignoring organism type "{0}" without matching category.'.format(field.value))
                    else:
                        self.theme_slug = organism_type_slug
                else:
                    theme_slug = strings.slugify(field.value)
                    if theme_slug in ramdb.category_by_slug:
                        self.theme_slug = theme_slug
                    else:
                        log.warning('Ignoring theme "{0}" without matching category.'.format(field.value))

            fields.append(field)
        if fields:
            self.fields = fields

        # Temporarily store bson in poi because it is needed by index_pois.
        self.bson = poi_bson

        cls.instance_by_id[self._id] = self
        if self.parent_id is not None:
            cls.ids_by_parent_id.setdefault(self.parent_id, set()).add(self._id)
        return self

    @classmethod
    def load_pois(cls):
        from . import model
        for db, petitpois_url in zip(model.dbs, conf['petitpois_url']):
            cls.subclass_by_database_name[db.name] = poi_subclass = type('PoiWithPetitpois', (cls,), dict(
                petitpois_url = petitpois_url,
                ))
            for poi_bson in db.pois.find({'metadata.deleted': {'$exists': False}}):
                poi_subclass.load(poi_bson)

    @classmethod
    def make_inputs_to_search_data(cls):
        return conv.struct(
            dict(
                geolocation = conv.pipe(
                    conv.input_to_coordinates,
                    conv.coordinates_to_territory,
                    ),
                term = conv.first_match(conv.input_to_postal_distribution_to_geolocated_territory, conv.input_to_slug),
                ),
            default = 'drop',
            keep_none_values = True,
            )

    @property
    def parent(self):
        if self.parent_id is None:
            return None
        return self.instance_by_id.get(self.parent_id)

    @classmethod
    def rename_input_to_param(cls, input_name):
        return dict(
            coverages = u'coverage',
            schemas_name = u'schema',
            transport_modes = u'transport_mode',
            transport_types = u'transport_type',
            ).get(input_name, input_name)

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
        return strings.slugify(self.name)

    @classmethod
    def sort_and_paginate_pois_list(cls, ctx, pager, poi_by_id, sort_key = None, **other_search_data):
        if sort_key is not None:
            return sorted(
                [poi for poi in poi_by_id.itervalues()],
                key = lambda poi: getattr(poi, sort_key, poi.name) if sort_key is not None else poi.name,
                reverse = True,
                )[pager.first_item_index:pager.last_item_number]
        if pager is not None:
            return itertools.islice(
                cls.iter_sort_pois_list(ctx, poi_by_id),
                pager.first_item_index,
                pager.last_item_number,
                )
        else:
            return list(cls.iter_sort_pois_list(ctx, poi_by_id))


def get_first_field(fields, id, label = None):
    for field in iter_fields(fields, id, label = label):
        return field
    return None


def iter_fields(fields, id, label = None):
    if fields is not None:
        for field in fields:
            if field.id == id and (label is None or field.label == label):
                yield field


def pop_first_field(fields, id, label = None):
    for field in iter_fields(fields, id, label = label):
        fields.remove(field)
        return field
    return None
