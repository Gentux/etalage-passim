#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""Rename Schemas and POIs fields.

Ce script change l'intitulé d'un champs dans un schema.
Le script s'occupe de répliquer le changement dans les POIs appartenant à ce schema.
"""


import argparse
import copy
import logging
import os
import sys

from paste.deploy import appconfig
import pylons

from petitpois.config.environment import load_environment
from petitpois.lib import poi_tools
from petitpois import model


app_name = os.path.splitext(os.path.basename(__file__))[0]
log = logging.getLogger(app_name)


def main():
    parser = argparse.ArgumentParser(description = __doc__)
    parser.add_argument('config_file', help = 'Configuratioin file of Petitpois')
    parser.add_argument('-s', '--schema', help = 'Schema\'s name', required = True)
    parser.add_argument('-i', '--id', help = 'ID of the renamed field', required = True)
    parser.add_argument('-l', '--label', help = 'Label of the renamed field', required = True)
    parser.add_argument('-nl', '--new-label', help = 'New name for the field', required = True)
    parser.add_argument('-v', '--verbose', action = 'store_true', help = 'increase output verbosity')

    args = parser.parse_args()

    site_conf = appconfig('config:%s' % os.path.abspath(args.config_file))
    pylons.config = load_environment(site_conf.global_conf, site_conf.local_conf)
    db = model.db

    logging.basicConfig(
        level = logging.DEBUG if args.verbose else logging.WARNING,
        format = '%(asctime)s %(levelname)-5.5s [%(name)s:%(funcName)s line %(lineno)d] %(message)s',
        stream = sys.stdout,
        )

    # Change name in the Schema
    log.info('Renaming field label in schema')
    schema = db.schemas.find_one()
    for field_index, field in enumerate(schema['fields']):
        if field['id'] == args.id and field['label'] == args.label:
            break
    new_field = copy.deepcopy(schema['fields'][field_index])
    new_field['label'] = args.new_label
    del schema['fields'][field_index]
    schema['fields'].insert(field_index, new_field)
    db.schemas.save(schema, safe = True)
    log.info('Schema\'s field renamed')

    # Rename this field in all POIs
    log.info('Renaming POIs field')
    for poi in db.pois.find({'metadata.schema-name': schema['name']}):
        for label_index, label_dict in enumerate(poi['metadata'].get(args.id, [])):
            if label_dict['label'] == args.label:
                break
        else:
            continue
        new_label = copy.deepcopy(label_dict)
        new_label['label'] = args.new_label
        del poi['metadata'][args.id][label_index]
        poi['metadata'][args.id].insert(label_index, new_label)

        try:
            poi_tools.poi_add_metadata_indexes_things(poi)
        except Exception as exc:
            log.error('An exception occurred while indexing POI: {}'.format(exc))
            continue

        db.pois.save(poi)
        poi_tools.poi_changed(poi)
    log.info('POIs field renamed')

    log.info('Renaming field in POIs history')
    for hpoi in db.pois_history.find({'metadata.schema-name': schema['name']}):
        for label_index, label_dict in enumerate(hpoi['metadata'].get(args.id, [])):
            if label_dict['label'] == args.label:
                break
        else:
            continue
        new_label = copy.deepcopy(label_dict)
        new_label['label'] = args.new_label
        del hpoi['metadata'][args.id][label_index]
        hpoi['metadata'][args.id].insert(label_index, new_label)

        db.pois_history.save(hpoi)
    log.info('History POIs field renamed')


if __name__ == "__main__":
    sys.exit(main())
