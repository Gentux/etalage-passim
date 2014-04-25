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


def field_metadata(poi, field_id, label_dict_pairs, default = None):
    poi_label_index = label_index(poi, field_id, label_dict_pairs)
    return default if poi_label_index is None else poi['metadata'][field_id][poi_label_index]


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

    information_services_by_id = dict([
        (item['_id'], item)
        for item in db.pois.find({'metadata.deleted': {'$exists': False}, 'metadata.schema-name': 'ServiceInfo'})
        ])
    schema_title_by_schema_name = dict([(schema['name'], schema['title']) for schema in db.schemas.find()])
    selected_pois_id = set()  # ID of POIs which will be removed after processed
    merging_fields_by_schema_name = {
        'ApplicationMobile': [
            ('name', [(u'label', u'Intitulé')]),
            ('url', [(u'label', u'Web mobile')]),
            ('url', [(u'label', u'iPhone')]),
            ('url', [(u'label', u'Android')]),
            ('url', [(u'label', u'Blackberry')]),
            ('url', [(u'label', u'Windows mobile')]),
            ('url', [(u'label', u'Symbian')]),
            ('autocompleters', [(u'label', u'Types d\'informations')]),
            ('autocompleters', [(u'label', u'Langues')]),
            ('text-block', [(u'label', u'Notes')]),
            ],
        'CalculDItineraires': [
            ('url', [('label', u'URL')]),
            ('boolean', [('label', u'Calcul CO2')]),
            ('checkboxes', [('label', u'Comparaison de modes')]),
            ('checkboxes', [('label', u'Rabattement vers TC')]),
            ('boolean', [('label', u'Prise en compte des perturbations')]),
            ('boolean', [('label', u'Prise en compte du temps réel')]),
            ('text-block', [('label', u'Notes')]),
            ],
        'CentreAppel': [
            ('name', [('label', u'Intitulé')]),
            ('tel', [('label', u'Téléphone')]),
            ('text-block', [('label', u'Horaires d\'ouverture')]),
            ('text-block', [('label', u'Notes')]),
            ],
        'Comarquage': [
            ('autocompleters', [('label', u'Type de marque')]),
            ('url', [('label', u'URL')]),
            ('text-block', [('label', u'Note')]),
            ],
        'Gadget': [
            ('name', [('label', u'Intitulé')]),
            ('url', [('label', u'URL')]),
            ('autocompleters', [('label', u'Types d\'informations')]),
            ('text-block', [('label', u'Notes')]),
            ],
        'GuichetInformation': [
            ('name', [('label', u'Intitulé')]),
            ('adr', [('label', u'Adresse')]),
            ('tel', [('label', u'Téléphone')]),
            ('fax', [('label', u'Fax')]),
            ('email', [('label', u'Courriel')]),
            ('text-block', [('label', u'Horaires d\'ouverture')]),
            ('geo', [('label', u'Géolocalisation')]),
            ('text-block', [('label', u'Notes')]),
            ],
        'InformationTechnique': [
            ('name', [('label', u'Intitulé')]),
            ('text-block', [('label', u'Notes')]),
            ('url', [('label', u'Site Web du système')]),
            ('url', [('label', u'Accès au serveur de documentation')]),
            ],
        'OffreTransport': [
            ('name', [('label', u'Nom commercial')]),
            ('select', [('label', u'Niveau')]),
            ('territories', [('label', u'Territoire couvert')]),
            ('select', [('label', u'Type de transport')]),
            ('checkboxes', [('label', u'Mode de transport')]),
            ('link', [('label', u'Service d\'info officiel')]),
            ('text-block', [('label', u'Accessibilité')]),
            ('text-block', [('label', u'Temps réel')]),
            ('text-block', [('label', u'Notes')]),
            ],
        'OpenData': [
            ('name', [('label', u'Intitulé')]),
            ('url', [('label', u'URL de la page d\'accueil du portail Open Data')]),
            ('url', [('label', u'URL de la page TC')]),
            ('checkboxes', [('label', u'Types d\'informations')]),
            ('checkboxes', [('label', u'Licence')]),
            ('url', [('label', u'URL de la licence')]),
            ('text-block', [('label', u'Notes')]),
            ],
        'OperateurServiceInformation': [
            ('name', [('label', u'Intitulé')]),
            ('select', [('label', u'Type d\'opérateur')]),
            ('text-block', [('label', u'Notes')]),
            ],
        'PageWeb': [
            ('name', [('label', u'Intitulé')]),
            ('url', [('label', u'URL')]),
            ('select', [('label', u'Type d\'information')]),
            ('text-block', [('label', u'Notes')]),
            ],
        'ServiceInfo': [
            ('name', [('label', u'Nom du service')]),
            ('text-inline', [('label', u'Alias')]),
            ('link', [('label', u'Opérateur')]),
            ('links', [('label', u'Offres de transport')]),
            ('boolean', [('label', u'Service d\'information multimodale')]),
            ('select', [('label', u'Niveau')]),
            ('territories', [('label', u'Territoire couvert')]),
            ('image', [('label', u'Logo')]),
            ('text-block', [('label', u'Notes')]),
            ],
        'ServiceWeb': [
            ('name', [('label', u'Intitulé')]),
            ('url', [('label', u'URL')]),
            ('autocompleters', [('label', u'Types d\'informations')]),
            ('text-inline', [('label', u'Licence')]),
            ('text-block', [('label', u'Notes')]),
            ],
        'SiteWeb': [
            ('url', [('label', u'URL')]),
            ('checkboxes', [('label', u'Types d\'informations')]),
            ('autocompleters', [('label', u'Langues')]),
            ('text-block', [('label', u'Notes')]),
            ],
        }

    for index, poi in enumerate(db.pois.find({
            'metadata.deleted': {'$exists': False},
            'metadata.schema-name': {'$ne': 'ServiceInfo'},
            })):
        information_service_id = field_value(poi, 'link', [('label', u'Service d\'information')])
        if information_service_id is None:
            continue

        for field_id, metadata in merging_fields_by_schema_name[poi['metadata']['schema-name']]:
            field_metadata_dict = field_metadata(poi, field_id, metadata)
            value = field_value(poi, field_id, metadata)
            if field_metadata_dict is None or value is None:
                continue
            if 'label' in field_metadata_dict:
                field_metadata_dict['label'] = u'{} - {}'.format(
                    schema_title_by_schema_name[poi['metadata']['schema-name']],
                    field_metadata_dict['label'],
                    )
            information_services_by_id[information_service_id] = add_field_to_poi(
                information_services_by_id[information_service_id],
                field_id,
                value,
                field_metadata_dict,
                )
            selected_pois_id.add(poi['_id'])

    for poi in information_services_by_id.itervalues():
        db.pois.save(poi)
    for poi_id in selected_pois_id:
        db.pois.remove({'_id': poi_id})

    return 0


if __name__ == "__main__":
    sys.exit(main())
