## -*- coding: utf-8 -*-


## Etalage -- Open Data POIs portal
## By: Emmanuel Raviart <eraviart@easter-eggs.com>
##
## Copyright (C) 2011, 2012 Easter-eggs
## http://gitorious.org/infos-pratiques/etalage
##
## This file is part of Etalage.
##
## Etalage is free software; you can redistribute it and/or modify
## it under the terms of the GNU Affero General Public License as
## published by the Free Software Foundation, either version 3 of the
## License, or (at your option) any later version.
##
## Etalage is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Affero General Public License for more details.
##
## You should have received a copy of the GNU Affero General Public License
## along with this program.  If not, see <http://www.gnu.org/licenses/>.


<%inherit file="/generic/export.mako"/>


<%def name="types_and_formats_radios()" filter="trim">
                        <label class="radio">
                            <input type="radio" value="annuaire-excel" name="type_and_format">
                            Annuaire (format Excel) &mdash; Les informations détaillées,
                            organisme par organisme
                        </label>
                        <label class="radio">
                            <input type="radio" value="annuaire-csv" name="type_and_format">
                            Annuaire (format CSV) &mdash; Les informations détaillées,
                            organisme par organisme
                        </label>
</%def>

