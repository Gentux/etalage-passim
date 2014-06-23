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

OBSOLETE_SCHEME_NAMES = [
    u'ApplicationMobile',
    u'CalculDItineraires',
    u'CentreAppel',
    u'Comarquage',
    u'Gadget',
    u'GuichetInformation',
    u'InformationTechnique',
    u'OpenData',
    u'OperateurServiceInformation',
    u'PageWeb',
    u'ServiceWeb',
    u'SiteWeb',
]


INFORMATION_SERVICES_FIELDS = [
    u"Nom du service",
    u"Alias",
    u"Opérateur",
    u"Offres de transport",
    u"Service d'information multimodale",
    u"Niveau",
    u"Territoire couvert",
    u"Logo",
    u"Notes",
    u"Site web - URL",
    u"Site web - Types d'informations",
    u"Site web - Notes",
    u"Site web - Langues",
    u"Application mobile - Intitulé",
    u"Application mobile - iPhone",
    u"Application mobile - Android",
    u"Application mobile - Types d'informations",
    u"Application mobile - Web mobile",
    u"Application mobile - Notes",
    u"Application mobile - Blackberry",
    u"Application mobile - Windows mobile",
    u"Application mobile - Langues",
    u"Centre d'appel - Intitulé",
    u"Centre d'appel - Téléphone",
    u"Centre d'appel - Notes",
    u"Centre d'appel - Horaires d'ouverture",
    u"Guichet d'information - Intitulé",
    u"Guichet d'information - Adresse",
    u"Guichet d'information - Téléphone",
    u"Guichet d'information - Géolocalisation",
    u"Guichet d'information - Fax",
    u"Guichet d'information - Courriel",
    u"Guichet d'information - Horaires d'ouverture",
    u"Guichet d'information - Notes",
    u"Open data - Intitulé",
    u"Open data - URL de la page d'accueil du portail Open Data",
    u"Open data - URL de la page TC",
    u"Open data - Types d'informations",
    u"Open data - Licence",
    u"Open data - URL de la licence",
    u"Open data - Notes",
    u"Service web - Intitulé",
    u"Service web - URL",
    u"Service web - Types d'informations",
    u"Service web - Licence",
    u"Service web - Notes",
    u"Comarquage - Type de marque",
    u"Comarquage - URL",
    u"Comarquage - Note",
    ]


def delete_scheme(schema, db):
    db.schemas.remove({'_id': schema['_id']})
    for poi in db.pois.find({'metadata.schema-name': schema['name']}):
        db.pois.remove({'_id': poi['_id']})


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


def reorder_poi_fields(poi, schema):
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
    return new_positions


def sort_schema_field(schema):
    return sorted(
        schema['fields'],
        key = lambda field: INFORMATION_SERVICES_FIELDS.index(field.get('label')),
        )


def main():
    parser = argparse.ArgumentParser(description = __doc__)
    parser.add_argument('csv_filename', nargs = '?', help = 'CSV File name.')
    parser.add_argument('-d', '--database_name', default = 'souk_passim', help = 'Name of database used')
    parser.add_argument('-v', '--verbose', action = 'store_true', help = 'Increase output verbosity')

    args = parser.parse_args()
    logging.basicConfig(level = logging.DEBUG if args.verbose else logging.WARNING, stream = sys.stdout)
    db = pymongo.Connection()[args.database_name]

    schema_by_name = {}
    for schema in db.schemas.find():
        if schema['name'] == 'ServiceInfo':
            schema['fields'] = sort_schema_field(schema)
            db.schemas.save(schema)
        elif schema['name'] in OBSOLETE_SCHEME_NAMES:
            delete_scheme(schema, db)
            continue
        schema_by_name[schema['name']] = schema

        for poi in db.pois.find({'metadata.schema-name': schema['name']}):
            new_positions = reorder_poi_fields(poi, schema)

            if poi['metadata']['positions'] != new_positions:
                poi['metadata']['positions'] = new_positions
                db.pois.save(poi)

#QUESTION : est-il encore possible de prendre en compte des modifs ? Notamment l'idée serait de figer des listes
#   actuellement dans des Autocompléteurs en les mettant dans des Menus ou Cases à cocher. Cela implique de prendre les
#   valeurs actuelles pour ces champs qui ne sont pas dans la liste, et d'ajouter dans le script de vérif peut être le
#   test que la valeur du champ correspond bien au type (valeurs dans la liste)

#    - une fois que c'est Ok en pre-prod (validation Cerema)-> (1) archivage de la BD (dump mongodb) (2) archivage du
#       contenu aussi sous forme de tableau CSV (3) Romain execute les scripts en production
#    - à partir de là, les collègues du Cerema notamment pourront reprendre la mise à jour dans ce nouveau modèle
#    - à chaque mise à jour du modèle Offre ou du modèle Service d'info, on fera de même un archivage des données et
#       des scripts, et une mise à jour des scripts permettant de passer à la nouvelle version des modèles

#-2- Romain importe les communes du Piémont dans la copie de Territoria de passim, en préproduction ; on valide le
#   comportement du front et du back (notamment par rapport à l'autocompléteur des noms de territoires), puis on passe
#   en production, et on peut prévenir les partenaires alpinfonet qu'ils peuvent essayer de saisir

#-3- Laurent Chevereau a désormais obtenu des collègues la mise à jour officielle des PTU :
#   http://www.certu.fr/liste-des-reseaux-de-transport-a1267.html .
#   Je vais repartir de ce tableau pour mettre à jour les scripts générant fichiers SHP utilisés par les scripts
#   d'export KML et SHP chaque nuit. Dès que c'est Ok, Romain pourra (1) mettre à jour Territoria avec les PTU 2014
#   (je suppose que les communes sont déjà mises à jour avec les données Insee les + récentes?) (2) mettre à jour le
#   serveur

#-4- points restant à traiter :
#   scripts logos,
#   captcha,
#   Google CSE,
#   petitpois en multilingue,
#   accès aux logs du serveur web pour regarder les stats de temps en temps,
#   doc d'install et tests unitaires
#   serveur de tuiles OSM des cartes passim à remplacer,
#   vérifier que etalage affiche bien tous les services sur des noms de communes du genre PUY EN VELAY (LE)...

#-5- je n'ai toujours pas accès au SSH .
#   Ci-joint ma clé publique, Romain peux-tu vérifier que c'est la bonne pour ton serveur, merci?

#Laurent a envoyé ses propositions de mise à jour du modèle service d'info (en bleu):

#- il s'agit surtout de remplacer des champs autocompléteur en cases à cocher :
#   site web - langues, appli mobile - langues, appli mobile - types d'info, comarquage - type de marque (valeurs dans
#   la bulle d'aide du champ)
#- bien qu'en bleu dans le tableau .ODS joint, open data - types d'info et licence (sur la base de la fiche open data)
#   sont déjà des cases à cocher dans le modèle SI
#Le seul autocompléteur multiple qui reste serait Type d'info de service web.
#Est-ce que c'est encore faisable ? Sinon on peut faire en deux temps.
    return 0


if __name__ == "__main__":
    sys.exit(main())
