#! /usr/bin/env python
# -*- coding: utf-8 -*-

"""
Use POIs from different schemes and unify them in only one information services scheme.
"""


import argparse
import copy
import logging
import os
import sys

import pymongo


app_name = os.path.splitext(os.path.basename(__file__))[0]
log = logging.getLogger(app_name)


def field_value(poi, field_id, label_dict_pairs, default = None):
    if field_id == 'territories':
        poi_label_index = label_index(poi, field_id, label_dict_pairs)
        return default if poi_label_index is None else map(
            lambda item: (item['kind'], item['code']),
            filter(
                None,
                poi[field_id][poi_label_index],
                ),
            )
    poi_label_index = label_index(poi, field_id, label_dict_pairs)
    return default if poi_label_index is None else poi[field_id][poi_label_index]


def label_index(poi, field_id, label_dict_pairs):
    for _label_index, _label_dict in enumerate(poi['metadata'].get(field_id, [])):
        if all(map(lambda item: _label_dict[item[0]] == item[1], label_dict_pairs)):
            return _label_index
    return None


def main():
    parser = argparse.ArgumentParser(description = __doc__)
    parser.add_argument('csv_filename', nargs = '?', help = 'CSV File name.')
    parser.add_argument('-d', '--database_name', default = 'souk_passim', help = 'Name of database used')
    parser.add_argument('-v', '--verbose', action = 'store_true', help = 'Increase output verbosity')

    args = parser.parse_args()
    logging.basicConfig(level = logging.DEBUG if args.verbose else logging.WARNING, stream = sys.stdout)
    db = pymongo.Connection()[args.database_name]

    schema_by_name = dict([(schema['name'], schema) for schema in db.schemas.find()])
    for poi in db.pois.find({'metadata.deleted': {'$exists': False}}):
        schema_name = poi['metadata']['schema-name']
        schema = schema_by_name.get(schema_name)
        if schema is None:
            schema = schema_by_name[schema_name] = db.schemas.find_one({'name': schema_name})
            if schema is None:
                log.error(u'Schema {} doesn\'t exists'.format(schema_name))
                continue

        poi_metadata_copy = copy.deepcopy(poi['metadata'])
        poi_fields_tuples = [
            (field_id, poi_metadata_copy[field_id].pop(0).get('label'))
            for field_id in poi['metadata']['positions']
            ]
        schema_fields_tuples = [
            (field['id'], field['label'])
            for field in schema.get('fields', [])
            ]
        new_positions = []
        for field_tuple in schema_fields_tuples:
            if field_tuple in poi_fields_tuples:
                new_positions.append(field_tuple[0])
                poi_fields_tuples.pop(poi_fields_tuples.index(field_tuple))

        for field_tuple in poi_fields_tuples:
            new_positions.append(field_tuple[0])
        if poi['metadata']['positions'] != new_positions:
            poi['metadata']['positions'] = new_positions
            db.pois.save(poi)
    return 0


if __name__ == "__main__":
    sys.exit(main())
