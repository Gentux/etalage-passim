#! /usr/bin/env python
# -*- coding: utf-8 -*-


"""
Check POIs structures.

For each POIs, verify if :
    * Vérify that links are correct
    * Vérify that all field are specified by scheme
    * Vérify that no field is the double of another
    * Vérify field and values match
    * Vérify field order
"""


import argparse
import copy
import logging
import os
import requests
import sys

import pymongo


APP_NAME = os.path.splitext(os.path.basename(__file__))[0]
log = logging.getLogger(APP_NAME)


def add_field_to_poi(poi, field_id, value, metadata):
    poi_copy = copy.deepcopy(poi)
    if field_id not in poi_copy:
        poi_copy[field_id] = [value]
        poi_copy['metadata'][field_id] = [metadata]
    else:
        poi_copy[field_id].append(value)
        poi_copy['metadata'][field_id].append(metadata)
    poi_copy['metadata']['positions'].append(field_id)
    return poi_copy


def are_links_correct(poi):
    """Vérify that links are correct."""
    for url in poi.get('url', []):
        log.debug(u'Testing URL : {}'.format(url))
        try:
            response = requests.get(url)
        except requests.ConnectionError:
            yield u'URL {} for poi {} is invalid, Connection Error'.format(url, poi['_id'])
            continue
        except requests.exceptions.TooManyRedirects:
            yield u'URL {} for poi {} is invalid, Connection Error'.format(url, poi['_id'])
            continue
        except requests.exceptions.ContentDecodingError:
            yield u'URL {} for poi {} is invalid, Connection Error'.format(url, poi['_id'])
            continue
        except requests.exceptions.InvalidURL:
            yield u'URL {} for poi {} is invalid, Connection Error'.format(url, poi['_id'])
            continue

        if not response.ok:
            yield u'URL {} for poi {} is invalid, status code = {}'.format(url, poi['_id'], response.status_code)


def field_orders_match(poi, schema):
    """Vérify that all field are specified by scheme."""
    poi_metadata_copy = copy.deepcopy(poi['metadata'])
    poi_fields_tuples = [
        (field_id, poi_metadata_copy[field_id].pop(0).get('label'))
        for field_id in poi['metadata']['positions']
        ]
    schema_fields_tuples = [
        (field['id'], field['label'])
        for field in schema.get('fields', [])
        ]
    if len(poi['metadata']['positions']) >= len(schema['fields']):
        yield u'POI {} has too much fields'.format(poi['_id'])
        return

    last_field_index = 0
    for field_tuple in poi_fields_tuples:
        if field_tuple not in schema_fields_tuples:
            yield u'Field {} in POI {} is not in schema'.format(field_tuple, poi['_id'])
            continue
        if schema_fields_tuples.index(field_tuple) < last_field_index:
            yield u'Field {} in POI {} is in right order'.format(field_tuple, poi['_id'])
            continue
        last_field_index = schema_fields_tuples.index(field_tuple)


def are_field_unique(poi):
    """Vérify that no field is the double of another."""
    for field_id in poi['metadata']['positions']:
        if len(poi['metadata'][field_id]) == 1:
            continue

        field_labels = set()
        for field_metadata in poi['metadata'][field_id]:
            if field_metadata['label'] in field_labels:
                yield u'Duplicate field {} in poi {}.'.format(field_id, poi['_id'])
                continue
            field_labels.add(field_metadata['label'])


def are_field_and_value_matches(poi, scheme):
    """Vérify field and values match."""
    # TODO implement this
    pass


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
        for error in are_links_correct(poi) or []:
            log.error(error)
        for error in field_orders_match(poi, schema) or []:
            log.error(error)
        for error in are_field_unique(poi) or []:
            log.error(error)
        for error in are_field_and_value_matches(poi, schema) or []:
            log.error(error)

    return 0


if __name__ == "__main__":
    sys.exit(main())
