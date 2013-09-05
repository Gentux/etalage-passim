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


"""Environment configuration"""


from ConfigParser import SafeConfigParser
import logging
import os
import sys
import urlparse

from biryani import strings
import mako.lookup
import pkg_resources
import pymongo
from etalagepassim import ramdb

import etalagepassim
from . import conv, model, templates


app_dir = os.path.dirname(os.path.abspath(__file__))


def load_environment(global_conf, app_conf):
    """Configure the application environment."""
    conf = etalagepassim.conf  # Empty dictionary
    conf.update(strings.deep_decode(global_conf))
    conf.update(strings.deep_decode(app_conf))
    conf.update(conv.check(conv.struct(
        {
            u'app_conf': conv.set_value(app_conf),
            u'app_dir': conv.set_value(app_dir),
            u'autocompleter_territories_kinds': conv.pipe(
                conv.function(lambda kinds: kinds.split()),
                conv.uniform_sequence(
                    conv.test_in(model.Territory.public_kinds),
                    constructor = lambda kinds: sorted(set(kinds)),
                    ),
                conv.default([
                    # u'AbstractCommuneOfFrance',
                    u'ArrondissementOfCommuneOfFrance',
                    u'ArrondissementOfFrance',
                    u'AssociatedCommuneOfFrance',
                    # u'CantonalFractionOfCommuneOfFrance',
                    u'CantonOfFrance',
                    u'CommuneOfFrance',
                    # u'Country',
                    u'DepartmentOfFrance',
                    u'IntercommunalityOfFrance',
                    # u'InternationalOrganization',
                    u'MetropoleOfCountry',
                    u'Mountain',
                    u'OverseasCollectivityOfFrance',
                    u'PaysOfFrance',
                    u'RegionalNatureParkOfFrance',
                    u'RegionOfFrance',
                    # u'Special',
                    u'UrbanAreaOfFrance',
                    u'UrbanTransportsPerimeterOfFrance',
                    ]),
                ),
            u'brand_name': conv.default(u'Comarquage.fr'),
            u'brand_url': conv.default(u'http://www.comarquage.fr/'),
            u'cache_dir': conv.default(os.path.join(os.path.dirname(app_dir), 'cache')),
            u'categories_collection': conv.default('categories'),
            u'cdn_url': conv.default('http://localhost:7000'),
            u'custom_static_files_dir': conv.default(None),
            u'custom_templates_dir': conv.default(None),
            u'data_updates_collection': conv.default('data_updates'),
            u'data_email': conv.pipe(
                conv.function(lambda lines: lines.split(u',')),
                conv.uniform_sequence(
                    conv.input_to_email,
                    ),
                ),
            u'database': conv.pipe(  # A space-separated list of databases
                conv.function(lambda databases: databases.split()),
                conv.uniform_sequence(
                    conv.noop,
                    # Remove empty items and remove sequence when it is empty.
                    ),
                conv.default(['souk']),
                ),
            u'debug': conv.pipe(conv.guess_bool, conv.default(False)),
            u'default_tab': conv.pipe(
                conv.cleanup_line,
                conv.test_in(['accueil', 'carte', 'liste']),
                conv.default('carte'),
                ),
            u'gadget_default_tab': conv.pipe(
                conv.cleanup_line,
                conv.test_in(['accueil', 'carte', 'liste']),
                conv.default(None),
                ),
            u'gadget-integration.js': conv.default(urlparse.urljoin('http://localhost:7002/', 'integration.js')),
            u'global_conf': conv.set_value(global_conf),
            u'handle_competence_territories': conv.pipe(conv.guess_bool, conv.default(True)),
            u'hide_directory': conv.pipe(conv.guess_bool, conv.default(False)),
            u'hide_export': conv.pipe(conv.guess_bool, conv.default(False)),
            u'hide_gadget': conv.pipe(conv.guess_bool, conv.default(False)),
            u'hide_home': conv.pipe(conv.guess_bool, conv.default(False)),
            u'hide_list': conv.pipe(conv.guess_bool, conv.default(False)),
            u'hide_map': conv.pipe(conv.guess_bool, conv.default(False)),
            u'hide_minisite': conv.pipe(conv.guess_bool, conv.default(False)),
            u'hide_category': conv.pipe(conv.guess_bool, conv.default(False)),
            u'hide_checkboxes': conv.pipe(conv.guess_bool, conv.default(False)),
            u'hide_legend': conv.pipe(conv.guess_bool, conv.default(False)),
            u'hide_territory': conv.pipe(conv.guess_bool, conv.default(False)),
            u'hide_term': conv.pipe(conv.guess_bool, conv.default(False)),
            u'i18n_dir': conv.default(os.path.join(app_dir, 'i18n')),
            u'i18n_dir_by_plugin_name': conv.set_value(None),  # set by plugins below
            u'ignored_fields': conv.pipe(
                conv.function(lambda lines: lines.split(u'\n')),
                conv.uniform_sequence(conv.pipe(
                    conv.function(lambda line: line.split(None, 1)),
                    conv.uniform_sequence(conv.input_to_slug),
                    conv.function(lambda seq: dict(zip(['id', 'name'], seq))),
                    )),
                conv.id_name_dict_list_to_ignored_fields,
                ),
            u'index.date.field': conv.default(None),
            u'log_level': conv.pipe(
                conv.default('WARNING'),
                conv.function(lambda log_level: getattr(logging, log_level.upper())),
                ),
            u'markers.piwik.id': conv.pipe(conv.input_to_int, conv.default(None)),
            u'markers.piwik.host': conv.default('http://localhost/piwik'),
            u'markers.piwik.ssl_host': conv.default('https://localhost/piwik'),
            u'organism_types_collection': conv.default('organism_types'),
            u'package_name': conv.default('etalagepassim'),
            u'package_slug': conv.default('etalage-passim'),
            u'pager.page_max_size': conv.pipe(conv.input_to_int, conv.default(20)),
            u'petitpois_url': conv.pipe(  # A space-separated list of URLs
                conv.function(lambda urls: urls.split()),
                conv.uniform_sequence(
                    conv.make_input_to_url(error_if_fragment = True, error_if_path = True, error_if_query = True,
                        full = True),
                    # Remove empty items and remove sequence when it is empty.
                    ),
                conv.default(['http://localhost:5000/']),
                ),
            u'plugins_conf_file': conv.default(None),
            u'realm': conv.default(u'Passim'),
            u'require_subscription': conv.pipe(conv.guess_bool, conv.default(False)),
            u'reset_on_poi_update': conv.pipe(conv.guess_bool, conv.default(False)),
            # Whether this application serves its own static files.
            u'static_files': conv.pipe(conv.guess_bool, conv.default(True)),
            u'static_files_dir': conv.default(os.path.join(app_dir, 'static')),
            u'subscribers.require_subscription': conv.pipe(conv.guess_bool, conv.default(False)),
            u'subscribers.database': conv.default('souk'),
            u'subscribers.collection': conv.default('subscribers'),
            u'subscribers.gadget_valid_domains': conv.pipe(
                conv.function(lambda hostnames: hostnames.split()),
                conv.default(['localhost', '127.0.0.1', 'comarquage.fr', 'donnees-libres.fr']),
                conv.function(lambda hostnames: tuple(hostnames)),
                ),
            u'territories_database': conv.noop,  # Done below.
            u'territories_collection': conv.default('territories'),
            u'territories_kinds': conv.pipe(
                conv.function(lambda kinds: kinds.split()),
                conv.uniform_sequence(
                    conv.test_in(model.Territory.public_kinds),
                    constructor = lambda kinds: sorted(set(kinds)),
                    ),
                conv.default([
                    # u'AbstractCommuneOfFrance',
                    u'ArrondissementOfCommuneOfFrance',
                    u'ArrondissementOfFrance',
                    u'AssociatedCommuneOfFrance',
                    # u'CantonalFractionOfCommuneOfFrance',
                    u'CantonOfFrance',
                    u'CommuneOfFrance',
                    # u'Country',
                    u'DepartmentOfFrance',
                    u'IntercommunalityOfFrance',
                    # u'InternationalOrganization',
                    u'MetropoleOfCountry',
                    u'Mountain',
                    u'OverseasCollectivityOfFrance',
                    u'PaysOfFrance',
                    u'RegionalNatureParkOfFrance',
                    u'RegionOfFrance',
                    # u'Special',
                    u'UrbanAreaOfFrance',
                    u'UrbanTransportsPerimeterOfFrance',
                    ]),
                ),
            u'theme_field': conv.pipe(
                conv.function(lambda line: line.split(None, 1)),
                conv.uniform_sequence(conv.input_to_slug),
                conv.function(lambda seq: dict(zip(['id', 'name'], seq))),
                conv.default(dict(id = 'organism-type')),
                ),
            u'tile_layers': conv.pipe(
                conv.function(eval),
                conv.function(strings.deep_decode),
                conv.test_isinstance(list),
                conv.uniform_sequence(
                    conv.pipe(
                        conv.test_isinstance(dict),
                        conv.struct(dict(
                            attribution = conv.pipe(
                                conv.test_isinstance(basestring),
                                conv.not_none,
                                ),
                            name = conv.pipe(
                                conv.test_isinstance(basestring),
                                conv.not_none,
                                ),
                            subdomains = conv.test_isinstance(basestring),
                            url = conv.pipe(
                                conv.test_isinstance(basestring),
                                conv.make_input_to_url(),
                                conv.not_none,
                                ),
                            )),
                        ),
                    ),
                conv.not_none,
                ),
            u'transport_types_order': conv.pipe(
                conv.function(lambda transport_type_slugs: transport_type_slugs.split()),
                conv.default([
                    u'transport-collectif-urbain',
                    u'transport-collectif-departemental',
                    u'transport-collectif-regional',
                    u'transport-longue-distance',
                    u'transport-a-la-demande',
                    u'transport-personnes-a-mobilite-reduite',
                    u'transport-scolaire',
                    u'velo-libre-service',
                    u'autopartage',
                    u'covoiturage',
                    u'taxi',
                    u'velo-taxi',
                    u'reseau-routier',
                    u'stationnement',
                    u'port',
                    u'aeroport',
                    u'circuit-touristique',
                    u'reseau-fluvial',
                    ]),
                ),
            },
        default = 'drop',
        keep_none_values = True,
        ))(conf))

    # CDN configuration
    conf.update(conv.check(conv.struct(
        {
            u'bootstrap.css': conv.default(urlparse.urljoin(conf['cdn_url'], '/bootstrap/2.3.1/css/bootstrap.min.css')),
            u'bootstrap-gadget.css': conv.default(
                urlparse.urljoin(conf['cdn_url'], '/bootstrap/2.3.1/css/bootstrap.min.css')
                ),
            u'bootstrap.js': conv.default(urlparse.urljoin(conf['cdn_url'], '/bootstrap/2.3.1/js/bootstrap.min.js')),
            u'bootstrap-responsive.css': conv.default(
                urlparse.urljoin(conf['cdn_url'], '/bootstrap/2.3.1/css/bootstrap-responsive.min.css')
                ),
            u'easyxdm.js': conv.default(urlparse.urljoin(conf['cdn_url'], '/easyxdm/latest/easyXDM.min.js')),
            u'easyxdm.swf': conv.default(urlparse.urljoin(conf['cdn_url'], '/easyxdm/latest/easyxdm.swf')),
            u'images.markers.url': conv.default(urlparse.urljoin(conf['cdn_url'], '/images/markers/')),
            u'images.misc.url': conv.default(urlparse.urljoin(conf['cdn_url'], '/images/misc/')),
            u'jquery.js': conv.default(urlparse.urljoin(conf['cdn_url'], '/jquery/jquery-1.9.1.min.js')),
            u'jquery-ui.css': conv.default(
                urlparse.urljoin(conf['cdn_url'], '/jquery-ui/1.8.16/themes/smoothness/jquery-ui.css')
                ),
            u'jquery-ui.js': conv.default(urlparse.urljoin(conf['cdn_url'], '/jquery-ui/1.8.16/jquery-ui.min.js')),
            u'json2.js': conv.default(urlparse.urljoin(conf['cdn_url'], '/easyxdm/latest/json2.js')),
            u'leaflet.css': conv.default(urlparse.urljoin(conf['cdn_url'], '/leaflet/leaflet-0.5.1/leaflet.css')),
            u'leaflet.ie.css': conv.default(urlparse.urljoin(conf['cdn_url'], '/leaflet/leaflet-0.5.1/leaflet.ie.css')),
            u'leaflet.js': conv.default(urlparse.urljoin(conf['cdn_url'], '/leaflet/leaflet-0.5.1/leaflet.js')),
            u'pie.js': conv.default(urlparse.urljoin(conf['cdn_url'], '/css3pie/1.0beta5/PIE.js')),
            u'prettify.js': conv.default(urlparse.urljoin(conf['cdn_url'], '/google-code-prettify/187/prettify.js')),
            u'territories_database': conv.pipe(
                conv.default(conf['database'][0]),
                ),
            u'typeahead.css': conv.default(urlparse.urljoin(conf['cdn_url'], '/twitter-typeahead/0.9.2/typeahead.css')),
            u'typeahead.js': conv.default(urlparse.urljoin(conf['cdn_url'], '/twitter-typeahead/0.9.2/typeahead.js')),
            },
        default = conv.noop,
        ))(conf))

    if len(conf['database']) != len(conf['petitpois_url']):
        raise Exception("Number of databases and number of Petitpois URLs don't match : {0} , {1}".format(
            conf['database'], conf['petitpois_url']))

    # Configure logging.
    logging.basicConfig(level = conf['log_level'], stream = sys.stdout)

    errorware = conf.setdefault(u'errorware', {})
    errorware['debug'] = conf['debug']
    if not errorware['debug']:
        errorware['error_email'] = conf['email_to']
        errorware['error_log'] = conf.get('error_log', None)
        errorware['error_message'] = conf.get('error_message', 'An internal server error occurred')
        errorware['error_subject_prefix'] = conf.get('error_subject_prefix', 'Passim Error: ')
        errorware['from_address'] = conf['from_address']
        errorware['smtp_server'] = conf.get('smtp_server', 'localhost')

    # Connect to MongoDB database.
    connection = pymongo.Connection()
    model.dbs = [
        connection[database_name]
        for database_name in conf['database']
        ]
    model.Subscriber.db = connection[conf['subscribers.database']]
    model.Subscriber.collection_name = conf['subscribers.collection']

    # Initialize plugins.
    if conf['plugins_conf_file'] is not None:
        plugins_conf = SafeConfigParser(dict(here = os.path.dirname(conf['plugins_conf_file'])))
        plugins_conf.read(conf['plugins_conf_file'])
        conf['i18n_dir_by_plugin_name'] = {}
        for section in plugins_conf.sections():
            plugin_accessor = plugins_conf.get(section, 'use')
            plugin_constructor = pkg_resources.EntryPoint.parse('constructor = {0}'.format(plugin_accessor)).load(
                require = False)
            plugin_constructor(plugins_conf, section)
            plugin_package_name = plugins_conf.get(section, 'package_name')
            if plugin_package_name is not None:
                plugin_i18n_dir = plugins_conf.get(section, 'i18n_dir')
                if plugin_i18n_dir is not None:
                    conf['i18n_dir_by_plugin_name'][plugin_package_name] = plugin_i18n_dir

    # Initialize ramdb database from MongoDB.
    ramdb.load()

    # Create the Mako TemplateLookup, with the default auto-escaping.
    templates_dirs = []
    if conf['custom_templates_dir']:
        templates_dirs.append(conf['custom_templates_dir'])
    templates_dirs.append(os.path.join(app_dir, 'templates'))
    templates.lookup = mako.lookup.TemplateLookup(
        cache_enabled = False if conf['debug'] else True,
        default_filters = ['h'],
        directories = templates_dirs,
#        error_handler = handle_mako_error,
        input_encoding = 'utf-8',
        module_directory = os.path.join(conf['cache_dir'], 'templates'),
#        strict_undefined = True,
        )
