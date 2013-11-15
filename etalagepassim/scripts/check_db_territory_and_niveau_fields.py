#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""Check fields "territory" and "niveau"

Ce script change remplit les champs "territoire" et "niveau" pour les Services d'information qui ne les posséderaientt
pas.
"""


import argparse
from itertools import chain, imap
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


def set_field_value(value, poi, field_id, label_dict_pairs):
    if value is None:
        return poi
    poi_label_index = label_index(poi, field_id, label_dict_pairs)
    field_value = value
    if field_id == 'territories':
        field_value = [
            {'kind': territory_kind, 'code': territory_code}
            for territory_kind, territory_code in value
            ]
    if poi_label_index is None:
        if poi['metadata'].get(field_id):
            poi['metadata'][field_id].append(dict(label_dict_pairs))
        else:
            poi['metadata'][field_id] = [dict(label_dict_pairs)]
        poi['metadata']['positions'].append(field_id)
        poi[field_id] = [field_value]
    else:
        poi[field_id][poi_label_index] = field_value
    return poi


def merge_territories(poi_list):
    return set(
        chain.from_iterable(
            filter(
                None,
                imap(lambda item: field_value(item, 'territories', [('label', 'Territoire couvert')]), poi_list),
                )
            ),
        )


def main():
    parser = argparse.ArgumentParser(description = __doc__)
    parser.add_argument('config_file', help = 'Configuratioin file of Petitpois')
    parser.add_argument('-v', '--verbose', action = 'store_true', help = 'increase output verbosity')

    args = parser.parse_args()

    site_conf = appconfig('config:%s' % os.path.abspath(args.config_file))
    pylons.config = load_environment(site_conf.global_conf, site_conf.local_conf)
    db = model.db

    logging.basicConfig(
        level = logging.DEBUG if args.verbose else logging.WARNING,
        format = u'%(message)s',
        #format = u'%(levelname)-5.5s [line %(lineno)d] %(message)s',
        #format = u'%(asctime)s %(levelname)-5.5s [%(name)s:%(funcName)s line %(lineno)d] %(message)s',
        stream = sys.stdout,
        )

    log.info(u'Check if "niveau" and "territory" fields exist in "Services d\'information" schema')
    schema_name = u'Service d\'information'
    schema = db.schemas.find_one({'title': schema_name})
    found_fields = []
    for field_index, field in enumerate(schema['fields']):
        if field['id'] == 'territories' and field['label'] == 'Territoires':
            log.info(u'Found "Territoires" field')
            found_fields.append('Territoires')
        if field['id'] == 'select' and field['label'] == 'Niveau':
            log.info(u'Found "Niveau" field')
            found_fields.append('Niveau')

    for field_name in found_fields:
        if field == 'Niveau':
            schema['fields'].append({
                u'id': u'select',
                u'label': u'Niveau',
                u'options': [
                    u'Locale',
                    u'Départementale',
                    u'Régionale',
                    u'Nationale',
                    ],
                u'protected': u'0',
                u'required': u'0',
                u'tooltip': u'',
                u'value': u'',
                })
            log.info('Add "Niveau" field to schema')
        if field == 'Territoires':
            schema['fields'].append({
                u'id': u'territories',
                u'initial': u'',
                u'label': u'Territoires',
                u'protected': u'0',
                u'required': u'0',
                u'tooltip': u'',
                u'value': u'',
                })
            log.info('Add "Territoires" field to schema')
    db.schemas.save(schema, safe = True)
    log.info('Schema saved')

    errors_by_id = {}
    log.info('Check all POIs for these two fields')
    for poi in db.pois.find({'metadata.schema-name': u'ServiceInfo'}):
        is_multimodal_info_service = field_value(
            poi,
            'boolean',
            [('label', u'Service d\'information multimodale')],
            default = '0',
            )
        niveau = field_value(poi, 'select', [('label', 'Niveau')])
        territoires = field_value(poi, 'territories', [('label', 'Territoires')])
        transport_offer_ids = field_value(
            poi,
            'links',
            [('kind', u'OffreTransport'), ('label', u'Offres de transport')],
            default = [],
            )
        transport_offers = list(db.pois.find({'_id': {'$in': transport_offer_ids}}))
        official_transport_offers = filter(
            lambda item: poi['_id'] == field_value(item, 'link', [('label', u'Service d\'info officiel')]),
            transport_offers,
            )

        if not is_multimodal_info_service and len(transport_offers) == 0:
            errors_by_id.setdefault(poi['_id'], {})['name'] = field_value(poi, 'name', [('label', u'Nom du service')])
            errors_by_id[poi['_id']].setdefault('messages', []).append(u'Poi hasn\'t got any transport offers')
            errors_by_id[poi['_id']]['type'] = '2missing'
            continue

        if is_multimodal_info_service == '1' or is_multimodal_info_service is True:
            poi = set_field_value('1', poi, 'boolean', [('label', u'Service d\'information multimodale')])
            # "Territoires" already set for all multimodal info service
            if territoires is None:
                errors_by_id.setdefault(poi['_id'], {})['name'] = field_value(
                    poi,
                    'name',
                    [('label', u'Nom du service')],
                    )
                errors_by_id[poi['_id']].setdefault('messages', []).append(
                    'Multimodal info service has no territories',
                    )
                errors_by_id[poi['_id']]['type'] = '1sim'
                continue
            for territoroire in territoires:
                territoires_tuple = territoires
                territoire_niveau = {
                    u'ArrondissementOfFrance': 'local',
                    u'CommuneOfFrance': 'local',
                    u'Country': 'national',
                    u'DepartmentOfFrance': 'departmental',
                    u'RegionOfFrance': 'regional',
                    u'UrbanTransportsPerimeterOfFrance': 'local',
                    }.get(territoires_tuple[0])
                if niveau is not None and niveau != territoire_niveau:
                    errors_by_id.setdefault(poi['_id'], {})['name'] = field_value(
                        poi,
                        'name',
                        [('label', u'Nom du Service')],
                        )
                    errors_by_id[poi['_id']].setdefault('messages', []).append(
                        'SIM Niveau can\'t be determined through territories',
                        )
                    errors_by_id[poi['_id']]['territoires'] = territoires
                    break
                niveau = territoire_niveau
            continue

        official_transports_offers_niveau = set(
            map(lambda item: field_value(item, 'select', [('label', 'Niveau')]), official_transport_offers),
            )
        transports_offers_niveau = None
        if len(official_transports_offers_niveau) == 1:
            niveau = official_transports_offers_niveau.pop()
        else:
            transports_offers_niveau = set(
                map(lambda item: field_value(item, 'select', [('label', 'Niveau')]), transport_offers),
                )
            if len(transports_offers_niveau) == 1:
                niveau = transports_offers_niveau.pop()
        if niveau is None:
            errors_by_id.setdefault(poi['_id'], {})['name'] = field_value(poi, 'name', [('label', u'Nom du service')])
            errors_by_id[poi['_id']].setdefault('messages', []).append(
                'Niveau can\'t be determined through transport_offers',
                )
            errors_by_id[poi['_id']]['niveaux'] = transports_offers_niveau or official_transports_offers_niveau
            errors_by_id[poi['_id']]['type'] = '3niveau'

        official_transports_offers_territoires = merge_territories(official_transport_offers)
        if len(official_transports_offers_territoires) >= 1:
            territoires = list(official_transports_offers_territoires)
        else:
            transports_offers_territoires = merge_territories(transport_offers)
            if len(transports_offers_territoires) >= 1:
                territoires = list(transports_offers_territoires)
        if territoires is None:
            errors_by_id.setdefault(poi['_id'], {})['name'] = field_value(poi, 'name', [('label', u'Nom du service')])
            errors_by_id[poi['_id']].setdefault('messages', []).append(
                'Territory can\'t be determined through transport_offers',
                )
            errors_by_id[poi['_id']]['territoires'] = transports_offers_territoires
            errors_by_id[poi['_id']]['type'] = '4territoires'
        else:
            # Remove territories if one of their ancestor territories is is in the list
            territories = [
                db.territories.find_one({'kind': territory_kind, 'code': territory_code})
                for territory_kind, territory_code in territoires
                ]
            remove_indexes = set()
            for index, territory in enumerate(territories):
                for index2, territory2 in enumerate(territories):
                    if index != index2 and territory['_id'] in territory2['ancestors_id']:
                        remove_indexes.add(index2)
            if remove_indexes:
                for index in sorted(remove_indexes, reverse = True):
                    territoires.pop(index)

        poi = set_field_value(niveau, poi, 'select', [('label', 'Niveau')])
        poi = set_field_value(territoires, poi, 'territories', [('label', 'Territoires')])
        try:
            poi_tools.poi_add_metadata_indexes_things(poi)
        except Exception as exc:
            log.error('An exception occurred while indexing POI: {}'.format(exc))
            continue

        db.pois.save(poi)
        poi_tools.poi_changed(poi)
    log.info('POIs field renamed')

    for index, (_id, error) in enumerate(sorted(errors_by_id.iteritems(), key = lambda t: t[1].get('type'))):
        log.error('-' * 85)
        log.error(index + 1)
        log.error('http://petitpois.passim-dev.mat.cst.easter-eggs.com/poi/view/{}'.format(_id))
        log.error(error['name'])
        for message in error['messages']:
            log.error(message)
        if error.get('niveaux'):
            log.error(u'{}* Niveaux :'.format(' ' * 4))
            for niveau in error['niveaux']:
                log.error(u'{}- {}'.format(' ' * 8, niveau))
        if error.get('territoires'):
            log.error(u'{}* Territoires :'.format(' ' * 4))
            for territoire in error['territoires']:
                log.error(u'{}- {}'.format(' ' * 8, territoire))


if __name__ == "__main__":
    sys.exit(main())
