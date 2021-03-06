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


"""Conversion functions"""


from cStringIO import StringIO
import csv
import math
import re

from biryani.baseconv import *
from biryani.bsonconv import *
from biryani.objectconv import *
from biryani.frconv import *
from biryani import states, strings
import bson
from territoria2.conv import split_postal_distribution, input_to_postal_distribution
import xlwt


default_state = states.default_state
N_ = lambda message: message
latitude_longitude_regex = re.compile(r'^[+-]?\d+\.\d+,[+-]?\d+\.\d+$')


# Level-1 Converters


def bson_to_site(bson, state = None):
    from . import model
    if state is None:
        state = default_state
    return pipe(
        struct(
            dict(
                subscriptions = uniform_sequence(function(model.Subscription.from_bson)),
                ),
            default = noop,
            ),
        make_dict_to_object(model.Site),
        )(bson, state = state)


def bson_to_subscriber(bson, state = None):
    from . import model
    if state is None:
        state = default_state
    return pipe(
        struct(
            dict(
                sites = uniform_sequence(function(model.Site.from_bson)),
                users = uniform_sequence(function(model.User.from_bson)),
                ),
            default = noop,
            ),
        make_dict_to_object(model.Subscriber),
        )(bson, state = state)


def bson_to_subscription(bson, state = None):
    from . import model
    if state is None:
        state = default_state
    return make_dict_to_object(model.Subscription)(bson, state = state)


def bson_to_user(bson, state = None):
    from . import model
    if state is None:
        state = default_state
    return make_dict_to_object(model.User)(bson, state = state)


def csv_infos_to_csv_bytes(csv_infos_by_schema_name, state = None):
    from . import ramdb
    if csv_infos_by_schema_name is None:
        return None, None
    if state is None:
        state = default_state
    csv_bytes_by_name = {}
    for schema_name, csv_infos in csv_infos_by_schema_name.iteritems():
        csv_file = StringIO()
        writer = csv.writer(csv_file, delimiter = ',', quotechar = '"', quoting = csv.QUOTE_MINIMAL)
        writer.writerow([
            (label or u'').encode("utf-8")
            for label in csv_infos['columns_label']
            ])
        for row in csv_infos['rows']:
            writer.writerow([
                unicode(cell).encode('utf-8') if cell is not None else None
                for cell in row
                ])
        csv_filename = '{0}.csv'.format(strings.slugify(ramdb.schema_title_by_name.get(schema_name, schema_name)))
        csv_bytes_by_name[csv_filename] = csv_file.getvalue()
    return csv_bytes_by_name or None, None


def csv_infos_to_excel_bytes(csv_infos_by_schema_name, state = None):
    from . import ramdb
    if csv_infos_by_schema_name is None:
        return None, None
    if state is None:
        state = default_state
    book = xlwt.Workbook(encoding = 'utf-8')
    for schema_name, csv_infos in csv_infos_by_schema_name.iteritems():
        sheet = book.add_sheet(ramdb.schema_title_by_name.get(schema_name, schema_name)[:31])
        sheet_row = sheet.row(0)
        for column_index, label in enumerate(csv_infos['columns_label']):
            sheet_row.write(column_index, label or u'')
        for row_index, row in enumerate(csv_infos['rows'], 1):
            if row_index % 1000 == 0:
                sheet.flush_row_data()
            sheet_row = sheet.row(row_index)
            for column_index, cell in enumerate(row):
                if cell is not None:
                    sheet_row.write(column_index,
                        unicode(cell) if isinstance(cell, bson.objectid.ObjectId) else cell,
                        )
        sheet.flush_row_data()
    excel_file = StringIO()
    book.save(excel_file)
    return excel_file.getvalue(), None


def id_name_dict_list_to_ignored_fields(value, state = None):
    if not value:
        return None, None
    if state is None:
        state = default_state
    ignored_fields = {}
    for id_name_dict in value:
        id = id_name_dict['id']
        name = id_name_dict.get('name')
        if id in ignored_fields:
            ignored_field = ignored_fields[id]
            if ignored_field is not None:
                ignored_field.add(name)
        else:
            if name is None:
                ignored_fields[id] = None
            else:
                ignored_fields[id] = set([name])
    return ignored_fields, None


def id_to_poi(poi_id, state = None):
    import model
    if poi_id is None:
        return poi_id, None
    if state is None:
        state = default_state
    poi = model.Poi.instance_by_id.get(poi_id)
    if poi is None:
        return poi_id, state._("POI {0} doesn't exist").format(poi_id)
    return poi, None


def input_to_category_slug(value, state = None):
    from . import ramdb
    if state is None:
        state = default_state
    return pipe(
        input_to_tag_slug,
        function(lambda slug: ramdb.category_by_slug[slug]),
        test(lambda category: (category.tags_slug or set()).issuperset(state.category_tags_slug or []),
            error = N_(u'Invalid category')),
        function(lambda category: category.slug),
        )(value, state = state)


input_to_coordinates = pipe(
    cleanup_line,
    function(lambda x: x if latitude_longitude_regex.match(x) else None),
    function(lambda x: dict(zip(['longitude', 'latitude'], [float(v) for v in x.split(',')]))),
    )


def input_to_tag_slug(value, state = None):
    from . import ramdb
    if state is None:
        state = default_state
    return pipe(
        input_to_slug,
        test(lambda slug: slug in ramdb.category_by_slug, error = N_(u'Invalid category')),
        )(value, state = state)


def inputs_to_atom_feed_data(inputs, state = None):
    from . import model
    if state is None:
        state = default_state
    return merge(
        model.Poi.make_inputs_to_search_data(),
        struct(
            dict(
                sort_key = pipe(
                    cleanup_line,
                    test_in(['last_update_datetime']),
                    ),
                ),
            default = 'drop',
            keep_none_values = True,
            ),
        )(inputs, state = state)


inputs_to_mail_data = pipe(
    struct({
        'email': pipe(input_to_email, not_none),
        'subject': pipe(cleanup_line, not_none),
        'body': pipe(cleanup_line, not_none),
        }),
    rename_item('email', 'from'),
    )


def inputs_to_pois_csv_infos(inputs, state = None):
    from . import model
    if state is None:
        state = default_state
    # Export only POIs present on given territory.
    data, errors = model.Poi.make_inputs_to_search_data()(inputs, state = state)
    if errors is not None:
        return data, errors

    territory = data['geolocation'] or (data['term'] if not isinstance(data['term'], basestring) else None)
    pois_id = set(model.Poi.iter_ids(
        state,
        territory = territory,
        **model.Poi.extract_non_territorial_search_data(state, data)
        ))

    if len(pois_id) > 65535:
        # Excel doesn't support sheets with more than 65535 rows.
        return None, state._(u'Export is too big. Restrict some search criteria and try again.')

    # Add sub-...-children of found POIs.
    def add_children_id(poi_id, pois_id):
        for child_id in (model.Poi.ids_by_parent_id.get(poi_id) or set()):
            if child_id not in pois_id:
                pois_id.add(child_id)
                add_children_id(child_id, pois_id)
    for poi_id in pois_id.copy():
        add_children_id(poi_id, pois_id)
        if len(pois_id) > 65535:
            # Excel doesn't support sheets with more than 65535 rows.
            return None, state._(u'Export is too big. Restrict some search criteria and try again.')

    return pois_id_to_csv_infos(pois_id, state = state)


def inputs_to_pois_directory_data(inputs, state = None):
    from . import model
    if state is None:
        state = default_state
    return pipe(
        model.Poi.make_inputs_to_search_data(),
        struct(
            dict(
                territory = pipe(
#                    test(lambda territory: territory.__class__.__name__ in model.communes_kinds,
#                        error = N_(u'In "directory" mode, territory must be a commune')),
                    test_not_none(error = N_(u'In "directory" mode, a commune is required')),
                    ),
                ),
            default = noop,
            keep_none_values = True,
            ),
        )(inputs, state = state)


def inputs_to_pois_layer_data(inputs, state = None):
    from . import model
    if state is None:
        state = default_state
    return merge(
        model.Poi.make_inputs_to_search_data(),
        struct(
            dict(
                bbox = pipe(
                    function(lambda bbox: bbox.split(u',')),
                    struct(
                        [
                            # West longitude
                            pipe(
                                input_to_float,
                                test_between(-180, 180),
                                not_none,
                                ),
                            # South latitude
                            pipe(
                                input_to_float,
                                test_between(-90, 90),
                                not_none,
                                ),
                            # East longitude
                            pipe(
                                input_to_float,
                                test_between(-180, 180),
                                not_none,
                                ),
                            # North latitude
                            pipe(
                                input_to_float,
                                test_between(-90, 90),
                                not_none,
                                ),
                            ],
                        ),
                    ),
                current = pipe(
                    input_to_object_id,
                    id_to_poi,
                    test(lambda poi: poi.geo is not None, error = N_('POI has no geographical coordinates')),
                    ),
                enable_cluster = pipe(
                    guess_bool,
                    default(True),
                    ),
                ),
            default = 'drop',
            keep_none_values = True,
            ),
        )(inputs, state = state)


def inputs_to_pois_list_data(inputs, state = None):
    from . import model
    if state is None:
        state = default_state
    return pipe(
        merge(
            model.Poi.make_inputs_to_search_data(),
            struct(
                dict(
                    coverage = pipe(
                        cleanup_line,
                        test_in([u'Départemental', u'Local', u'National', u'Régional']),
                        ),
                    page = pipe(
                        input_to_int,
                        test_greater_or_equal(1),
                        default(1),
                        ),
                    poi_index = pipe(
                        input_to_int,
                        test_greater_or_equal(1),
                        ),
                    sort_key = pipe(
                        cleanup_line,
                        test_in(['name', 'organism-type', 'postal_distribution_str', 'schema_name', 'street_address']),
                        ),
                    ),
                default = 'drop',
                keep_none_values = True,
                ),
            ),
        rename_item('page', 'page_number'),
        )(inputs, state = state)


def pois_id_by_commune_id_to_csv_infos(pois_id_by_commune_id, state = None):
    from . import model, ramdb
    if pois_id_by_commune_id is None:
        return None, None
    if state is None:
        state = default_state
    csv_infos_by_schema_name = {}
    for commune_id, commune_pois_id in pois_id_by_commune_id.iteritems():
        commune = ramdb.territory_by_id.get(commune_id)
        if commune is None:
            continue
        for poi_id in commune_pois_id:
            poi = model.Poi.instance_by_id.get(poi_id)
            if poi is None:
                continue
            csv_infos = csv_infos_by_schema_name.get(poi.schema_name)
            if csv_infos is None:
                csv_infos_by_schema_name[poi.schema_name] = csv_infos = dict(
                    columns_label = [u'Code commune', u'Nom commune'],
                    columns_ref = [None, None],
                    rows = [],
                    )
            columns_label = csv_infos['columns_label']
            columns_index = {}
            columns_ref = csv_infos['columns_ref']
            row = [commune.code, commune.name] + [None] * len(columns_ref)
            for field_ref, field in poi.iter_csv_fields(state):
                # Detect column number to use for field. Create a new column if needed.
                column_ref = tuple(field_ref[:-1])
                same_ref_columns_count = field_ref[-1]
                if columns_ref.count(column_ref) == same_ref_columns_count:
                    column_index = len(columns_ref)
                    columns_label.append(field.label)  # or u' - '.join(label for label in field_ref[::2])
                    columns_ref.append(column_ref)
                    row.append(None)
                else:
                    column_index = columns_ref.index(column_ref, columns_index.get(column_ref, -1) + 1)
                columns_index[column_ref] = column_index
                row[column_index] = field.value
            csv_infos['rows'].append(row)

    # Sort rows by commune code and POI ID.
    for csv_infos in csv_infos_by_schema_name.itervalues():
        csv_infos['rows'].sort(key = lambda row: (row[0], row[2]))

    return csv_infos_by_schema_name or None, None


def pois_id_to_csv_infos(pois_id, state = None):
    from . import model
    if pois_id is None:
        return None, None
    if state is None:
        state = default_state
    csv_infos_by_schema_name = {}
    visited_pois_id = set(pois_id)
    while pois_id:
        remaining_pois_id = []
        for poi_id in pois_id:
            poi = model.Poi.instance_by_id.get(poi_id)
            if poi is None:
                continue
            csv_infos = csv_infos_by_schema_name.get(poi.schema_name)
            if csv_infos is None:
                csv_infos_by_schema_name[poi.schema_name] = csv_infos = dict(
                    columns_label = [],
                    columns_ref = [],
                    rows = [],
                    )
            columns_label = csv_infos['columns_label']
            columns_index = {}
            columns_ref = csv_infos['columns_ref']
            row = [None] * len(columns_ref)
            for field_ref, field in poi.iter_csv_fields(state):
                # Detect column number to use for field. Create a new column if needed.
                column_ref = tuple(field_ref[:-1])
                same_ref_columns_count = field_ref[-1]
                if columns_ref.count(column_ref) == same_ref_columns_count:
                    column_index = len(columns_ref)
                    columns_label.append(field.label)  # or u' - '.join(label for label in field_ref[::2])
                    columns_ref.append(column_ref)
                    row.append(None)
                else:
                    column_index = columns_ref.index(column_ref, columns_index.get(column_ref, -1) + 1)
                columns_index[column_ref] = column_index
                row[column_index] = field.value
                for linked_poi_id in (field.linked_pois_id or []):
                    if linked_poi_id not in visited_pois_id:
                        visited_pois_id.add(linked_poi_id)
                        remaining_pois_id.append(linked_poi_id)
            csv_infos['rows'].append(row)
        pois_id = remaining_pois_id
    return csv_infos_by_schema_name or None, None


def postal_distribution_to_territory(postal_distribution, state = None):
    from . import ramdb
    if postal_distribution is None:
        return postal_distribution, None
    if state is None:
        state = default_state
    territory_id = ramdb.territories_id_by_postal_distribution.get(postal_distribution)
    if territory_id is None:
        return postal_distribution, state._(u'Unknown territory')
    territory = ramdb.territory_by_id.get(territory_id)
    if territory is None:
        return postal_distribution, state._(u'Unknown territory')
    return territory, None


def site_to_bson(subscriber, state = None):
    if state is None:
        state = default_state
    return pipe(
        object_to_clean_dict,
        struct(
            dict(
                subscriptions = uniform_sequence(function(lambda subscription: subscription.to_bson())),
                ),
            default = noop,
            ),
        )(session, state = state)


def subscriber_to_bson(subscriber, state = None):
    if state is None:
        state = default_state
    return pipe(
        object_to_clean_dict,
        struct(
            dict(
                sites = uniform_sequence(function(lambda site: site.to_bson())),
                users = uniform_sequence(function(lambda user: user.to_bson())),
                ),
            default = noop,
            ),
        )(session, state = state)


subscription_to_bson = object_to_clean_dict


user_to_bson = object_to_clean_dict


# Level-2 Converters


def coordinates_to_territory(value, state = None):
    from . import ramdb
    if not value:
        return None, None
    if state is None:
        state = default_state

    latitude_cos = math.cos(math.radians(value['latitude']))
    latitude_sin = math.sin(math.radians(value['latitude']))
    distance_and_territory_couples = sorted(
        (
            (
                6372.8 * math.acos(
                    round(
                        math.sin(math.radians(territory.geo[1])) * latitude_sin
                        + math.cos(math.radians(territory.geo[1])) * latitude_cos
                        * math.cos(math.radians(territory.geo[0] - value['longitude'])),
                        13,
                    )),
                territory,
                )
            for territory in ramdb.territory_by_id.itervalues()
            if territory.geo is not None and territory.__class__.__name__ in (
                u'ArrondissementOfCommuneOfFrance',
                u'AssociatedCommuneOfFrance',
                u'CommuneOfFrance'
                )
            ),
        key = lambda distance_and_territory: distance_and_territory[0],
        )
    return distance_and_territory_couples[0][1] if distance_and_territory_couples else None, None


input_to_postal_distribution_to_geolocated_territory = pipe(
    input_to_postal_distribution,
    postal_distribution_to_territory,
    test(lambda territory: territory.geo is not None, error = N_(u'Territory has no geographical coordinates')),
    )
