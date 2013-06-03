#! /usr/bin/env python
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


"""Customization of Etalage for Passim"""


try:
    from setuptools import setup, find_packages
except ImportError:
    from ez_setup import use_setuptools
    use_setuptools()
    from setuptools import setup, find_packages


classifiers = """\
Development Status :: 3 - Alpha
Environment :: Web Environment
Intended Audience :: Information Technology
License :: OSI Approved :: GNU Affero General Public License v3
Operating System :: OS Independent
Programming Language :: Python
Topic :: Scientific/Engineering
"""

doc_lines = __doc__.split('\n')


setup(
    name = 'Etalage-Passim',
    version = '0.1dev',

    author = 'Emmanuel Raviart',
    author_email = 'infos-pratiques-devel@listes.infos-pratiques.org',
    classifiers = [classifier for classifier in classifiers.split('\n') if classifier],
    description = doc_lines[0],
    keywords = 'data database directory etalage geographical organism open organization passim passim+ poi web',
    license = 'http://www.fsf.org/licensing/licenses/agpl-3.0.html',
    long_description = '\n'.join(doc_lines[2:]),
    url = 'http://gitorious.org/passim/etalage-passim',

    data_files = [
        ('share/locale/fr/LC_MESSAGES', ['etalagepassim/i18n/fr/LC_MESSAGES/etalage-passim.mo']),
        ],
    install_requires = [
        'Etalage >= 0.1dev',
        ],
    message_extractors = {
        'etalagepassim': [
            ('**.py', 'python', None),
            ('templates/**.mako', 'mako', {'input_encoding': 'utf-8'}),
            ('static/**', 'ignore', None),
            ],
        },
#    package_data = {'etalagepassim': ['i18n/*/LC_MESSAGES/*.mo']},
    packages = find_packages(),
    zip_safe = False,
    )
